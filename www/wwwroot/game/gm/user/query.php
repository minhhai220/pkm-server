<?php
include 'config.php';
if ($_SESSION['lasttime'] == '') {
    $_SESSION['lasttime'] = time();
} else {
    if (time() - $_SESSION['lasttime'] < 1) {
        exit('刷太快了1秒一次');
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
                    exit('设置密码不能为空');
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
                    exit('卡密失效 你没有后台权限 请重新获取卡密激活.。');
                } elseif ($vipjson[$uid]['pwd'] != $pwd) {
                    exit('用户设置密码不匹配.');
                }
                if ($vipjson[$uid]['quid'] != $quid) {
                    exit('设置用户与当前选择大区不匹配.');
                }
                $viplevel = intval($vipjson[$uid]['level']);
                switch ($type) {
                    case 'charge':
				
                        $chargetype = trim(poststr('chargetype'));
                        $chargenum = trim(poststr('chargenum'));
                        if ($chargetype == '') {
                                exit('充值ID错误');
                            }
                            $find = false;
                            $file = fopen("../charge.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('充值ID错误');
                            }
                            $chargenum = trim(poststr('chargenum'));
                            if ($chargenum == '' || $chargenum < 0 || $chargenum > 999999999) {
                                exit('发送数量错误1-999999999');
                            }
                        
						     $result = sendMail($url,$uid,$cookie,$chargetype,$chargenum,$srv_name);
							 
							 exit('充值成功 邮件领取！');
               
                    break;
                    
                    case 'charge1':
				
                        $chargetype1 = trim(poststr('chargetype1'));
                        $chargenum1 = trim(poststr('chargenum1'));
                        if ($chargetype1 == '') {
                                exit('充值ID错误');
                            }
                            $find = false;
                            $file = fopen("../charge1.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype1) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('充值ID错误');
                            }
                            $chargenum1 = trim(poststr('chargenum1'));
                            if ($chargenum1 == '' || $chargenum1 < 0 || $chargenum1 > 1) {
                                exit('发送数量错误1-1');
                            }
                        
						     $result = sendMail($url,$uid,$cookie,$chargetype1,$chargenum1,$srv_name);
							 
							 exit('发送成功 邮件领取！');
               
                    break;
                    
                    case 'charge2':
				
                        $chargetype2 = trim(poststr('chargetype2'));
                        $chargenum2 = trim(poststr('chargenum2'));
                        if ($chargetype2 == '') {
                                exit('充值ID错误');
                            }
                            $find = false;
                            $file = fopen("../charge2.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype2) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('充值ID错误');
                            }
                            $chargenum2 = trim(poststr('chargenum2'));
                            if ($chargenum2 == '' || $chargenum2 < 0 || $chargenum2 > 9999) {
                                exit('发送数量错误1-9999');
                            }
                        
						     $result = sendMail($url,$uid,$cookie,$chargetype2,$chargenum2,$srv_name);
							 
							 exit('发送成功 邮件领取！');
               
                    break;
                    
                    case 'charge3':
				
                        $chargetype3 = trim(poststr('chargetype3'));
                        $chargenum3 = trim(poststr('chargenum3'));
                        if ($chargetype3 == '') {
                                exit('充值ID错误');
                            }
                            $find = false;
                            $file = fopen("../charge3.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype3) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('充值ID错误');
                            }
                            $chargenum3 = trim(poststr('chargenum3'));
                            if ($chargenum3 == '' || $chargenum3 < 0 || $chargenum3 > 999999) {
                                exit('发送数量错误1-999999');
                            }
                        
						     $result = sendMail($url,$uid,$cookie,$chargetype3,$chargenum3,$srv_name);
							 
							 exit('发送成功 邮件领取！');
               
                    break;
                    
                    case 'charge4':
				
                        $chargetype4 = trim(poststr('chargetype4'));
                        $chargenum4 = trim(poststr('chargenum4'));
                        if ($chargetype4 == '') {
                                exit('充值ID错误');
                            }
                            $find = false;
                            $file = fopen("../charge4.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype4) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('充值ID错误');
                            }
                            $chargenum4 = trim(poststr('chargenum4'));
                            if ($chargenum4 == '' || $chargenum4 < 0 || $chargenum4 > 999) {
                                exit('发送数量错误1-999');
                            }
                        
						     $result = sendMail($url,$uid,$cookie,$chargetype4,$chargenum4,$srv_name);
							 
							 exit('发送成功 邮件领取！');
               
                    break;
                    
                    case 'charge5':
				
                        $chargetype5 = trim(poststr('chargetype5'));
                        $chargenum5 = trim(poststr('chargenum5'));
                        if ($chargetype5 == '') {
                                exit('充值ID错误');
                            }
                            $find = false;
                            $file = fopen("../charge5.txt", "r");
                            while (!feof($file)) {
                                $line = fgets($file);
                                $txts = explode(';', $line);
                                if ($txts[0] == $chargetype5) {
                                    $find = true;
                                }
                            }
                            fclose($file);
                            if ($find == false) {
                                exit('充值ID错误');
                            }
                            $chargenum5 = trim(poststr('chargenum5'));
                            if ($chargenum5 == '' || $chargenum5 < 0 || $chargenum5 > 1) {
                                exit('发送数量错误1-1');
                            }
                        
						     $result = sendMail($url,$uid,$cookie,$chargetype5,$chargenum5,$srv_name);
							 
							 exit('发送成功 邮件领取！');
               
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
