#!/bin/bash

sudo yum install -y curl
sleep 2

PUBLIC_IP=$(
    curl -s --max-time 5 ifconfig.me | { read ip && [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && echo "$ip" || exit 1; }
) || PUBLIC_IP=$(
    curl -s --max-time 5 icanhazip.com | { read ip && [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && echo "$ip" || exit 1; }
) || PUBLIC_IP=$(
    curl -s --max-time 5 ipinfo.io/ip | { read ip && [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && echo "$ip" || exit 1; }
) || PUBLIC_IP=$(
    ip -4 addr show eth0 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1 | head -1
) || PUBLIC_IP=$(
    hostname -I 2>/dev/null | awk '{print $1}'
) || {
    echo -e "\033[31m错误：无法获取外网IP\033[0m"
    exit 1
}

if [[ ! $PUBLIC_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "\033[31m错误：获取到无效IP地址 ($PUBLIC_IP)\033[0m"
    exit 1
fi

echo -e "检测到外网IP：\033[32m$PUBLIC_IP\033[0m"

declare -a FILES=(
    "/mnt/pokemon/release/autochess_room/defines.json"
	"/mnt/pokemon/release/online_fight_forward/defines.json"
	"/mnt/pokemon/release/game_defines.py"
	"/mnt/pokemon/release/payment_defines.py"
	"/mnt/pokemon/release/login/defines.json"
	"/mnt/pokemon/release/login/conf/game.json"
	"/mnt/pokemon/release/login/conf/cn/serv.json"
	"/www/wwwroot/game/patch/3/res/version.plist"
)

for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "\033[33m警告：文件不存在 [$file]\033[0m"
        continue
    fi
    
    if [ ! -w "$file" ]; then
        echo -e "\033[31m错误：文件不可写 [$file]\033[0m"
        continue
    fi

    if sed -i "s/122\.51\.27\.223/${PUBLIC_IP}/g" "$file"; then
        echo -e "成功更新：\033[34m${file}\033[0m"
    else
        echo -e "\033[31m错误：替换失败 [$file]\033[0m"
    fi
done

echo -e "\n操作完成，建议人工复核文件修改结果"
echo -e "\n阿泽源码网：www.lyzwlkj.vip"




















































































































































#阿 泽 源 码 网 w w w . l y z w l k j . v i p