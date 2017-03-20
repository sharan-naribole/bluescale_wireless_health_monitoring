<?php
// In PHP versions earlier than 4.1.0, $HTTP_POST_FILES should be used instead
// of $_FILES.


// Function to compute the float value from the ascii string
	function compute_float_val($str)
	{
        	$bin1  = base_convert($str,16,2);	//hex2bin conversion
        	$exp1  = substr($bin1,0,8);		//exponent field
        	$mant1 = "1" . substr($bin1,-23);	//mantissa field
        	$bin2 = base_convert($exp1,2,10);	//exponent converted in decimal base...
        	$bin3 = $bin2 - 127;			//...and subtracted 127 (IEEE754)
        	//echo $bin3;
        	$arr1 = str_split($mant1);		//mantissa split into array
        	//echo "<br />";
        	$sum = 0.0;
        	foreach ($arr1 as $i => $v)		//for each elemnt of the mantissa..
        	{
                	$temp = pow( 0.5, $i);		//...conversion to decimal
                	if ($v=="1")
                	{
                        $sum = $sum + $temp;
                	}

        	}
        	$sum = $sum * pow (2, $bin3);		//Final calculation of the floating point result
        	return $sum;
	}

	// Function to compute hex to ascii string
	function string_to_ascii($str)
	{
        	$arr = str_split($str,2);
		$str_out='';
        	foreach ($arr as $i)		//for each elemnt of the mantissa..
        	{
                	$str_out=$str_out.chr(base_convert($i,16,10));

        	}
        	return $str_out;
	}

	// Function to compute hex to ascii string
	function string_to_timestamp($str)
	{
        	return $str_out=substr($str,4,4).'-'.substr($str,0,2).'-'.substr($str,2,2);
	}


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





chdir('..');		//FTP destination folder
chdir('data');

$uploadfile = basename($_FILES['userfile']['name']);

echo '<pre>';
if (move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile)) {
    echo "File is valid, and was successfully uploaded.\n";
} else {
    echo "Possible file upload attack!\n";
}

//echo 'Here is some more debugging info:';




$new_file='bb01.txt';
			
 	$logfile = fopen('log.txt', 'a') or die ("A new file cannot be created");
	$message="\n";
	$message.=date("Y-m-d G:i:s")." ".$new_file." file transmitted";	//Add filename
	$message.="\n";
       fwrite($logfile, $message);
	fclose($logfile);		

       echo $bbfilecontent = file_get_contents($new_file);
	
       $id_patient=string_to_ascii(substr($bbfilecontent,32,16));	//patient found at position 32, //ASCII conversion (byte x byte)
	$id_device=substr($bbfilecontent,0,16);		//device found at position 0
			
	$qrs=compute_float_val(substr($bbfilecontent,52,8));		//qrs found at position 52
	//$rr_ecg = compute_float_val(substr($bbfilecontent,60,8));	//RR_ecg found at position 60
	$rr = compute_float_val(substr($bbfilecontent,68,8));	//RR found at position 68
	$hr_ecg=substr($bbfilecontent,76,4);		//HR ECG position 76
	$hr_pleth=substr($bbfilecontent,80,4);		//HR ECG position 80
       $sti = compute_float_val(substr($bbfilecontent,84,8));	//STI found at position 84
			
	$pwv=50;	//fake
             
	$weight=200;		//fake

	$ecg_samples=substr($bbfilecontent,164,4);		//floating point?????

	$ecg_rate=compute_float_val(substr($bbfilecontent,168,8));		//floating point looks correct (1000=1kHz)

	$pleth_samples=substr($bbfilecontent,176,4);		//floating point?????

	$pleth_rate=compute_float_val(substr($bbfilecontent,180,8));		//floating point looks correct (1000=1kHz)

	$data=substr($bbfilecontent,202,80000);		// format: 32bit binary (10000samples ecg, 10000 pleth); no waveforms with mobile phone

	
		//for ($i = 1*(4*10000); $i < 2*(4*10000); $i=$i+4)
		//{
    		//	echo $point=hex2sdec(substr($data,$i,4))."\n";
		//}


	$day_ts=string_to_timestamp(string_to_ascii(substr($bbfilecontent,16,16)));	//ASCII conversion (byte x byte)
	$timestamp=string_to_ascii(substr($bbfilecontent,144,16))." ";	// timestamp at 144, 16 16bit elements
	$day_ts=$day_ts." ".$timestamp;

	$response='green';	//fake

	//$impedance=compute_float_val(substr($bbfilecontent,202+16,8));	//Bioimpedance Magnitude found at position 84;
	$impedance=500;
	$impedance=compute_float_val(substr($bbfilecontent,202+80000+16,8));

	if ($id_device=='426C7565426F7820') $id_device=1; 

	$rr = sprintf("%d",$rr);	//formatting section
       $sti = sprintf("%d",$sti);
	$qrs = sprintf("%d",$qrs);

       $term1 = (-1.4464) * (0.001) * $rr;
       $term2 = 3.7118 * (0.01) * $sti;
       $CO = $term1 + $term2;

       if (($CO < 0) || ($CO > 30))
                {
                        $CO = 0.0;
                        $RR = 0.0;
                        $STI = 0.0;
                }

       $coutput = sprintf("%1.2f",$CO);
       
                
//#define FILE_OFFSET_IDENT								(0)
//#define FILE_OFFSET_DATE								(2*8  + FILE_OFFSET_IDENT)	//16
//#define FILE_OFFSET_PATIENT								(2*8  + FILE_OFFSET_DATE)	//32
//#define FILE_OFFSET_APPEND								2 + (2*8  + FILE_OFFSET_PATIENT)	//50 (48+carriage return)
//#define FILE_OFFSET_QRS_LENGTH							(2*1  + FILE_OFFSET_APPEND)	//52
//#define FILE_OFFSET_RR_INTERVAL_ECG						(2*4  + FILE_OFFSET_QRS_LENGTH)	//60	
//#define FILE_OFFSET_RR_INTERVAL_PLETH_LEFT				(2*4  + FILE_OFFSET_RR_INTERVAL_ECG)	//68 rrEcg
//#define FILE_OFFSET_HR_ECG								(2*4  + FILE_OFFSET_RR_INTERVAL_PLETH_LEFT)	//76	
//#define FILE_OFFSET_HR_PLETH_LEFT						(2*2  + FILE_OFFSET_HR_ECG)	//80
//#define FILE_OFFSET_STI_FOOT							(2*2  + FILE_OFFSET_HR_PLETH_LEFT)	//84 stiFoot
//#define FILE_OFFSET_STI_PEAK							(2*4  + FILE_OFFSET_STI_FOOT)	//92
//#define FILE_OFFSET_RESPONSE							(2*4  + FILE_OFFSET_STI_PEAK)	//100
//#define FILE_OFFSET_TIMESTAMP							(2*1  + FILE_OFFSET_RESPONSE)	//102
//#define FILE_OFFSET_IMPEDANCE_BANDS						(2*29 + FILE_OFFSET_TIMESTAMP)	//160
//#define FILE_OFFSET_ECG_SAMPLES							(2*2  + FILE_OFFSET_IMPEDANCE_BANDS)	//164
//#define FILE_OFFSET_ECG_SAMPLE_RATE						(2*2  + FILE_OFFSET_ECG_SAMPLES)	//168
//#define FILE_OFFSET_PLETH_LEFT_SAMPLES					(2*4  + FILE_OFFSET_ECG_SAMPLE_RATE)	//176
//#define FILE_OFFSET_PLETH_LEFT_SAMPLE_RATE				(2*2  + FILE_OFFSET_PLETH_LEFT_SAMPLES)	//180
//#define FILE_OFFSET_PLETH_RIGHT_SAMPLES					(2*4  + FILE_OFFSET_PLETH_LEFT_SAMPLE_RATE)	//188
//#define FILE_OFFSET_PLETH_RIGHT_SAMPLE_RATE				(2*2  + FILE_OFFSET_PLETH_RIGHT_SAMPLES)	//192

//#define FILE_OFFSET_DATA								2 + (2*4  + FILE_OFFSET_PLETH_RIGHT_SAMPLE_RATE)	//202
//#define FILE_OFFSET_IMPEDANCE_DATA						(2*40000 + FILE_OFFSET_DATA)	//80202



//sscanf($string,"%d %d %d %d %d %d %d %d %d %d %d %s %s %s %d %d/n",$id_patient,$id_device,$qrs,$rr,$sti,$pwv,$weight,$ecg_samples, //$ecg_rate,$pleth_samples,$pleth_rate,$data,$day_ts,$response,$impedance,$coutput);

//echo $id_patient." ".$id_device." ".$qrs." ".$rr." ".$sti." ".$pwv." ".$weight." ".$ecg_samples." ". $ecg_rate." ".$pleth_samples." ".$pleth_rate." ".$data." ".$day_ts." ".$response." ".$impedance." ".$coutput;

$con = mysql_connect("localhost","luca","bluescale");
if (!$con)
{
  die('Could not connect: ' . mysql_error());
$testfile = fopen('log.txt', 'a') or die ("A new file cannot be created");
        	$message=date("Y-m-d G:i:s")." Cannot connect to database";
		$message.="\n";
        	fwrite($testfile, $message);
	        fclose($testfile);

}
mysql_select_db("pecanpark", $con);


$sql="INSERT INTO measure VALUES ('0', '$id_patient', '$id_device', '$qrs', '$rr', '$sti', '$pwv', '$weight', '$ecg_samples', '$ecg_rate', '$pleth_samples', '$pleth_rate', '$data' ,'$day_ts' , '$response', '$impedance', '$coutput', now())";

if (!mysql_query($sql,$con))
{
  die('Error: ' . mysql_error());
$testfile = fopen('log.txt', 'a') or die ("A new file cannot be created");
        	$message=date("Y-m-d G:i:s")." Database update failed";
		$message.="\n";
        	fwrite($testfile, $message);
	        fclose($testfile);

}
mysql_close($con);

$testfile = fopen('log.txt', 'a') or die ("A new file cannot be created");
        	$message=date("Y-m-d G:i:s")." Database update complete";
		$message.="\n";
        	fwrite($testfile, $message);	       
fclose($testfile);
?>
