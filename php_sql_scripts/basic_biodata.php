<?php
require_once ("auth.php");
?>

<?php
    
    function patient_select($id)
    {
        $con = mysql_connect("localhost","lpolloni_scale","bluescale");
        if (!$con)
        {
            die('Could not connect: ' . mysql_error());
        }
        mysql_select_db("lpolloni_pecanpark", $con);
        $result = mysql_query("SELECT * FROM patient WHERE id_patient=$id");
        while($row = mysql_fetch_array($result))
        {
            $id_patient=$row['id_patient'];
            $age=$row['age'];
            $height=$row['height'];
            $gender=$row['gender'];
            $smoker=$row['smoker'];
            $diabetic=$row['diabetic'];
            $condition=$row['medical condition'];
            $treatment=$row['treatment'];
        }
        return array ($id_patient, $age, $height, $gender, $smoker, $diabetic, $condition, $treatment);
        mysql_close($con);
    }
    
    function device_select($id)
    {
        $con = mysql_connect("localhost","lpolloni_scale","bluescale");
        if (!$con)
        {
            die('Could not connect: ' . mysql_error());
        }
        mysql_select_db("lpolloni_pecanpark", $con);
        $result = mysql_query("SELECT id_device FROM measure WHERE measure.id_patient=$id");
        $row=mysql_fetch_array($result);
        $device=$row['id_device'];
        $result = mysql_query("SELECT * FROM device WHERE device.id_device=$device");
        while($row = mysql_fetch_array($result))
        {
            $id_device=$row['id_device'];
            $sn=$row['serial number'];
            $model=$row['model'];
            $manuf=$row['manufacturing date'];
        }
        return array ($id_device, $sn, $model, $manuf);     
        mysql_close($con);
    }
    
    if (isset($_GET['id'])) $id=$_GET['id'];  
    list($id_patient, $age, $height, $gender, $smoker, $diabetic, $condition, $treatment)=patient_select($id);
    list($id_device, $sn, $model, $manuf)=device_select($id);
    
    ?>

ID:<?php echo $id_patient.PHP_EOL ?>
Age:<?php echo $age.PHP_EOL ?>
Height:<?php echo $height.PHP_EOL ?>
Gender:<?php echo $gender.PHP_EOL ?>
Smoker:<?php echo $smoker.PHP_EOL ?>
Diabetic:<?php echo $diabetic.PHP_EOL ?>
Device:<?php echo $id_device.PHP_EOL ?>
S/N:<?php echo $sn .PHP_EOL?>
Model:<?php echo $model.PHP_EOL ?>
Condition:<?php echo $condition.PHP_EOL ?>
Treatment:<?php echo $treatment.PHP_EOL ?>




