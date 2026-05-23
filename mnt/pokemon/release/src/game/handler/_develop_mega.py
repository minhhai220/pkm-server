#!/usr/bin/python
# coding=utf-8
from framework import nowtime_t
from framework.csv import ErrDefs, csv, ConstDefs
from framework.log import logger
from game import ClientError
from game.handler import RequestHandlerTask
from game.handler.inl import effectAutoGain, battleCardsAutoDeployment, battleCardsAutoDeploymentByNatureCheck, createCardsDB
from game.object import FeatureDefs, MegaDefs
from game.object.game import ObjectFeatureUnlockCSV, ObjectCostCSV
from game.object.game.gain import ObjectGainAux, ObjectCostAux
from game.object.game.aid import AidHelper
from tornado.gen import coroutine

# 合体进化
class DevelopMegaMerge(RequestHandlerTask):
    url = r'/game/develop/merge'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
            raise ClientError(ErrDefs.megaNotOpen)

        flag = self.input.get('flag')
        csvID = self.input.get('csvID')
        costCardIDs = self.input.get('costCardIDs')

        # 兼容大小写/空格/非字符串的 flag 入参
        if isinstance(flag, basestring):
            flag = flag.strip().lower()
        if flag not in ('new', 'route', 'relieve', 'recover'):
            raise ClientError('flag error')
        if csvID is None:
            raise ClientError('param miss')
        try:
            csvID = int(csvID)
        except Exception:
            raise ClientError('csvID error')
        if csvID not in csv.card_mega:
            raise ClientError('csvID error')
        cfg = csv.card_mega[csvID]
        cfgType = getattr(cfg, 'type', 0) or 0
        try:
            cfgType = int(cfgType)
        except Exception:
            cfgType = 0
        if cfgType != 3:
            raise ClientError('card mega cfg error')
        mergeCardID = getattr(cfg, 'mergeCardID', None)
        try:
            mergeCardID = int(mergeCardID)
        except Exception:
            raise ClientError('card mega cfg error')
        if mergeCardID not in csv.cards:
            raise ClientError('card mega cfg error')
        mergeCardCfg = csv.cards[mergeCardID]
        markID = mergeCardCfg.cardMarkID #3241
        roleCardMerge = self.game.role.card_merge
        entry = roleCardMerge.get(markID, None)
        isNewEntry = entry is None
        if isNewEntry:
            # 临时条目，校验失败不会污染数据库
            entry = {
                'id': None,
                'merge_cards': [],
                'merge_recover_last_time': 0,
                'unlock_route': {},
            }
        else:
            entry.setdefault('id', None)
            entry.setdefault('merge_cards', [])
            entry.setdefault('merge_recover_last_time', 0)
            entry.setdefault('unlock_route', {})
            if not isinstance(entry['merge_cards'], list):
                entry['merge_cards'] = list(entry['merge_cards'])
            if not isinstance(entry['unlock_route'], dict):
                entry['unlock_route'] = dict(entry['unlock_route'])
        
        # 保存条目的辅助函数，只在操作成功时调用
        def commitEntry():
            if isNewEntry:
                roleCardMerge[markID] = entry

        try:
            iterValues = roleCardMerge.itervalues
        except AttributeError:
            iterValues = roleCardMerge.values

        cooldownCD = getattr(ConstDefs, 'cardMergeRecoverCD', 0) or 0
        try:
            cooldownCD = int(cooldownCD)
        except Exception:
            cooldownCD = 0
        lastRecover = entry.get('merge_recover_last_time', 0) or 0
        try:
            lastRecover = int(lastRecover)
        except Exception:
            lastRecover = 0
        now = nowtime_t()
        cooldownEnd = lastRecover + cooldownCD

        def normalizeCardInfos(cardsCfg):
            if not cardsCfg:
                return []
            if isinstance(cardsCfg, (list, tuple)):
                cardInfos = list(cardsCfg)
            else:
                cardInfos = [cardsCfg]
            if cardInfos and not isinstance(cardInfos[0], (list, tuple, dict)):
                cardInfos = [cardInfos]
            return cardInfos

        def extractRequirements(cardInfos):
            ret = []
            for info in cardInfos:
                cardID = None
                star = 0
                if isinstance(info, dict):
                    cardID = info.get('cardID', info.get('id'))
                    star = info.get('star', 0)
                else:
                    seq = list(info)
                    if seq:
                        cardID = seq[0]
                        if len(seq) > 1:
                            star = seq[1]
                try:
                    cardID = int(cardID)
                    star = int(star)
                except Exception:
                    continue
                ret.append((cardID, star))
            return ret

        if flag == 'new':
            # 临时取消冷却限制
            if entry['merge_cards']:
                raise ClientError('card is using 128')
            if not isinstance(costCardIDs, (list, tuple)):
                raise ClientError('param miss')
            if len(costCardIDs) != 2:
                raise ClientError('costCardIDs error')
            costIDs = list(costCardIDs)
            if any(i is None for i in costIDs):
                raise ClientError('cardID error')
            # 先自动下阵，避免 getCostCards 报错
            yield battleCardsAutoDeployment(costIDs, self.game, **self.rpcs)
            costCards = self.game.cards.getCostCards(costIDs)
            usedCards = set()
            for info in iterValues():
                if not info:
                    continue
                mergeCards = info.get('merge_cards', []) or []
                usedCards.update(mergeCards)
            if usedCards & set(costIDs):
                raise ClientError('card is using 144')
            cardInfos = normalizeCardInfos(getattr(cfg, 'card', None))
            requirements = extractRequirements(cardInfos)
            if len(requirements) != len(costIDs):
                raise ClientError('card config error')
            remain = list(requirements)
            for card in costCards:
                matchedIdx = None
                for idx, req in enumerate(remain):
                    reqCardID, reqStar = req
                    if card.card_id != reqCardID:
                        continue
                    if card.star < reqStar:
                        raise ClientError('card star not enough')
                    matchedIdx = idx
                    break
                if matchedIdx is None:
                    raise ClientError('cardID error2')
                remain.pop(matchedIdx)
            if remain:
                raise ClientError('card config error')
            entry['merge_cards'] = list(costIDs)
            if not entry['id']:
                cardData = yield createCardsDB({'id': mergeCardID}, self.game.role.id, self.dbcGame)
                self.game.cards.addCards([cardData])
                entry['id'] = cardData['id']
                self.game.pokedex.addPokedex([entry['id']])
            entry['unlock_route'][mergeCardID] = True
        elif flag == 'route':
            if not entry['id']:
                raise ClientError('merge_card_not_exist')
            if entry['merge_cards']:
                raise ClientError('card is using 128')
            if entry['unlock_route'].get(mergeCardID, False):
                raise ClientError('merge_route_unlocked')
            # 验证素材卡
            if not isinstance(costCardIDs, (list, tuple)):
                raise ClientError('param miss')
            if len(costCardIDs) != 2:
                raise ClientError('costCardIDs error')
            costIDs = list(costCardIDs)
            if any(i is None for i in costIDs):
                raise ClientError('cardID error')
            # 先自动下阵，避免 getCostCards 报错
            yield battleCardsAutoDeployment(costIDs, self.game, **self.rpcs)
            costCards = self.game.cards.getCostCards(costIDs)
            usedCards = set()
            for info in iterValues():
                if not info:
                    continue
                mergeCards = info.get('merge_cards', []) or []
                usedCards.update(mergeCards)
            if usedCards & set(costIDs):
                raise ClientError('card is using 144')
            cardInfos = normalizeCardInfos(getattr(cfg, 'card', None))
            requirements = extractRequirements(cardInfos)
            if len(requirements) != len(costIDs):
                raise ClientError('card config error')
            remain = list(requirements)
            for card in costCards:
                matchedIdx = None
                for idx, req in enumerate(remain):
                    reqCardID, reqStar = req
                    if card.card_id != reqCardID:
                        continue
                    if card.star < reqStar:
                        raise ClientError('card star not enough')
                    matchedIdx = idx
                    break
                if matchedIdx is None:
                    raise ClientError('cardID error2')
                remain.pop(matchedIdx)
            if remain:
                raise ClientError('card config error')
            # 消耗解锁路线代价
            routeCost = getattr(cfg, 'mergeRouteCost', None)
            if routeCost:
                routeCostAux = ObjectCostAux(self.game, routeCost)
                if not routeCostAux.isEnough():
                    raise ClientError('merge_route_cost_not_enough')
                routeCostAux.cost(src='mega_merge_route')
            # 解锁路线
            entry['unlock_route'][mergeCardID] = True
            # 切换合体卡的形态（修改card_id）
            mergeCard = self.game.cards.getCard(entry['id'])
            if mergeCard and mergeCard.card_id != mergeCardID:
                mergeCard.db['card_id'] = mergeCardID
                mergeCard.db['skin_id'] = 0
                # 重要：调用 init() 更新 _csvCard，否则其他依赖 _csvCard 的属性不会更新
                mergeCard.init()
                # 更新图鉴
                self.game.pokedex.addPokedex([entry['id']])
            # 进行合体
            entry['merge_cards'] = list(costIDs)
        elif flag == 'relieve':
            if not entry['id'] or not entry['merge_cards']:
                raise ClientError('merge_not_active')
            mergeCardDBID = entry['id']
            
            # 重置合体卡的z觉醒并返还材料（与超进化逻辑一致）
            from framework.log import logger
            mergeCard = self.game.cards.getCard(mergeCardDBID)
            if mergeCard:
                mergeCardID = mergeCard.card_id
                if mergeCardID and mergeCardID in csv.cards:
                    zawakeID = csv.cards[mergeCardID].zawakeID
                    if zawakeID:
                        eff = self.game.zawake.reset(zawakeID, auto=True)
                        if eff:
                            logger.info('[MergeRelieve] 返还z觉醒材料: %s', eff.result)
                            yield effectAutoGain(eff, self.game, self.dbcGame, src='zawake_reset_from_merge_relieve')
                    else:
                        logger.info('[MergeRelieve] 合体卡%s没有z觉醒(zawakeID=%s)', mergeCardID, zawakeID)
                else:
                    logger.info('[MergeRelieve] 合体卡配置不存在: mergeCardID=%s', mergeCardID)
            
            # 先释放素材卡（会自动上阵）
            costCardDBIDs = list(entry['merge_cards'])
            if costCardDBIDs:
                yield battleCardsAutoDeployment(costCardDBIDs, self.game, **self.rpcs)
            # 清空合体记录
            entry['merge_cards'] = []
            # 恢复冷却：记录解体时间
            entry['merge_recover_last_time'] = now
            # 下阵合体卡（解体后不能使用，需要重新合体）
            if mergeCardDBID:
                yield battleCardsAutoDeployment([mergeCardDBID], self.game, **self.rpcs)
        elif flag == 'recover':
            # 切换合体形态（如从焰白酋雷姆切换到暗黑酋雷姆）
            if not entry['id']:
                raise ClientError('merge_card_not_exist')
            if entry['merge_cards']:
                raise ClientError('card is using 128')
            if not entry['unlock_route'].get(mergeCardID, False):
                raise ClientError('merge_route_not_unlocked')
            if not isinstance(costCardIDs, (list, tuple)):
                raise ClientError('param miss')
            if len(costCardIDs) != 2:
                raise ClientError('costCardIDs error')
            costIDs = list(costCardIDs)
            if any(i is None for i in costIDs):
                raise ClientError('cardID error')
            # 先自动下阵，避免 getCostCards 报错
            yield battleCardsAutoDeployment(costIDs, self.game, **self.rpcs)
            costCards = self.game.cards.getCostCards(costIDs)
            usedCards = set()
            for info in iterValues():
                if not info:
                    continue
                mergeCards = info.get('merge_cards', []) or []
                usedCards.update(mergeCards)
            if usedCards & set(costIDs):
                raise ClientError('card is using 144')
            cardInfos = normalizeCardInfos(getattr(cfg, 'card', None))
            requirements = extractRequirements(cardInfos)
            if len(requirements) != len(costIDs):
                raise ClientError('card config error')
            remain = list(requirements)
            for card in costCards:
                matchedIdx = None
                for idx, req in enumerate(remain):
                    reqCardID, reqStar = req
                    if card.card_id != reqCardID:
                        continue
                    if card.star < reqStar:
                        raise ClientError('card star not enough')
                    matchedIdx = idx
                    break
                if matchedIdx is None:
                    raise ClientError('cardID error2')
                remain.pop(matchedIdx)
            if remain:
                raise ClientError('card config error')
            # 消耗恢复代价
            recoverCost = getattr(cfg, 'mergeRecoverCost', None)
            if recoverCost:
                recoverCostAux = ObjectCostAux(self.game, recoverCost)
                if not recoverCostAux.isEnough():
                    raise ClientError('merge_recover_cost_not_enough')
                recoverCostAux.cost(src='mega_merge_recover')
            # 切换合体卡的形态（修改card_id）
            mergeCard = self.game.cards.getCard(entry['id'])
            if mergeCard and mergeCard.card_id != mergeCardID:
                mergeCard.db['card_id'] = mergeCardID
                mergeCard.db['skin_id'] = 0
                # 重要：调用 init() 更新 _csvCard，否则其他依赖 _csvCard 的属性不会更新
                mergeCard.init()
                # 更新图鉴
                self.game.pokedex.addPokedex([entry['id']])
            entry['merge_cards'] = list(costIDs)
        else:
            raise ClientError('flag error')
        
        # 只有操作成功才提交新条目到数据库
        commitEntry()

#  超进化
class DevelopMega(RequestHandlerTask):
    url = r'/game/develop/mega'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
            raise ClientError(ErrDefs.megaNotOpen)
        cardID = self.input.get('cardID', None)  # 本体
        branch = self.input.get('branch', None)  # 分支
        costCardIDs = self.input.get('costCardIDs', [])  # [cardID ...]
        if cardID is None or branch is None:
            raise ClientError('param miss')
        card = self.game.cards.getCard(cardID)
        if card is None:
            raise ClientError('cardID error')
        oldCardID = card.card_id
        markID = card.markID  # 精灵系列ID

        costCards = self.game.cards.getCostCards(costCardIDs, cardID)
        yield battleCardsAutoDeployment(costCardIDs, self.game, **self.rpcs)

        # 超进化前：重置助战培养并返还材料（不消耗钻石）
        # 获取该系列精灵的助战ID
        aidID = csv.cards[oldCardID].aidID
        aidResetEff = None
        if aidID:
            # auto=True 时 aidReset 不会内部调用 gain()，需要外部调用 effectAutoGain 发放材料
            aidResetEff = AidHelper.aidReset(self.game, aidID, auto=True)
            if aidResetEff:
                logger.info('[DevelopMega] 重置助战培养: aidID=%s, 返还材料=%s', aidID, aidResetEff.result)
                yield effectAutoGain(aidResetEff, self.game, self.dbcGame, src='aid_reset_from_mega')
        
        # 超进化前：从助战位下阵同系列的精灵
        removed = AidHelper.removeAidCardsByMarkID(self.game, markID)
        if removed:
            logger.info('[DevelopMega] 从助战位下阵同系列精灵: markID=%s, removed=%s', markID, removed)

        self.game.badge.resetBadgeCache(card)
        oldNatures = (card.natureType, card.natureType2)
        card.riseDevelopMega(branch, costCards)
        self.game.pokedex.addPokedex([card.id])
        newNatures = (card.natureType, card.natureType2)

        yield battleCardsAutoDeploymentByNatureCheck(self.game, cardID, oldNatures, newNatures, **self.rpcs)

        # 收集所有返还的材料
        allReturns = {}
        
        # Z觉醒重置返还
        zawakeIDOld = csv.cards[oldCardID].zawakeID
        zawakeIDNew = csv.cards[card.card_id].zawakeID
        if zawakeIDOld and zawakeIDOld != zawakeIDNew:
            eff = self.game.zawake.reset(zawakeIDOld, auto=True)
            if eff:
                yield effectAutoGain(eff, self.game, self.dbcGame, src='zawake_reset_from_mega')
                for k, v in eff.result.iteritems():
                    allReturns[k] = allReturns.get(k, 0) + v
        
        # 助战重置返还
        if aidResetEff and aidResetEff.result:
            for k, v in aidResetEff.result.iteritems():
                allReturns[k] = allReturns.get(k, 0) + v
        
        if allReturns:
            self.write({"view": allReturns})


# 精灵 转化 进化石/钥石
class DevelopMegaConvertCard(RequestHandlerTask):
    url = r'/game/develop/mega/convert/card'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
            raise ClientError(ErrDefs.megaNotOpen)
        csvID = self.input.get('csvID', None)
        costCardID = self.input.get('costCardID', None)  # cardDBID
        if csvID is None or costCardID is None:
            raise ClientError('param miss')

        costCards = self.game.cards.getCostCards([costCardID])
        yield battleCardsAutoDeployment([costCardID], self.game, **self.rpcs)

        # 转化
        num = self.game.cards.cardConvertMegaItems(csvID, costCards[0])

        eff = ObjectGainAux(self.game, {csvID: num})
        yield effectAutoGain(eff, self.game, self.dbcGame, src='mega_convert_card')


# 碎片 转化 进化石/钥石
class DevelopMegaConvertFrag(RequestHandlerTask):
    url = r'/game/develop/mega/convert/frag'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
            raise ClientError(ErrDefs.megaNotOpen)
        csvID = self.input.get('csvID', None)
        num = self.input.get('num', None)  # 转化数量
        costFragID = self.input.get('costFragID', None)  # fragID
        if csvID is None or num is None or costFragID is None:
            raise ClientError('param miss')

        # 转化
        self.game.cards.fragConvertMegaItems(csvID, num, costFragID)

        eff = ObjectGainAux(self.game, {csvID: num})
        yield effectAutoGain(eff, self.game, self.dbcGame, src='mega_convert_frag')


# 转化 进化石/钥石 次数购买
class DevelopMegaConvertBuy(RequestHandlerTask):
    url = r'/game/develop/mega/convert/buy'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
            raise ClientError(ErrDefs.megaNotOpen)

        csvID = self.input.get('csvID', None)
        if csvID is None:
            raise ClientError('param miss')

        costRMB = 0
        cfg = csv.card_mega_convert[csvID]
        times = self.game.role.mega_convert_times.get(csvID, 0)
        afterBuyTimes = 0
        buyChance = self.game.dailyRecord.mega_convert_buy_times.get(csvID, 0)

        if cfg.type == MegaDefs.MegaCommonItem:
            # 钥石购买机会达上限
            if buyChance >= ConstDefs.megaCommonBuyChanceLimit:
                raise ClientError(ErrDefs.megaCommonBuyChanceLimit)
            afterBuyTimes = ConstDefs.megaCommonBuyAddTimes + times
            # 钥石购买数量超上限
            if afterBuyTimes > self.game.role.megaCommonItemMaxTimes:
                raise ClientError(ErrDefs.megaCommonBuyLimit)
            costRMB = ObjectCostCSV.getMegaCommonItemConvertBuyCost(buyChance)
        elif cfg.type == MegaDefs.MegaItem:
            # 进化石购买机会达上限
            if buyChance >= ConstDefs.megaBuyChanceLimit:
                raise ClientError(ErrDefs.megaBuyChanceLimit)
            afterBuyTimes = ConstDefs.megaBuyAddTimes + times
            # 进化石购买数量超上限
            if afterBuyTimes > self.game.role.megaItemMaxTimes:
                raise ClientError(ErrDefs.megaBuyLimit)
            costRMB = ObjectCostCSV.getMegaItemConvertBuyCost(buyChance)

        cost = ObjectCostAux(self.game, {'rmb': costRMB})
        if not cost.isEnough():
            raise ClientError(ErrDefs.buyRMBNotEnough)
        cost.cost(src='mega_convert_times_buy')

        self.game.role.mega_convert_times[csvID] = afterBuyTimes
        self.game.dailyRecord.mega_convert_buy_times[csvID] = buyChance + 1


# 羁绊进化/特殊进化(假面超级火焰鸡、小智版甲贺忍蛙等)
# 规则：不消耗本体，创建一只全新的进化后卡牌
class DevelopFetter(RequestHandlerTask):
    url = r'/game/develop/fetter'

    @coroutine
    def run(self):
        if not ObjectFeatureUnlockCSV.isOpen(FeatureDefs.Mega, self.game):
            raise ClientError(ErrDefs.megaNotOpen)
        
        csvID = self.input.get('csvID', None)  # card_mega 的 id
        costCardIDs = self.input.get('costCardIDs', self.input.get('costCardID', []))

        if csvID is None:
            raise ClientError('param miss')
        try:
            csvID = int(csvID)
        except Exception:
            raise ClientError('param error')

        if costCardIDs is None:
            costCardIDs = []
        if not isinstance(costCardIDs, (list, tuple)):
            costCardIDs = [costCardIDs]
        if costCardIDs:
            try:
                costCardIDs = [int(x) for x in costCardIDs]
            except Exception:
                raise ClientError('costCardIDs error')

        if csvID not in csv.card_mega:
            raise ClientError('csvID error')
        megaCfg = csv.card_mega[csvID]

        targetCardID = getattr(megaCfg, 'targetID', None)
        if not targetCardID or targetCardID not in csv.cards:
            raise ClientError('card mega cfg error')

        # 消耗配置的道具 / 材料卡
        costAux = ObjectCostAux(self.game, getattr(megaCfg, 'costItems', {}))
        if megaCfg.costCards:
            costCards = self.game.cards.getCostCards(costCardIDs)
            markID = megaCfg.costCards.get('markID', None)
            rarity = megaCfg.costCards.get('rarity', None)
            star = megaCfg.costCards.get('star', None)
            needNum = megaCfg.costCards.get('num', 0)
            num = 0
            for costCard in costCards:
                if rarity and costCard.rarity != rarity:
                    raise ClientError('costCards error rarity')
                if markID and costCard.markID != markID:
                    raise ClientError('costCards error markID')
                if star and costCard.star < star:
                    raise ClientError('card star not enough')
                num += 1
            if num != needNum:
                raise ClientError('costCards error len')
            costAux.setCostCards(costCards)
            yield battleCardsAutoDeployment(costCardIDs, self.game, **self.rpcs)
        elif costCardIDs:
            # 配置未要求消耗卡牌但客户端传了材料
            raise ClientError('costCardIDs error')

        if not costAux.isEnough():
            raise ClientError(ErrDefs.costNotEnough)
        costAux.cost(src='card_develop_fetter')
        
        # 创建新卡牌（不消耗本体，直接给配置 targetID）
        cardData = yield createCardsDB({'id': targetCardID}, self.game.role.id, self.dbcGame)
        self.game.cards.addCards([cardData])
        newCardDBID = cardData['id']
        self.game.pokedex.addPokedex([newCardDBID])
        
        self.write({"view": {}})
