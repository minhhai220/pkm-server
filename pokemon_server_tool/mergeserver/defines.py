# coding:utf8

MongoDefs = {
	'gamemerge.dev.1': "mongodb://127.0.0.1:27018/gamemerge_dev1",
	'game.dev.2': "mongodb://127.0.0.1:27018/game_dev1",
	'game.dev.6': "mongodb://127.0.0.1:27018/game_dev2",
}

DumpPath = './dump'


def getMongoDefs():
	import os
	import sys
	sys.path.append(os.path.join(os.getcwd(), '../../release/'))
	from new_container import MONGODB_MAP, CMGO_GAME_DEV_1
	from run_merge import MergeServs

	mergeServerName = {
		'gamemerge.dev.1': CMGO_GAME_DEV_1,

	}


	ret = []
	srcServerNames = []
	for name in mergeServerName:
		for mergeName in MergeServs[name]:
			if 'merge' in mergeName:
				ret.append("'%s': '%s'," % (mergeName, MongoDefs[mergeName]))
			else:
				srcServerNames.append(mergeName)

	for name in srcServerNames:
		conf = '%s/%s?authMechanism=SCRAM-SHA-1&authSource=admin' % (
				MONGODB_MAP[name.replace('game', 'storage')], name.replace('.', '_')
		)
		ret.append("'%s': '%s'," % (name, conf))

	for name, v in mergeServerName.iteritems():
		conf = '%s/%s?authMechanism=SCRAM-SHA-1&authSource=admin' % (
			v, name.replace('.', '_')
		)
		ret.append("'%s': '%s'," % (name, conf))

	ret.sort()
	print('\n'.join(ret))


if __name__ == "__main__":
	getMongoDefs()


