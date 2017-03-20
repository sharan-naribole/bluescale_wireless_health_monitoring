<?php      
require_once ("auth.php"); 
?>

<?php

function weight_select($id)
{
	$con = mysql_connect("localhost","lpolloni_scale","bluescale");
	if (!$con)
  	{
  		die('Could not connect: ' . mysql_error());
  	}
	mysql_select_db("lpolloni_pecanpark", $con);
	$result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' ASC");
    $height=$row['height'];
	
	$num = mysql_num_rows($result);

	if ($num != 0)
	{
		$counter=1;
 		while ($row = mysql_fetch_array($result))
		{
			$timestamp=$row['reading timestamp'];
            $impedance = $row['impedance_mag'];
            #$impedance = sprintf("%2.1f",$height*$height/$impedance);
			$counter=$counter+1;
            echo "$timestamp | $impedance \n";
		}
        #echo "Total measurements: $counter";
		mysql_data_seek($result, 0);
    }
	#return array($timestamp,$weight);
	mysql_close($con);
}
if (isset($_GET['id'])) $id=$_GET['id'];
weight_select($id);
?>




