<?php
include 'jl.php';
if ($_SESSION['lasttime'] == '') {
    $_SESSION['lasttime'] = time();
} else {
    if (time() - $_SESSION['lasttime'] < 2) {
        exit('刷太快了2秒一次');
    } else {
        $_SESSION['lasttime'] = time();
    }
}

if ($_POST) {
	/*
	 "1" => array (
  "user" =>"admin",
  "pswd" =>"admin",
  "zoneid"=>1,
  "srv_name"=>"game.dev.1",
  "name"=>"阿泽源码网1区",
  "url"=>"http://127.0.0.1:39081",
  "hidde"=>false
 )
 
	*/
    $quid      =  trim(poststr('qu'));
    $qu        =  $quarr[$quid];
    $uid       =  trim(poststr('uid'));
    $url       =  $qu['url'];
    $srv_name  =  $qu['srv_name'];
    $adm_user  =  $qu['user'];
	$adm_pswd  =  $qu['pswd'];
    
	$cookie    =  loginGetCookie($url,$adm_user,$adm_pswd);
	
	
	$pwd = trim(poststr('pwd'));
	
	
	//参数处理
	
	
		
        $time = time();
		
	//参数处理	
	
	
    if ($quid >= 1) {
        if ($uid != '') {
            if ($_POST['type']) {
                $type = trim($_POST['type']);
                $pswd = trim($_POST['pswd']);
                if ($pwd == '') {
                    exit('授权密码不能为空');
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
                    exit('你没有VIP权限.。');
                } elseif ($vipjson[$uid]['pwd'] != $pwd) {
                    exit('用户密码不匹配.');
                }
                if ($vipjson[$uid]['quid'] != $quid) {
                    exit('授权用户与当前选择大区不匹配.');
                }
                $viplevel = intval($vipjson[$uid]['level']);
                switch ($type) {
                    case 'jlzf':
				
                        $jl = trim(poststr('jl'));
                 
                        if ($jl == '') {
                                exit('精灵ID错误');
                            }
                            $find = false;
                            $file = fopen("../jl.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode('|', $line);
                                if ($txts[0] == $jl) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('精灵ID错误');
                            }

                             $chargetype = trim(poststr('jl'));
						     $result = sendMail($url,$uid,$cookie,$chargetype,$chargenum,$srv_name);
							 
							 exit('发送成功！');
               
                    break;
                    
                    case 'daoju':
					
					
							
                        if ($viplevel < 1) {
                            exit('VIP权限不足');
                        }
                            $mailid = trim(poststr('item'));
                            if ($mailid == '') {
                                exit('物品ID错误');
                            }
                            $find = false;
                            $file = fopen("../item.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode('|', $line);
                                if ($txts[0] == $mailid) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('物品ID不存在');
                            }
                            $mailnum = trim(poststr('num'));
                            if ($mailnum == '' || $mailnum < 0 || $mailnum > 9999) {
                                exit('发送数量错误');
                            }
                           //防止f12
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
                            if ($mailnum == '' || $mailnum < 0 || $mailnum > 9999) {
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
                    default:
                        exit('系统异常，请重试!');
                    break;
                }
            } else {
                exit('抓尼玛呢！');
            }
        } else {
            exit('角色名错误');
        }
    } else {
        exit('区号错误');
    }
} else {
    exit('非法请求!请自重');
}
