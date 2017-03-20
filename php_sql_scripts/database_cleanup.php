<?php      
require_once ("auth.php"); 
?>

<?php

function cleanup($id)
{
	$con = mysql_connect("localhost","lpolloni_scale","bluescale");
	if (!$con)
  	{
  		die('Could not connect: ' . mysql_error());
  	}
	mysql_select_db("lpolloni_pecanpark", $con);
	$sql = "DELETE FROM measure WHERE measure.id_patient=$id";
	
    if (!mysql_query($sql,$con))
    {
        echo "NOT FOUND Patient ID = $id in the database \n";
        die('Error: ' . mysql_error());
    }
    echo "SUCCESS in deleting records for patient ID = $id \n";
    
    mysql_close($con);

}
if (isset($_GET['id'])) $id=$_GET['id'];
cleanup($id);
?>




