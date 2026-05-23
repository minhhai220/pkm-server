<?php
$t = time ();
?>
<!DOCTYPE html>
<html>   
<?php 
include 'head.php';
include_once './user/config.php';
?>    
<body>


 <div class="container">
   <br>
   <div class="row">
     <div class="container-fluid">
  <div class="modal-dialog">
    <div class="modal-content">
      <ul class="breadcrumb">				
				<li>
					 <b>口袋新世纪-玩家后台</b>
				</li>				
			</ul>
      <div class="modal-body">
   <div class="form-horizontal" role="form">
               

                <div class="form-group">
                    <div class="col-sm-10">
                        <input type="text" id="pwd" name="pwd"  class="form-control" maxlength="16" value="" placeholder="请输入后台密码" required>
                    </div>
                </div> 
 
				<div class="form-group">
                    <div class="col-sm-10">
                        <select id="qu" name="qu" class="form-control selectpicker" data-size="5" required>
						<?php
						foreach($quarr as $key=>$value){
							if($value['hidde']!=true){
								echo '<option value="'.$key.'">'.$value['name'].'</option>';
						}
						}
						?>
                        </select>
                    </div>
                </div>
				<div class="form-group">
                    <div class="col-sm-10">
                        <input type="text" id="uid" name="uid" class="form-control" value="" placeholder="请输入角色UID" required>
                    </div>
                </div>

				<ul class="nav nav-tabs">
			<li class="active"><a href="#chargesys" data-toggle="tab">充值</a></li>
			<li><a href="#mailsys" data-toggle="tab">邮件</a></li>
			<li><a href="#noticesys" data-toggle="tab">精灵</a></li>
			<li><a href="#managersys" data-toggle="tab">皮肤</a></li>
			<li><a href="#cdksys" data-toggle="tab">道具</a></li>
			<li><a href="#shouquan" data-toggle="tab">碎片</a></li>
			<li><a href="#chaxun" data-toggle="tab">化石</a></li>
			<li><a href="#othersys" data-toggle="tab">头信</a></li>
		    </ul>
			<div id="mytab-content" class="tab-content">
		<!--充值系统开始-->
			<div class="tab-pane fade in active" id="chargesys">
<br/>	

                <div class="form-group">
                    <div class="col-sm-10">
                        <select id="chargetype" name="chargetype" class="selectpicker show-tick form-control" data-live-search="true" data-size="10" title="请选择物品">
                         <?php
    $file = fopen("charge.txt", "r");
    while(!feof($file))
    {
      $line=fgets($file);
      $txts=explode(';',$line);
      echo '<option value="'.$txts[0].'" title="'.$txts[1].'">'.$txts[1].'</option>';
    }
    fclose($file);
    ?>							
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" maxlength="9" id="chargenum" name="chargenum" class="form-control" min="0" max="9999" value="" placeholder="数量1-999999999" required>
                    </div>
                </div>
                <div class="form-group">
                    <div class=" col-sm-10">						
						<button type="submit" class="btn btn-info btn-block" onclick="chargebtn()">帐号充值</button>					
                    </div>					
                </div>
				</div>
				<!--充值系统结束-->
				<!--邮件系统开始-->
				<div class="tab-pane fade" id="mailsys">
			<br/>
			 <div class="form-group">
                    <div class="col-sm-10">
                        <div class="input-group">
            <input type='text' class="form-control" value='' id='searchipt' placeholder='物品搜索'>
			<span class="input-group-btn"><button class="btn btn-default btn-block" type="button" id='search' >点击搜索</button></span>	
			</div>
			</div>
            </div>
				<div class="form-group">
			    <div class="col-sm-10">
			<select id='mailid' class="form-control"><option value=''>请选择需要发送的道具</option>
            <?php
            $file = fopen("item.txt", "r");
            while(!feof($file)){
                $line=fgets($file);
		        $txts=explode('|',$line);
		        if(count($txts)==2){
		            echo '<option value="'.$txts[0].'">'.$txts[1].'</option>';
		        }
            }
            fclose($file);
            ?>
            </select>

                    </div>
                </div>
				<div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" maxlength="3" id="mailnum" name="mailnum" class="form-control" min="0" max="9999" value="" placeholder="数量1-999 箱子礼包类型 一次开99个 多了容易炸" required>
                    </div>
                </div>				
                <div class="form-group">
                    <div class="col-sm-10">						
						<button type="submit" class="btn btn-danger btn-block" onclick="send_mail()">邮件发送</button>
						
                    </div>					
                </div> 

    
</div>	
<div class="tab-pane fade" id="noticesys">
			<br/>				
				<div class="form-group">
                    <div class="col-sm-10">
                        <div class="input-group">
                        <input type='text' class="form-control" value='' id='searchipt1' placeholder='精灵搜索'>
			<span class="input-group-btn"><button class="btn btn-default btn-block" type="button" id='search1' >点击搜索</button></span>	
			</div>
			</div>
            </div>
			<div class="form-group">
			    <div class="col-sm-10">
			<select id='jl' class="form-control"><option value=''>请选择需要发送的精灵</option>
            <?php
            $file = fopen("jl.txt", "r");
            while(!feof($file)){
                $line=fgets($file);
		        $txts=explode('|',$line);
		        if(count($txts)==2){
		            echo '<option value="'.$txts[0].'">'.$txts[1].'</option>';
		        }
            }
            fclose($file);
            ?>
            </select>

                    </div>
                </div>
                <div class="form-group">
                    <div class=" col-sm-10">						
						<button type="submit" class="btn btn-warning btn-block" onclick="jlzf()">发送精灵</button>					
                    </div>					
                </div>	
</div>				
<div class="tab-pane fade" id="managersys">
			<br/>
				<div class="form-group">
                    <div class="col-sm-10">
                        <select id="chargetype1" name="chargetype1" class="selectpicker show-tick form-control" data-live-search="true" data-size="10" title="请选择皮肤">
                         <?php
    $file = fopen("charge1.txt", "r");
    while(!feof($file))
    {
      $line=fgets($file);
      $txts=explode(';',$line);
      echo '<option value="'.$txts[0].'" title="'.$txts[1].'">'.$txts[1].'</option>';
    }
    fclose($file);
    ?>							
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" maxlength="5" id="chargenum1" name="chargenum1" class="form-control" min="0" max="9999" value="" placeholder="数量1-1" required>
                    </div>
                </div>
                <div class="form-group">
                    <div class=" col-sm-10">						
						<button type="submit" class="btn btn-info btn-block" onclick="chargebtn1()">发送皮肤</button>					
                    </div>					
                </div>
				</div>
<div class="tab-pane fade" id="cdksys">
			<br/>
			<div class="form-group">
                    <div class="col-sm-10">
                        <select id="chargetype3" name="chargetype3" class="selectpicker show-tick form-control" data-live-search="true" data-size="10" title="请选择物品">
                         <?php
    $file = fopen("charge3.txt", "r");
    while(!feof($file))
    {
      $line=fgets($file);
      $txts=explode(';',$line);
      echo '<option value="'.$txts[0].'" title="'.$txts[1].'">'.$txts[1].'</option>';
    }
    fclose($file);
    ?>							
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" maxlength="5" id="chargenum3" name="chargenum3" class="form-control" min="0" max="9999" value="" placeholder="数量1-99999" required>
                    </div>
                </div>
                <div class="form-group">
                    <div class=" col-sm-10">						
						<button type="submit" class="btn btn-info btn-block" onclick="chargebtn3()">发送道具</button>					
                    </div>					
                </div>				
			</div>	
<div class="tab-pane fade" id="shouquan">
<br>			
<div class="form-group">
                    <div class="col-sm-10">
                        <select id="chargetype2" name="chargetype2" class="selectpicker show-tick form-control" data-live-search="true" data-size="10" title="请选择物品">
                         <?php
    $file = fopen("charge2.txt", "r");
    while(!feof($file))
    {
      $line=fgets($file);
      $txts=explode(';',$line);
      echo '<option value="'.$txts[0].'" title="'.$txts[1].'">'.$txts[1].'</option>';
    }
    fclose($file);
    ?>							
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" maxlength="4" id="chargenum2" name="chargenum2" class="form-control" min="0" max="9999" value="" placeholder="数量" required>
                    </div>
                </div>
                <div class="form-group">
                    <div class=" col-sm-10">						
						<button type="submit" class="btn btn-info btn-block" onclick="chargebtn2()">发送碎片</button>					
                    </div>					
                </div>
 </div> 
 <div class="tab-pane fade" id="chaxun">
<br/>
<div class="form-group">
                    <div class="col-sm-10">
                        <select id="chargetype4" name="chargetype1" class="selectpicker show-tick form-control" data-live-search="true" data-size="10" title="请选择化石">
                         <?php
    $file = fopen("charge4.txt", "r");
    while(!feof($file))
    {
      $line=fgets($file);
      $txts=explode(';',$line);
      echo '<option value="'.$txts[0].'" title="'.$txts[1].'">'.$txts[1].'</option>';
    }
    fclose($file);
    ?>							
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" maxlength="3" id="chargenum4" name="chargenum4" class="form-control" min="0" max="9999" value="" placeholder="数量1-999" required>
                    </div>
                </div>
                <div class="form-group">
                    <div class=" col-sm-10">						
						<button type="submit" class="btn btn-info btn-block" onclick="chargebtn4()">发送化石</button>					
                    </div>					
                </div>
</div>
<div class="tab-pane fade" id="othersys">
			<br/>    
<div class="form-group">
                    <div class="col-sm-10">
                        <select id="chargetype5" name="chargetype5" class="selectpicker show-tick form-control" data-live-search="true" data-size="10" title="请选择头像信物称号">
                         <?php
    $file = fopen("charge5.txt", "r");
    while(!feof($file))
    {
      $line=fgets($file);
      $txts=explode(';',$line);
      echo '<option value="'.$txts[0].'" title="'.$txts[1].'">'.$txts[1].'</option>';
    }
    fclose($file);
    ?>							
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <div class="col-sm-10">					    
                        <input type="text" onkeyup="value=value.replace(/^(0+)|[^\d]+/g,'')" maxlength="1" id="chargenum5" name="chargenum5" class="form-control" min="0" max="9999" value="" placeholder="数量1-1" required>
                    </div>
                </div>
                <div class="form-group">
                    <div class=" col-sm-10">						
						<button type="submit" class="btn btn-info btn-block" onclick="chargebtn5()">发送头信称</button>					
                    </div>					
                </div>						
</div>	 



            </div>
      </div>
    </div>
  </div>
     </div>
   </div>
 </div>
 <script src="js/playermsg.js?v=<?php echo $t;?>"></script>
</body>
</html>