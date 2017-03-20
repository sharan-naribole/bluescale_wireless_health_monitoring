<?php      
require_once ("auth.php"); 
?>

<?php

function patient_id_list()
{
	$con = mysql_connect("localhost","lpolloni_scale","bluescale");
	if (!$con)
  	{
  		die('Could not connect: ' . mysql_error());
  	}
	mysql_select_db("lpolloni_pecanpark", $con);
	$result = mysql_query("SELECT DISTINCT id_patient FROM measure ORDER BY 'id_patient' ASC");
	
	$num = mysql_num_rows($result);

	if ($num != 0)
	{
		$counter=1;
 		while ($row = mysql_fetch_array($result))
		{
			$id=$row['id_patient'];
			$counter=$counter+1;
            echo "$id \n";
		}
        #echo "Total measurements: $counter";
		mysql_data_seek($result, 0);
    }
	#return array($timestamp,$weight);
	mysql_close($con);
}
patient_id_list();
?>




