#!/bin/bash
# 转区服务启动脚本
# 
# 使用方法:
#   ./transfer/run.sh        # 前台运行
#   ./transfer/run.sh -d     # 后台运行

cd "$(dirname "$0")/.."

if [ "$1" == "-d" ]; then
    echo "后台启动转区服务..."
    nohup python transfer/daemon.py > transfer_daemon.log 2>&1 &
    echo "PID: $!"
    echo "日志: tail -f transfer_daemon.log"
else
    echo "前台启动转区服务..."
    python transfer/daemon.py
fi

