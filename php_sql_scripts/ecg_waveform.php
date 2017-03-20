<?php
require_once ("auth.php"); 
?>

<?php

function hex2sdec ($hex)
{
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

function ecg_select($id,$ts)
{
    #echo "Timestamp ID = $ts \n";
    
	$con = mysql_connect("localhost","lpolloni_scale","bluescale");
	if (!$con)
  	{
  		die('Could not connect: ' . mysql_error());
  	}
	mysql_select_db("lpolloni_pecanpark", $con);
	$result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' ASC");
    $num = mysql_num_rows($result);
    #echo "Number of measurements = $num \n";
    
    $ts_loc = $num - $ts;
    $result = mysql_query("SELECT * FROM measure WHERE measure.id_patient=$id ORDER BY 'reading timestamp' ASC LIMIT $ts_loc,1");
    $row = mysql_fetch_array($result);
    $id_m=$row['id_measure'];
    $wave=$row['waveform'];
    $timestamp=$row['reading timestamp'];
    
    #echo "Timestamp: $timestamp \n";
        
    if ($wave != NULL)
    {
        $counter=1;
        for ($i = 0*(4*12500); $i < 1*(4*12500); $i=$i+4)
        {
            $point=hex2sdec(substr($wave,$i,4));
            #echo "$counter | $point \n";
            echo "$point \n";
            $counter++;
        }
    }
    return 0;
    mysql_close($con);
}

if (isset($_GET['id'])) $id=$_GET['id'];
if (isset($_GET['ts'])) $ts=$_GET['ts'];
    
$dummy=ecg_select($id,$ts);
?>