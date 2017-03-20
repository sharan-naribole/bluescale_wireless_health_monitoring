<?php      
require_once ("auth.php"); 
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />

<link rel="stylesheet" type="text/css" href="styles.css" />

<title>BlueScale</title>

<script type="text/javascript">
function refresh(id,param)
{

}
</script>


</head>

<!--<script type="text/javascript" src="jscharts.js"></script>-->

<script type="text/javascript" src="http://www.google.com/jsapi"></script>

<body>

<?php

function average($array){
    $sum   = array_sum($array);
    $count = count($array);
    return $sum/$count;
}

//The average function can be use independantly but the deviation function uses the average function.

function deviation ($array){
    
    $avg = average($array);
    foreach ($array as $value) {
        $variance[] = pow($value-$avg, 2);
    }
    $deviation = sqrt(average($variance));
    return $deviation;
}


function select($id,$param)
{
	$con = mysql_connect("localhost","lpolloni_scale","bluescale");
	if (!$con)
  	{
  		die('Could not connect: ' . mysql_error());
  	}
	mysql_select_db("lpolloni_pecanpark", $con);
	$result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' ASC");
	
	$num = mysql_num_rows($result);

	switch ($param)
	{
	case 'Cardiac Output':
        	$db_param='cardiac output';
       	break;
    case 'STI':
        	$db_param='sti';
        	break;
    case 'QRS':
        	$db_param='qrs';
        	break;
	case 'Heart Rate':
        	$db_param='rr';
			break;
	case 'RR Variation':
			$db_param='rr_std';
			break;
	case 'Total Body Water':
        	$db_param='impedance';
			break;
	case 'Weight':
        	$db_param='weight';
			break;
	}

	
	$row = mysql_fetch_array(mysql_query("SELECT * FROM patient WHERE id_patient=$id"));
	$height=$row['height'];

	if ($num > 1)
	{
 		$file= fopen("data.xml", "w");
 		$_xml ="<?xml version=\"1.0\"?>\r\n";
 		$_xml .="<JSChart>\r\n";
		$_xml .="<dataset type=\"line\">\r\n";
		
		
		if ($db_param=='rr_std')
		{
			$counter=1;
			$rr_array=array();
			while ($row = mysql_fetch_array($result))
			{
				$rr=$row['rr'];
				$rr_array[$counter]=$rr;
				$counter=$counter+1;
			}
		}

//print_r($rr_array);

		mysql_data_seek($result, 0);
		$counter=1;
 		while ($row = mysql_fetch_array($result))
		{
			$timestamp=$row['reading timestamp'];
			$value=$row[$db_param];
			if ($db_param=='rr_std') $value=sprintf("%2.1f",deviation(array_slice($rr_array,count($rr_array)-$counter)));
			if ($db_param=='rr') $value=sprintf("%2.1f",60*1000/$value);
			if ($db_param=='impedance') $value=sprintf("%2.1f",$height*$height/$value);
 			$_xml .="\t<data unit=\"".$counter."\" value=\"".$value."\"/>\r\n";
			$counter=$counter+1;
		}
		$_xml .="</dataset>\r\n";
		$_xml .="<optionset>\r\n";
		mysql_data_seek($result, 0);
		$counter=1; 
		while ($row = mysql_fetch_array($result))
		{
			$ts=substr($row['reading timestamp'],5,5);
			$value=$row[$db_param];
			if ($db_param=='rr_std') $value=sprintf("%2.1f",deviation(array_slice($rr_array,count($rr_array)-$counter)));
			if ($db_param=='rr') $value=sprintf("%2.1f",60*1000/$value);
			if ($db_param=='impedance') $value=sprintf("%2.1f",$height*$height/$value);
 			$_xml .="\t<option set=\"setLabelX\" value=\"[".$counter.", '".$ts."']\"/>\r\n";
			$_xml .="\t<option set=\"setTooltip\" value=\"[".$counter.", '".$value."']\"/>\r\n";
			$counter=$counter+1;
		}
		$_xml .="\t<option set=\"setAxisValuesNumberX\" value=\"1\"/>\r\n";
		$_xml .="</optionset>\r\n";
 		$_xml .="</JSChart>";
 		fwrite($file, $_xml);
	}
	else
	{
		$file= fopen("data.xml", "w");
 		$_xml ="<?xml version=\"1.0\"?>\r\n";
 		$_xml .="<JSChart>\r\n";
		$_xml .="<dataset type=\"line\">\r\n";
		$_xml .="\t<data unit=\"0\" value=\"0\"/>\r\n";
		$_xml .="\t<data unit=\"1\" value=\"0\"/>\r\n";
		$_xml .="</dataset>\r\n";
		$_xml .="<optionset>\r\n";
		mysql_data_seek($result, 0);
		$counter=1; 
		while ($row = mysql_fetch_array($result))
		{
			$timestamp=substr($row['reading timestamp'],5,5);
 			$_xml .="\t<option set=\"setLabelX\" value=\"[".$counter.", '".$timestamp."']\"/>\r\n";
			$counter=$counter+1;
		}
		$_xml .="\t<option set=\"setAxisValuesNumberX\" value=\"1\"/>\r\n";
		$_xml .="</optionset>\r\n";
 		$_xml .="</JSChart>";
 		fwrite($file, $_xml);
	}
 	fclose($file);

	//return array($timestamp,$imp,$coutput,$height,$num);     
	return $result;
	mysql_close($con);
}

if (isset($_GET['id'])) $id=$_GET['id'];
if (isset($_GET['param'])) $param=$_GET['param'];
	else $param='Cardiac Output';
 
//list($timestamp,$imp,$coutput,$height,$num)=select($id,$param); 
$result=select($id,$param);

?>

<div id="container">

		<div id="banner">
			<img src="AbramsonCenterlogo_new.gif" width="100%">
		</div>

		<div id="header">
			<h1>
				Patient #<?php echo $id ?>
			</h1>

			<h5>
				Logged user: <?php echo $last_name; ?>, <?php echo $first_name; ?>
			</h5>
		</div>
		<div id="menu">
			<ul>
				<li><a href="bio.php?id=<?php echo $id ?>" title="Home page" >Patient Summary</a></li>
				<li><a href="ekg.php?id=<?php echo $id ?>" title="Heart Stats" >Heart Stats</a></li>
				<li><a href="ecg.php?id=<?php echo $id ?>" title="ECG">ECG</a></li>
				<li><a href="pleth.php?id=<?php echo $id ?>" title="Pulse">Pulse</a></li>
				<li><a href="trends.php?id=<?php echo $id ?>" title="Trends" class="current">Trends</a></li>
			</ul>
		</div>
		<div id="content">
			<div id="sidebar">
				<h4>Patients Database</h4>
				<!-- <ul>
					<li><?php if ($id==1) echo'<a href=trends.php?id=1 style="background-color:gainsboro">ID# 1'; else echo'<a href=trends.php?id=1>ID# 1'?></a></li>
					<li><?php if ($id==2) echo'<a href=trends.php?id=2 style="background-color:gainsboro">ID# 2'; else echo'<a href=trends.php?id=2>ID# 2'?></a></li>
					<li><?php if ($id==3) echo'<a href=trends.php?id=3 style="background-color:gainsboro">ID# 3'; else echo'<a href=trends.php?id=3>ID# 3'?></a></li>
					<li><?php if ($id==4) echo'<a href=trends.php?id=4 style="background-color:gainsboro">ID# 4'; else echo'<a href=trends.php?id=4>ID# 4'?></a></li>
					<li><?php if ($id==5) echo'<a href=trends.php?id=5 style="background-color:gainsboro">ID# 5'; else echo'<a href=trends.php?id=5>ID# 5'?></a></li>
					<li><?php if ($id==6) echo'<a href=trends.php?id=6 style="background-color:gainsboro">ID# 6'; else echo'<a href=trends.php?id=6>ID# 6'?></a></li>
					<li><?php if ($id==7) echo'<a href=trends.php?id=7 style="background-color:gainsboro">ID# 7'; else echo'<a href=trends.php?id=7>ID# 7'?></a></li>
					<li><?php if ($id==8) echo'<a href=trends.php?id=8 style="background-color:gainsboro">ID# 8'; else echo'<a href=trends.php?id=8>ID# 8'?></a></li>
					<li><?php if ($id==9) echo'<a href=trends.php?id=9 style="background-color:gainsboro">ID# 9'; else echo'<a href=trends.php?id=9>ID# 9'?></a></li>
					<li><?php if ($id==10) echo'<a href=trends.php?id=10 style="background-color:gainsboro">ID# 10'; else echo'<a href=trends.php?id=10>ID# 10'?></a></li>
				</ul> -->
				
				<?php 
					$con = mysql_connect("localhost","lpolloni_scale","bluescale");
						if (!$con)
						{
							die('Could not connect: ' . mysql_error());
						}
						mysql_select_db("lpolloni_pecanpark", $con);
					$result = mysql_query("SELECT DISTINCT id_patient FROM measure ORDER BY id_patient"); 
				?> 
				<form action="trends.php" method="get"> 
				<select name="id"> 
				<?php 
					while ($row = mysql_fetch_array($result))
					{ 
						if ($row[id_patient]==$id) echo "<option value=\"$row[id_patient]\" selected=\"selected\">$row[id_patient]</option>\n";
						else echo "<option value=\"$row[id_patient]\">$row[id_patient]</option>\n";						
					} 
				?> 
				</select> 
				<input type="submit" value="Go"> 
				</form> 
				
				
			</div>

			<div id="page">
				
			  	
					<p><table><tr>
					<td><a href="trends.php?id=<?php echo $id ?>&param=<?php echo 'Cardiac Output' ?>" title="Cardiac Output" >Cardiac Output</a></td><td>&nbsp;&nbsp;</td>
					<td><a href="trends.php?id=<?php echo $id ?>&param=<?php echo 'STI' ?>" title="sti" >STI</a></td><td>&nbsp;&nbsp;</td>
					<td><a href="trends.php?id=<?php echo $id ?>&param=<?php echo 'QRS' ?>" title="qrs" >QRS</a></td><td>&nbsp;&nbsp;</td>
					<td><a href="trends.php?id=<?php echo $id ?>&param=<?php echo 'Heart Rate' ?>" title="Heart Rate" >Heart rate</a></td><td>&nbsp;&nbsp;</td>
					<td><a href="trends.php?id=<?php echo $id ?>&param=<?php echo 'RR Variation' ?>" title="RR Variation" >RR Variation</a></td><td>&nbsp;&nbsp;</td>
					<td><a href="trends.php?id=<?php echo $id ?>&param=<?php echo 'Total Body Water' ?>" title="Total Body Water" >Total body water</a></td><td>&nbsp;&nbsp;</td>
					<td><a href="trends.php?id=<?php echo $id ?>&param=<?php echo 'Weight' ?>" title="Weight" >Weight</a></td>
					</tr></table></p>
				
				<h2><?php echo $param ?></h2> 				

				

				
				<script type="text/javascript"> 
					  google.load("visualization", "1", {packages:["annotatedtimeline"]}); 
					  google.setOnLoadCallback(drawData); 
					  function drawData()
					  { 
						var data = new google.visualization.DataTable(); 
						data.addColumn('datetime', 'Date');  
						<?php	
							$con = mysql_connect("localhost","lpolloni_scale","bluescale");
							if (!$con)
							{
								die('Could not connect: ' . mysql_error());
							}
							mysql_select_db("lpolloni_pecanpark", $con);
							$result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' ASC");
							$int_y_pos = -1; 
							$int_y_step_small = 1;
							$num = mysql_num_rows($result);
							
							switch ($param)
							{
							case 'Cardiac Output':
									$db_param='cardiac output';
									echo "data.addColumn('number', 'Cardiac Output');";
								break;
							case 'STI':
									$db_param='sti';
									echo "data.addColumn('number', 'STI');";
									break;
							case 'QRS':
									$db_param='qrs';
									echo "data.addColumn('number', 'QRS');";
									break;
							case 'Heart Rate':
									$db_param='rr';
									echo "data.addColumn('number', 'RR interval');";
									break;
							case 'RR Variation':
									$db_param='rr_std';
									echo "data.addColumn('number', 'RR variation');";
									break;
							case 'Total Body Water':
									$db_param='impedance_mag';
									echo "data.addColumn('number', 'Total Body Water');";
									break;
							case 'Weight':
									$db_param='weight';
									echo "data.addColumn('number', 'Weight');";
									break;
							}
					
						$row = mysql_fetch_array(mysql_query("SELECT * FROM patient WHERE id_patient=$id"));
						$height=$row['height'];
					
						if ($db_param=='rr_std')
							{
								$counter=1;
								$rr_array=array();
								while ($row = mysql_fetch_array($result))
								{
									$rr=$row['rr'];
									$rr_array[$counter]=$rr;
									$counter=$counter+1;
								}
							}

							
							mysql_data_seek($result, 0);			
							echo "data.addRows(".$num.");\n";
							
							
						while ($row = mysql_fetch_array($result))
						{
							$int_y_pos += $int_y_step_small; 
							$timestamp=$row['reading timestamp'];
							$year=substr($timestamp,0,4);
							$month=substr($timestamp,5,2)-1;
							$day=substr($timestamp,8,2);
							$hours=substr($timestamp,11,2)-6;
							$mins=substr($timestamp,14,2);							
							$value=$row[$db_param];
							if ($value==0){
							if ($db_param=='rr_std') $value=sprintf("%2.1f",deviation(array_slice($rr_array,count($rr_array)-$counter)));
							if ($db_param=='rr') $value=sprintf("%2.1f",60*1000/$value);
							if ($db_param=='impedance') $value=sprintf("%2.1f",$height*$height/$value);
							}
							echo "		data.setValue(" . $int_y_pos . ", 0, new Date(" . $year .",". $month .",". $day .",". $hours .",". $mins . ")); \n";
							echo "		data.setValue(" . $int_y_pos . ", 1, " . $value . "); \n";
							$counter=$counter+1;
						}
						mysql_close($con);
						?> 
						var trend = new google.visualization.AnnotatedTimeLine(document.getElementById('chartcontainer')); 
						trend.draw(data, {displayExactValues: true}); 
					  } 
				</script> 

				
				<div id="chartcontainer" style='width: 800px; height: 400px;'>
					
				</div>

			</div>
		</div>
	
	<div id="footer">
		<p> </p>
	</div>

</div>



</body>
</html>


