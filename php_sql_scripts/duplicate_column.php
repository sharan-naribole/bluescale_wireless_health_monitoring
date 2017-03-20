<?php      
require_once ("auth.php"); 
?>

<?php

function duplicate($original,$duplicate)
{
	$con = mysql_connect("localhost","lpolloni_scale","bluescale");
	if (!$con)
  	{
  		die('Could not connect: ' . mysql_error());
  	}
	mysql_select_db("lpolloni_pecanpark", $con);
    
    #DETERMINING PRIMARY KEY COLUMN
    
    $sql = "SHOW INDEX FROM measure WHERE Key_name = 'PRIMARY'";
    $gp = mysql_query($sql);
    $cgp = mysql_num_rows($gp);
    if($cgp > 0){
        // Note I'm not using a while loop because I never use more than one prim key column
        $agp = mysql_fetch_array($gp);
        extract($agp);
        echo "PRIMARY KEY COLUMN = $Column_name \n";
        
    }else{
        echo "false \n";
    }
	
    #CREATING TEMPORARY TABLE, SETTING PATIENT ID WITH DUPLICATE AND INSERTING INTO ORIGINIAL TABLE
    mysql_query("CREATE table temporary_table AS SELECT * FROM measure WHERE measure.id_patient=$original");

    mysql_query("UPDATE temporary_table SET temporary_table.id_patient=$duplicate");
    
    mysql_query("UPDATE temporary_table SET temporary_table.id_measure=NULL");
    
    #$result = mysql_query("SELECT * FROM temporary_table");
    
    $sql = "INSERT INTO measure SELECT * FROM temporary_table";
    
    if (!mysql_query($sql,$con))
    {
        die('Error: ' . mysql_error($con));
    }
    echo "Successful duplication \n";
    
    $result = mysql_query("SELECT DISTINCT measure.id_patient FROM measure");
	
	$num = mysql_num_rows($result);
    
	if ($num != 0)
	{
		$counter=1;
 		while ($row = mysql_fetch_array($result))
		{
			#$timestamp=$row['reading timestamp'];
            $idd = $row['id_patient'];
			$counter=$counter+1;
            echo "$idd \n";
		}
        #echo "Total measurements: $counter";
		mysql_data_seek($result, 0);
    }

    
    mysql_query("DROP TABLE temporary_table");

    
    #echo "SUCCESS in duplicating records for patient ID = $id_original \n";
    
    mysql_close($con);
}
if (isset($_GET['original'])) $original=$_GET['original'];
if (isset($_GET['duplicate'])) $duplicate=$_GET['duplicate'];
duplicate($original,$duplicate);
?>