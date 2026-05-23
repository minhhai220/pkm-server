<?php
include 'config.php';
if ($_POST) {
    $checknum = trim(poststr('checknum'));
    $quid = trim(poststr('qu'));
    $qu = $quarr[$quid];
    $uid = trim(poststr('uid'));
    $dbip = $qu['host'];
    $zoneid = $qu['zoneid'];
    $quname = $qu['name'];
    $url = $qu['url'];
	
	//参数处理
	$quid      =  trim(poststr('qu'));
    $qu        =  $quarr[$quid];
    $uid       =  trim(poststr('uid'));
    $url       =  $qu['url'];
    $srv_name  =  $qu['srv_name'];
    $adm_user  =  $qu['user'];
	$adm_pswd  =  $qu['pswd'];
    
	
		
		
        
		
        $time = time();
		
	//参数处理	
	
    if ($checknum == $gmcode) {
        if ($quid >= 1 || $quid != '') {
            if ($uid != '') {
                if ($_POST['type']) {
                    $type = trim($_POST['type']);
                    switch ($type) {
                        case 'charge':
                 
                        $cookie     =  loginGetCookie($url,$adm_user,$adm_pswd);
                        $chargetype = trim(poststr('chargetype'));
                        $chargenum  = trim(poststr('chargenum'));
                             
							 sendMail($url,$uid,$cookie,$chargetype,$chargenum,$srv_name);
							 exit('充值成功！');
                        break;
                        case 'mail':
						//防止f12
						$cookie     =  loginGetCookie($url,$adm_user,$adm_pswd);
							
						    $mailid = trim(poststr('item'));
                            if ($mailid == '') {
                                exit('物品ID错误');
                            }
                            $find = false;
                            $file = fopen("../xmitem.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $mailid) {
                                    $find = true;
                                }
                            }
							
							
                            fclose($file);
                            if ($find == false) {
                                exit('物品ID不存在');
                            }
                            $mailnum = trim(poststr('num'));
                            if ($mailnum == '' || $mailnum < 0 || $mailnum > 99999999) {
                                exit('发送数量太大，不允许哦，人家受不鸟啦~！');
                            }
						//防止f12
                            $item = trim($_POST['item']);
							$itemnum = trim($_POST['num']);
							$title =  trim($_POST['title']);
							$content = trim($_POST['content']);
							
							sendMail($url,$uid,$cookie,$item,$itemnum,$srv_name,$title,$content);
							 exit('发送成功！');
                        break;

                        case 'addczvip':
                            $pwd = trim(poststr('pwd'));
                            if ($pwd == '') {
                                exit('玩家后台的授权密码不能为空');
                            }
                            $vipfile = 'Q32838727-' . $quid . '.json';
                            $fp = fopen($vipfile, "a+");
                            if (filesize($vipfile) > 0) {
                                $str = fread($fp, filesize($vipfile));
                                fclose($fp);
                                $vipjson = json_decode($str, true);
                                if ($vipjson == null) {
                                    $vipjson = array();
                                }
                            } else {
                                $vipjson = array();
                            }
                            if (!$vipjson[$uid]) {
                                $vipjson[$uid] = array('pwd' => $pwd, 'level' => 0, 'quid' => $quid);
                                file_put_contents($vipfile, json_encode($vipjson, 320));
                                exit('加入VIP成功.');
                            } else {
                                exit('该角色名已经是VIP了.');
                            }
                        break;
                        case 'addvip':
                            $pwd = trim(poststr('pwd'));
                            if ($pwd == '') {
                                exit('玩家后台的授权密码不能为空');
                            }
                            $vipfile = 'Q32838727-' . $quid . '.json';
                            $fp = fopen($vipfile, "a+");
                            if (filesize($vipfile) > 0) {
                                $str = fread($fp, filesize($vipfile));
                                fclose($fp);
                                $vipjson = json_decode($str, true);
                                if ($vipjson == null) {
                                    $vipjson = array();
                                }
                            } else {
                                $vipjson = array();
                            }
                            if (!$vipjson[$uid] || intval($vipjson[$uid]['level'] == 0)) {
                                $vipjson[$uid] = array('pwd' => $pwd, 'level' => 1, 'quid' => $quid);
                                file_put_contents($vipfile, json_encode($vipjson, 320));
                                exit('加入或升级VIP成功.');
                            } else {
                                exit('该角色名已经是VIP了.');
                            }
                        break;
                        case 'quxiaovip':
                            $vipfile = 'Q32838727-' . $quid . '.json';
                            $fp = fopen($vipfile, "a+");
                            if (filesize($vipfile) > 0) {
                                $str = fread($fp, filesize($vipfile));
                                fclose($fp);
                                $vipjson = json_decode($str, true);
                                if ($vipjson == null) {
                                    $vipjson = array();
                                }
                            } else {
                                $vipjson = array();
                            }
                            if ($vipjson[$uid]) {
                                unset($vipjson[$uid]);
                                file_put_contents($vipfile, json_encode($vipjson, 320));
                                exit('取消成功.');
                            } else {
                                exit('该角色名并未授权.');
                            }
                        break;
                        case 'editpwd':
                            $data = array("key" => $token, "time" => $time, "type" => 'queryrole', "roleid" => $uid, "port" => $port, "ip" => $ip);
                            $rest = get($url, $data);
                            if (strstr($rest, 'success') == false) {
                                exit('校验失败');
                            }
                            $pwd = trim(poststr('pwd'));
                            if ($pwd == '') {
                                exit('玩家后台的授权密码不能为空');
                            }
                            $vipfile = 'Q32838727-' . $quid . '.json';
                            $fp = fopen($vipfile, "a+");
                            if (filesize($vipfile) > 0) {
                                $str = fread($fp, filesize($vipfile));
                                fclose($fp);
                                $vipjson = json_decode($str, true);
                                if ($vipjson == null) {
                                    $vipjson = array();
                                }
                            } else {
                                $vipjson = array();
                            }
                            if ($vipjson[$uid]) {
                                $vipjson[$uid] = array('pwd' => $pwd, 'level' => $vipjson[$uid]['level'], 'quid' => $quid);
                                file_put_contents($vipfile, json_encode($vipjson, 320));
                                exit('修改成功.');
                            } else {
                                exit('该角色名并未授权.');
                            }
                        break;
						
                        default:
                            exit('系统异常，请重试!');
                        break;
                    }
                } else {
                    exit('请求类型不存在！');
                }
            } else {
                exit('角色名错误');
            }
        } else {
            exit('区号错误');
        }
    } else {
        exit('GM码不对');
    }
} else {
    exit('非法请求!请自重');
}
