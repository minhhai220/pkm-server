# coding:utf8
"""
合服配置
注意：有些文件是需要修改的
1. mergeserver/run_merge配置
2. mergeserver/defines配置(提供了脚本)
3. mergeserver/run_merge选定合服后运行的服务器
4. 修改/fabfile/fabfile的ServerIDMap
5. 将服务器配置到fabfile_merge文件，将新增合服信息增加到fabfile_merge.ServerIDMap
6. 生成storage,pvp配置, release/new_container.py
7. 生成game_defines配置, server_tool/fabfile/new_game_defines.py
8. 运行game_defines.py文件，得到login服务的登录配置文件


运行合服
-u 输出到stdout,不缓冲
例：  python -u run_merge.py gamemerge.cn_qd.10|tee gamemerge.cn_qd.10.log
"""

from datetime import datetime
from handler import run

MergeServs = {
	# 20211013
	'gamemerge.dev.1': ['game.dev.1', 'game.dev.2'],

def main():
	import sys
	dest = sys.argv[1]
	if len(dest.split('.')) != 3 or 'game' not in dest:
		print("err: please check your input")
		return
	if dest not in MergeServs:
		print('err: %s not in MergeServs config' % dest)
		return

	print(dest)
	keys = MergeServs[dest]
	start_time = datetime.now()
	run(dest, keys)
	end_time = datetime.now()
	print('DONE: %ss' % str((end_time - start_time).seconds))


if __name__ == '__main__':
	main()

