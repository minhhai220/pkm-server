var pwd = '';
var cdk = '';
var uid = '';
var qu = $('#qu').val();
var role = $('#role').val();
$('#pwd').change(function() {
    pwd = $(this).val();
});
  $('#uid').change(function(){
	  uid=$.trim($(this).val());
  });
  $('#cdk').change(function(){
	  cdk=$.trim($(this).val());
  });
  $('#qu').change(function(){
	  qu=$.trim($(this).val());
  });
$(".selectpicker").selectpicker({
    header:'请选择',
    showIcon:true,
    multipleSeparator:'#',
    maxOptions:4,
    maxOptionsText:'最多选4个',
});

$('#search').click(function(){
	  var keyword=$('#searchipt').val();
	  $.ajax({
		  url:'itemquery.php',
		  type:'post',
		  'data':{keyword:keyword},
          'cache':false,
          'dataType':'json',
		  success:function(data){
			  if(data){
				  $('#mailid').html('');
				for (var i in data){
				  $('#mailid').append('<option value="'+data[i].key+'">'+data[i].val+'</option>');
				}
			  }else{
				  $('#mailid').html('<option value="">未找到</option>');
			  }
		  },
		  error:function(){
			  bootbox.alert({message:'操作失败',title:"提示"});
		  }
	  });
  });


$('#search1').click(function(){
	  var keyword=$('#searchipt1').val();
	  $.ajax({
		  url:'itemquery1.php',
		  type:'post',
		  'data':{keyword:keyword},
          'cache':false,
          'dataType':'json',
		  success:function(data){
			  if(data){
				  $('#jl').html('');
				for (var i in data){
				  $('#jl').append('<option value="'+data[i].key+'">'+data[i].val+'</option>');
				}
			  }else{
				  $('#jl').html('<option value="">未找到</option>');
			  }
		  },
		  error:function(){
			  bootbox.alert({message:'操作失败',title:"提示"});
		  }
	  });
  });

/**
帐号充值
*/
function chargebtn() {
/*	if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }*/

	  var chargenum=$('#chargenum').val();
	  if(chargenum==''){
		  layer.msg('充值数量不能为空');
		  return false;
	  }	 
	   var chargetype=$('#chargetype').val();
	  if(chargetype==''){
		  layer.msg('请选择操作类型');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/query.php", {
		type:'charge',uid:uid,chargenum:chargenum,qu:qu,pwd:pwd,chargetype:chargetype,				
	},
	function(data) {
		
		layer.msg(data);
		
	});
}

function chargebtn1() {
/*	if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }*/

	  var chargenum1=$('#chargenum1').val();
	  if(chargenum1==''){
		  layer.msg('充值数量不能为空');
		  return false;
	  }	 
	   var chargetype1=$('#chargetype1').val();
	  if(chargetype1==''){
		  layer.msg('请选择操作类型');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/query.php", {
		type:'charge1',uid:uid,chargenum1:chargenum1,qu:qu,pwd:pwd,chargetype1:chargetype1,				
	},
	function(data) {
		
		layer.msg(data);
		
	});
}

function chargebtn2() {
/*	if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }*/

	  var chargenum2=$('#chargenum2').val();
	  if(chargenum2==''){
		  layer.msg('数量不能为空');
		  return false;
	  }	 
	   var chargetype2=$('#chargetype2').val();
	  if(chargetype2==''){
		  layer.msg('请选择操作类型');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/query.php", {
		type:'charge2',uid:uid,chargenum2:chargenum2,qu:qu,pwd:pwd,chargetype2:chargetype2,				
	},
	function(data) {
		
		layer.msg(data);
		
	});
}

function chargebtn3() {
/*	if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }*/

	  var chargenum3=$('#chargenum3').val();
	  if(chargenum3==''){
		  layer.msg('数量不能为空');
		  return false;
	  }	 
	   var chargetype3=$('#chargetype3').val();
	  if(chargetype3==''){
		  layer.msg('请选择操作类型');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/query.php", {
		type:'charge3',uid:uid,chargenum3:chargenum3,qu:qu,pwd:pwd,chargetype3:chargetype3,				
	},
	function(data) {
		
		layer.msg(data);
		
	});
}

function chargebtn4() {
/*	if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }*/

	  var chargenum4=$('#chargenum4').val();
	  if(chargenum4==''){
		  layer.msg('数量不能为空');
		  return false;
	  }	 
	   var chargetype4=$('#chargetype4').val();
	  if(chargetype4==''){
		  layer.msg('请选择操作类型');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/query.php", {
		type:'charge4',uid:uid,chargenum4:chargenum4,qu:qu,pwd:pwd,chargetype4:chargetype4,				
	},
	function(data) {
		
		layer.msg(data);
		
	});
}

function chargebtn5() {
/*	if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }*/

	  var chargenum5=$('#chargenum5').val();
	  if(chargenum5==''){
		  layer.msg('数量不能为空');
		  return false;
	  }	 
	   var chargetype5=$('#chargetype5').val();
	  if(chargetype5==''){
		  layer.msg('请选择操作类型');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/query.php", {
		type:'charge5',uid:uid,chargenum5:chargenum5,qu:qu,pwd:pwd,chargetype5:chargetype5,				
	},
	function(data) {
		
		layer.msg(data);
		
	});
}

function jihuo() {
     if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }
	  if(uid ==''){
		  layer.msg('角色UID不能为空');
		  return false;
	  }
	  if(cdk ==''){
		  layer.msg('卡密不能为空');
		  return false;
	  }
	  
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/jihuo.php", {
		type:'jihuo',uid:uid,cdk:cdk,qu:qu,pwd:pwd,				
	},
	function(data) {
		
		layer.msg(data);
		
	});
}
/**
发道具邮件
*/
function send_mail() {

	if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }
	  if(uid==''){
		  layer.msg('角色名不能为空');
		  return false;
	  }
	  var mailid=$('#mailid').val();
	  if(mailid==''){
		  layer.msg('请选择物品');
		  return false;
	  }
	  var title='GM邮件';
	  var content='亲爱的玩家，请查收您的邮件!';
	  var mailnum=$('#mailnum').val();
	  if(mailnum=='' || isNaN(mailnum)){
		  layer.msg('数量不能为空');
		  return false;
	  }
	  if(mailnum<1 || mailnum>9999){
		  layer.msg('道具数量范围:1-9999');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/query.php", {
		type:'daoju',uid:uid,item:mailid,num:mailnum,qu:qu,pwd:pwd,title:title,content:content,				
	},
	function(data) {
		layer.msg(data);
		
	});
	
}

function jlzf() {
/*	if (pwd == '') {
        layer.msg('请输入授权密码');
        return false;
    }*/
	   var jl=$('#jl').val();
	  if(jl==''){
		  layer.msg('请选择你要发送的成品精灵');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/jlzf.php", {
		type:'jlzf',uid:uid,qu:qu,pwd:pwd,jl:jl,				
	},
	function(data) {
		
		layer.msg(data);
		
	});
}

/**
清包
*/
function clearbag() {
	{
	   layer.confirm('<font color="red"><h2>警告！</h2><br/>1、请确认是否要执行背包操作！<br/>2、请确认角色是否已经提前下线！<br/>3、清理完成后不要着急上线，等个分吧钟再上！<br/>4、功能在测试阶段，清理错误请联系GM！</font>',
 {
  btn: ['是的','算了'] //按钮
},function() {
/*	if (pwd == '') {
        layer.msg('请输入授权密码');qbpwd
        return false;
    }*/
    if (pwd == '') {
        layer.msg('请输入清包密码');
        return false;
    }
	  if(uid==''){
		  layer.msg('角色名不能为空');
		  return false;
	  }
	$.ajaxSetup({
		contentType: "application/x-www-form-urlencoded; charset=utf-8"
	});
	$.post("user/query.php", {
		type:'clearbag',uid:uid,qu:qu,qbpwd:pwd		
	},
	function(data) {
		layer.msg(data);
		
	});
}, function(){
  layer.msg('小伙子想好再来吧');
});
}}