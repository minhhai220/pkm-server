#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
【转区逻辑】服务入口 - 启动转区守护进程
启动方式: python transfer_server.py transfer_daemon
'''

import dev_patch
import framework
from framework.log import initLog

import argparse


def parseArgs():
    parser = argparse.ArgumentParser(description="%s\r\nTransfer server." % framework.__copyright__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('name', help='server name', nargs='?', default='transfer_daemon')
    args = parser.parse_args()
    return args


def main():
    args = parseArgs()
    initLog(args.name)
    
    from transfer.daemon import TransferDaemon
    daemon = TransferDaemon()
    print '[%s] Transfer Daemon running ...' % args.name
    daemon.init()
    daemon.start()


if __name__ == "__main__":
    main()

