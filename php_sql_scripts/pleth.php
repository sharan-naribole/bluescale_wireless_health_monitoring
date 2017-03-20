<?php      
require_once ("auth.php");
?>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />

<link rel="stylesheet" type="text/css" href="styles.css" />

<title>BlueScale</title>

</head>

<!--<script type="text/javascript" src="jscharts.js"></script>-->

<script type="text/javascript" src="http://www.google.com/jsapi"></script> 
    



<body>

<?php

function hex2sdec ($hex)
{
  //how many bytes
  /*$ib = strlen ($hex) - (strlen ($hex) % $hex)) / $hex;
  if ((strlen ($hex) % 2) > 0) $ib = $ib + 1;

  //how many bites
  $ibb = 8 * $ib;
	
  $ibb=32;	
  //search for -1 value (max_uj)
  $buf = '1';
  for ($i = 1; $i <= $ibb - 1; $i++)
  {
    $buf .= '0';
  }
  $max_uj = bindec ($buf);*/

$ib=2;
$ibb=16;
  $max_uj =32768;

  //decide a sign, and calculate a value
  if (hexdec ($hex) < $max_uj)
  //+
  {
    $sdec = hexdec ($hex);
  }
  else
  //-
  {
    //search for max value + 1
    //(for ex. if hex = 23ef then max_p1 = ffff + 1)
    $buf = '';
    for ($i = 1; $i <= $ib; $i++)
    {
      $buf .= 'ff';
    }
    $max_p1 = hexdec ($buf) + 1;

    $sdec = hexdec ($hex) - $max_p1;
  }

  return $sdec;
}

function pleth_select($id)
{
	$con = mysql_connect("localhost","lpolloni_scale","bluescale");
	if (!$con)
  	{
  		die('Could not connect: ' . mysql_error());
  	}
	mysql_select_db("lpolloni_pecanpark", $con);
	$result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' DESC");

	$num = mysql_num_rows($result);
	$row = mysql_fetch_array($result);
	$id_m=$row['id_measure'];
	$wave=$row['waveform'];	//The blob parse is different from 0 only for the first 65536 bytes...so the pleth is truncated
	if ($wave != NULL)
	{
 		$file= fopen("data.xml", "w");
 		$_xml ="<?xml version=\"1.0\"?>\r\n";
 		$_xml .="<JSChart>\r\n";
		$_xml .="<dataset type=\"line\">\r\n";
		$counter=1;
		for ($i = 3*(4*12500); $i < 4*(4*12500); $i=$i+4)
		{
    			$point=hex2sdec(substr($wave,$i,4));
			if ($i%(4*4)==0)
			{
				$_xml .="\t<data unit=\"".$counter."\" value=\"".$point."\"/>\r\n";
				$counter++;
			}	
		}
		$_xml .="</dataset>\r\n";


		$_xml .="<optionset>\r\n"; 
		for ($i = 1; $i <= 10; $i++)
		{
			$x=$i*(1000/4);
			$xx=$i;	
    			$_xml .="\t<option set=\"setLabelX\" value=\"[".$x.", '".$xx."']\"/>\r\n";
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

	return $wave;     
	mysql_close($con);
}

if (isset($_GET['id'])) $id=$_GET['id'];
if (isset($_GET['ts'])) $ts=$_GET['ts'];
if ($ts=="")
{
	$con = mysql_connect("localhost","lpolloni_scale","bluescale");
	if (!$con)
		{
			die('Could not connect: ' . mysql_error());
		}
	mysql_select_db("lpolloni_pecanpark", $con);
	$result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' DESC LIMIT 1");
	mysql_close($con);
	$row = mysql_fetch_array($result);
	$ts=$row['reading timestamp'];	
}
 
$wave=pleth_select($id); 

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
				<li><a href="ekg.php?id=<?php echo $id ?>" title="Heart Stats">Heart Stats</a></li>
				<li><a href="ecg.php?id=<?php echo $id."&ts=".urlencode($ts) ?>" title="ECG">ECG</a></li>
				<li><a href="pleth.php?id=<?php echo $id."&ts=".urlencode($ts) ?>" title="Pulse" class="current">Pulse</a></li>
				<li><a href="trends.php?id=<?php echo $id ?>" title="Trends">Trends</a></li>
			</ul>
		</div>
		<div id="content">
			<div id="sidebar">
			
				<h4>Patients Database</h4>
				<!-- <ul>
					<li><?php if ($id==1) echo'<a href=pleth.php?id=1 style="background-color:gainsboro">ID# 1'; else echo'<a href=pleth.php?id=1>ID# 1'?></a></li>
					<li><?php if ($id==2) echo'<a href=pleth.php?id=2 style="background-color:gainsboro">ID# 2'; else echo'<a href=pleth.php?id=2>ID# 2'?></a></li>
					<li><?php if ($id==3) echo'<a href=pleth.php?id=3 style="background-color:gainsboro">ID# 3'; else echo'<a href=pleth.php?id=3>ID# 3'?></a></li>
					<li><?php if ($id==4) echo'<a href=pleth.php?id=4 style="background-color:gainsboro">ID# 4'; else echo'<a href=pleth.php?id=4>ID# 4'?></a></li>
					<li><?php if ($id==5) echo'<a href=pleth.php?id=5 style="background-color:gainsboro">ID# 5'; else echo'<a href=pleth.php?id=5>ID# 5'?></a></li>
					<li><?php if ($id==6) echo'<a href=pleth.php?id=6 style="background-color:gainsboro">ID# 6'; else echo'<a href=pleth.php?id=6>ID# 6'?></a></li>
					<li><?php if ($id==7) echo'<a href=pleth.php?id=7 style="background-color:gainsboro">ID# 7'; else echo'<a href=pleth.php?id=7>ID# 7'?></a></li>
					<li><?php if ($id==8) echo'<a href=pleth.php?id=8 style="background-color:gainsboro">ID# 8'; else echo'<a href=pleth.php?id=8>ID# 8'?></a></li>
					<li><?php if ($id==9) echo'<a href=pleth.php?id=9 style="background-color:gainsboro">ID# 9'; else echo'<a href=pleth.php?id=9>ID# 9'?></a></li>
					<li><?php if ($id==10) echo'<a href=pleth.php?id=10 style="background-color:gainsboro">ID# 10'; else echo'<a href=pleth.php?id=10>ID# 10'?></a></li>
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
				<form action="pleth.php" method="get"> 
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
				<h2>Pleth Waveform</h2>
				
				
				<?php 
					$con = mysql_connect("localhost","lpolloni_scale","bluescale");
						if (!$con)
						{
							die('Could not connect: ' . mysql_error());
						}
					mysql_select_db("lpolloni_pecanpark", $con);
					$result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' DESC");
					mysql_close($con);					
				?>
				
				<form action="pleth.php" method="get">
				<input type="hidden" name="id" value="<?php echo $id;?>">
				<select name="ts"> 
				<?php 
					while ($row = mysql_fetch_array($result))
					{ 
						if ($row["reading timestamp"]==$ts) echo "<option value=\"".$row["reading timestamp"]."\" selected=\"selected\">".$row["reading timestamp"]."</option>\n";
						else echo "<option value=\"".$row["reading timestamp"]."\">".$row["reading timestamp"]."</option>\n";							
					} 
				?> 
				</select>
				<input type="submit" value="Display">
				</form>
	
	
	<script type="text/javascript"> 
      google.load("visualization", "1", {packages:["annotatedtimeline"]}); 
      google.setOnLoadCallback(drawData); 
      function drawData()
	  { 
        var data = new google.visualization.DataTable(); 
        data.addColumn('datetime', 'Datapoint'); 
        data.addColumn('number', 'Intensity'); 
		<?php
			$con = mysql_connect("localhost","lpolloni_scale","bluescale");
			if (!$con)
			{
				die('Could not connect: ' . mysql_error());
			}
			mysql_select_db("lpolloni_pecanpark", $con);
			$result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' DESC");
			mysql_close($con);
			$int_y_pos = -1; 
			$int_y_step_small = 1;
			$num = mysql_num_rows($result);
			while (1)
			{
				$row = mysql_fetch_array($result);
				$timestamp=$row['reading timestamp'];
				if ($timestamp==$ts) break;
			}
				
			$id_m=$row['id_measure'];
			$timestamp=$row['reading timestamp'];
			$year=substr($timestamp,0,4);
			$month=substr($timestamp,5,2)-1;
			$day=substr($timestamp,8,2);
			$hours=substr($timestamp,11,2);
			$mins=substr($timestamp,14,2);
			$secs=substr($timestamp,17,2);		
							
			
			$wave=$row['waveform'];	//The blob parse is different from 0 only for the first 65536 bytes...so the pleth is truncated			
			//echo "data.addRows(2500);\n";
			echo "data.addRows(3125);\n";
			if ($wave != NULL)
				{
					$counter=1;
					$msecs=0;
					for ($i = 3*(4*12500); $i < 4*(4*12500); $i=$i+4)
					{
							$point=hex2sdec(substr($wave,$i,4));
						if ($i%(4*4)==0)
						{
							$int_y_pos += $int_y_step_small;
							//if ($int_y_pos%25==0)
							// echo "		data.setValue(" . $int_y_pos . ", 0, '" . $int_y_pos/250 . "');\n";
							// else
							// echo "		data.setValue(" . $int_y_pos . ", 0, '');\n";
							
							echo "		data.setValue(" . $int_y_pos . ", 0, new Date(" . $year .",". $month .",". $day .",". $hours .",". $mins .",". $secs .",". $msecs . ")); \n";
							echo "		data.setValue(" . $int_y_pos . ", 1, " . $point . "); \n";
							$msecs=$msecs+4;
							if ($msecs%1000==0)
							{
								$secs+=1;
								$msecs=0;
							}							
						}	
					}
				}
		?> 
        //var wave = new google.visualization.LineChart(document.getElementById('chart_div')); 
        //wave.draw(data, {width: 0.57*screen.width, height: 0.38*screen.height, legend: 'none', pointSize:0, axisFontSize:13, legendFontSize:13, lineSize:2, showCategories:true, titleX:'Time[s]'});
		var trend = new google.visualization.AnnotatedTimeLine(document.getElementById('chartcontainer'));
		trend.draw(data, {displayZoomButtons: false, displayRangeSelector: false, displayExactValues: true}); 
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


