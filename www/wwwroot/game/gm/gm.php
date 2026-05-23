<?php
$t = time();
?>
<!DOCTYPE html>
<html>
<?php
include_once 'head.php';
include_once './user/config.php';
;
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
                                <b>Pokémon Thế Kỷ Mới - Quản Trị GM</b>
                            </li>
                        </ul>
                        <div class="modal-body">
                            <div class="form-horizontal" role="form">
                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <h4>Thông Tin Kết Nối</h4>
                                        <input type="password" id="checknum" name="checknum" class="form-control"
                                            maxlength="16" value="" placeholder="Nhập mã xác thực GM (GM Code)"
                                            required>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <select id="qu" name="qu" class="form-control selectpicker" data-size="5"
                                            required>
                                            <?php

                                            foreach ($quarr as $key => $value) {
                                                if ($value['hidde'] != true) {
                                                    echo '<option value="' . $key . '">' . $value['name'] . '</option>';
                                                }
                                            }

                                            ?>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <input type="text" id="uid" name="uid" class="form-control" value=""
                                            placeholder="Vui lòng nhập ID Nhân Vật" required>

                                    </div>
                                </div>

                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <h4>Hệ Thống Nạp</h4>

                                    </div>
                                </div>

                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <select id="chargetype" name="chargetype"
                                            class="selectpicker show-tick form-control" data-live-search="true"
                                            data-size="10" title="Vui lòng chọn vật phẩm/gói nạp">
                                            <?php
                                            $file = fopen("charge.txt", "r");
                                            while (!feof($file)) {
                                                $line = fgets($file);
                                                $txts = explode(';', $line);
                                                echo '<option value="' . $txts[0] . '" title="' . $txts[1] . '">' . $txts[1] . '</option>';
                                            }
                                            fclose($file);
                                            ?>
                                        </select>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <input type="text" id="chargenum" name="chargenum" class="form-control" min="0"
                                            max="9999" value="" placeholder="Số lượng" required>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <div class="col-sm-10 ">
                                        <button type="submit" class="btn btn-danger btn-block" onclick="chargebtn()">Nạp
                                            Ngay</button>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <select id="mailid" name="mailid" class="selectpicker show-tick form-control"
                                            data-live-search="true" data-size="10" title="Vui lòng chọn vật phẩm">
                                            <?php
                                            $file = fopen("xmitem.txt", "r");
                                            while (!feof($file)) {
                                                $line = fgets($file);
                                                $txts = explode(';', $line);
                                                echo '<option value="' . $txts[0] . '" title="' . $txts[1] . '">' . $txts[1] . '</option>';
                                            }
                                            fclose($file);
                                            ?>
                                        </select>
                                    </div>
                                </div>

                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <input type="text" id="mailnum" name="mailnum" class="form-control" min="0"
                                            max="9999" value="" placeholder="Số lượng" required>
                                    </div>
                                </div>



                                <div class="form-group">
                                    <div class="col-sm-10 ">
                                        <button type="submit" class="btn btn-primary btn-block"
                                            onclick="send_mail()">Gửi Quà Qua Thư</button>
                                        <!--
                    <button type="submit" class="btn btn-primary btn-block" onclick="send_allmail()">Gửi Thư Toàn Máy Chủ</button> 
                     -->
                                    </div>
                                </div>

                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <h4>Hệ Thống Cấp Quyền</h4>
                                        <input type="text" id="pwd" name="pwd" class="form-control" value=""
                                            placeholder="Nhập Mật khẩu quản trị cấp quyền" required>
                                    </div>
                                </div>
                                <div class="form-group">
                                    <div class="col-sm-10">
                                        <button type="submit" class="btn btn-primary" onclick="shouquanbtn()">Vô Hạn Kim
                                            Cương</button>
                                        <button type="submit" class="btn btn-primary" onclick="shouquanbtn1()">Cấp Quyền
                                            Tool GM</button>
                                        <button type="submit" class="btn btn-primary" onclick="unshouquan()">Hủy Bỏ
                                            Quyền</button>
                                        <button type="submit" class="btn btn-primary" onclick="editpwdbtn()">Đổi Mật
                                            Khẩu Khác</button>
                                    </div>
                                </div>
                            </div>

                        </div>

                    </div>

                </div>
            </div>
        </div>
    </div>
    <script src="js/msg.js?v=<?php echo $t; ?>"></script>
</body>

</html>