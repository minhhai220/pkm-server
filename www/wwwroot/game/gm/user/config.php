<?php
error_reporting(1);
session_start();
date_default_timezone_set('PRC');
header("Content-type: text/html; charset=utf-8");
$gmcode='lyzwlkj.vip';
$quarr = array (
 "1" => array (
  "user" =>"admin",
  "pswd" =>"admin",
  "zoneid"=>1,
  "srv_name"=>"game.cn.1",
  "name"=>"阿泽源码网1区",
  "url"=>"http://127.0.0.1:38088",
  "hidde"=>false
 )
,
 "2" => array (
  "user" =>"admin",
  "pswd" =>"admin",
  "zoneid"=>2,
  "srv_name"=>"game.cn.2",
  "name"=>"阿泽源码网2区",
  "url"=>"http://127.0.0.1:38088",
  "hidde"=>false
 )


);
/*
使用方法: 
1.如果是用Ubuntu系统的话,修改NGINX配置,使它支持PHP,新增conf创建网站,把后台文件放进去就可以用了(看不懂的话,跳过这个,看下面这条)
2.看不懂第一条的话:随便找个服务器,把127.0.0.1改成服务端的IP,然后宝塔创建个网站,丢进去运行

玩家后台道具:player.txt GM后台道具:xmitem.txt 目前2个文件是一样的

*/

$getfilter="'|(and|or)\\b.+?(>|<|=|in|like)|\\/\\*.+?\\*\\/|<\\s*script\\b|\\bEXEC\\b|UNION.+?SELECT|UPDATE.+?SET|INSERT\\s+INTO.+?VALUES|(SELECT|DELETE).+?FROM|(CREATE|ALTER|DROP|TRUNCATE)\\s+(TABLE|DATABASE)";
$postfilter="\\b(and|or)\\b.{1,6}?(=|>|<|\\bin\\b|\\blike\\b)|\\/\\*.+?\\*\\/|<\\s*script\\b|\\bEXEC\\b|UNION.+?SELECT|UPDATE.+?SET|INSERT\\s+INTO.+?VALUES|(SELECT|DELETE).+?FROM|(CREATE|ALTER|DROP|TRUNCATE)\\s+(TABLE|DATABASE)";
$cookiefilter="\\b(and|or)\\b.{1,6}?(=|>|<|\\bin\\b|\\blike\\b)|\\/\\*.+?\\*\\/|<\\s*script\\b|\\bEXEC\\b|UNION.+?SELECT|UPDATE.+?SET|INSERT\\s+INTO.+?VALUES|(SELECT|DELETE).+?FROM|(CREATE|ALTER|DROP|TRUNCATE)\\s+(TABLE|DATABASE)";
function StopAttack($StrFiltKey,$StrFiltValue,$ArrFiltReq){
	if(is_array($StrFiltValue)){
		$StrFiltValue=implode($StrFiltValue);
	}
	if (preg_match("/".$ArrFiltReq."/is",$StrFiltValue)==1){
		print "非法操作!";
		exit();
	}
}
foreach($_GET as $key=>$value){
	StopAttack($key,$value,$getfilter);
}
foreach($_POST as $key=>$value){
	StopAttack($key,$value,$postfilter);
}
foreach($_COOKIE as $key=>$value){
	StopAttack($key,$value,$cookiefilter);
}
function poststr($str){

  return $_POST[$str];

}


function http_post($url, $data = NULL , $cookie ="") {

        $curl = curl_init();

        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($curl, CURLOPT_SSL_VERIFYHOST, false);
		
        if($data=="" ){
            $data = "{}";
        }
        if(is_array($data))
        {
            $data = json_encode($data,JSON_UNESCAPED_UNICODE);
        }

		$dataLen = strlen($data);
        curl_setopt($curl, CURLOPT_POST, 1);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
        curl_setopt($curl, CURLOPT_HEADER, 0);
		curl_setopt($curl, CURLOPT_COOKIE,$cookie);
        curl_setopt($curl, CURLOPT_HTTPHEADER,array(
		        "Content-Encoding: gzip",
                'Content-Type: application/json',
                "Content-Length: {$dataLen}" ,
        
        ));
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
        $res = curl_exec($curl);
        $errorno = curl_errno($curl);
        if ($errorno) {
            return $errorno;
        }
        curl_close($curl);
        return $res;

    }





function loginGetCookie($url,$user,$pswd){
	    $url = $url."/login";
         $ch = curl_init($url); 
		 $post = array(
		  "username" => "$user" ,
	      "password" =>  "$pswd",
		);
		
		  curl_setopt($ch, CURLOPT_HEADER, 1);
          curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1); 
          curl_setopt($ch, CURLOPT_POSTFIELDS, $post); 
		  $content=curl_exec($ch);
          preg_match('/Set-Cookie:(.*);/iU',$content,$str); 
          $cookie = $str[1]; //获得COOKIE
		  return $cookie;
}




function sendMail($url,$rid,$cookie,$itema,$num,$srv_name,$title="",$content=""){

    $mailApiUrl =$url."/sendmail";//API的位置
	$title == "" && $title="GM邮件";
	$content == "" && $content="提示您：你有新的道具，请查收";
	$items=array($itema=>(int)$num);
	$meta = array();
	$meta['servName'] = $srv_name;
	$meta['receive'] =  $rid;  
	$meta['mailTemp'] = "2";
	$meta['mailType'] = "role";
	$meta['sender'] = "GM";
	$meta['subject'] = $title;
	$meta['content'] = $content;
	$meta['attachs'] = json_encode($items,JSON_UNESCAPED_UNICODE);
	$meta['beginVip'] = null;
	$meta['endVip'] = null;

	
	$retJson  = http_post($mailApiUrl,$meta,$cookie); 
 	$jsonData = json_decode($retJson,true);

	if($jsonData['retS'] == ""){
	  return false;
	}
	
	if( in_array($rid, $jsonData['retS'])){
		return true;
	}else{
	   return false;
	}
   
	
}

?>