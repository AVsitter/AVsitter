<?php

/*
MIT License

Copyright (c) 2017

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
 */

header("Content-Type: text/plain; charset=utf-8");

error_reporting(E_ERROR | E_WARNING | E_PARSE);
ini_set('display_errors', '1');

$dbhost = 'localhost'; // database host
$dbuser = '?'; // database user
$dbpass = '?'; // database password
$dbname = '?'; // database name
$avpos_table='avpos';

$email_to="you@yourmail.com"; // your email (for error reporting)
$email_from="you@yourhost.com"; // your server's sending email (for error reporting)

$allow_install = false; // enable to allow action=install (clear/format database)

$check_ip = false; // enable to check the sim ip submitting the data is in the allowed range 

$link = mysqli_connect($dbhost, $dbuser, $dbpass, $dbname) or die("Error " . mysqli_error($link));

if (mysqli_connect_errno()) {
	die ("Connect failed: " . mysqli_connect_error());
}

if($_REQUEST['action']=="install" && $allow_install==true){
	$sql = "DROP TABLE IF EXISTS $avpos_table;";
	$result = mysqli_query($link,$sql) or die("Error creating table: ".mysqli_error($link));
	$sql = "CREATE TABLE IF NOT EXISTS $avpos_table (
	`id` int(11) NOT NULL auto_increment,
	`webkey` varchar(36) default NULL,
	`owner_uuid` varchar(36) default NULL,
	`owner_name` varchar(63) default NULL,
	`text` TEXT default NULL,
	`keep` tinyint(1) default 0,
	`count` int(5) default NULL,
	`ip` varbinary(16) defult NULL,
	`timestamp` timestamp NOT NULL default CURRENT_TIMESTAMP on update CURRENT_TIMESTAMP,
	PRIMARY KEY  (`id`),
	UNIQUE (`webkey`)
	) ENGINE=MyISAM  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1;";
	$result = mysqli_query($link,$sql) or die("Error formatting table: ".mysqli_error($link));
	if($result) {
		echo "Your tables have been formatted!";
	}
	else{
		echo "Oops! There were some problems. You should check your config and try again: ".mysqli_error($link);
	}
}
else if(isset($_REQUEST['w'])){ // write to a record
	$given_webkey = mysqli_real_escape_string($link, $_REQUEST['w']);
	
	$ip_address = $_SERVER['REMOTE_ADDR'];
	$ip_packed = inet_pton($ip_address);
	
	if(!isValidGuid($given_webkey)){
		echo "INVALID WEBKEY";
	}
	else{
		$headers = parse_llHTTPRequest_headers();
		$owner_key = mysqli_real_escape_string($link, $headers['X-SecondLife-Owner-Key']);
		$object_name = mysqli_real_escape_string($link, $headers['X-SecondLife-Object-Name']);
		$owner_name = mysqli_real_escape_string($link, $headers['X-SecondLife-Owner-Name']);
		$object_key = mysqli_real_escape_string($link, $headers['X-SecondLife-Object-Key']);
		$region = mysqli_real_escape_string($link, trim(substr($headers['X-SecondLife-Region'],0,strrpos($headers['X-SecondLife-Region'],'('))));
		$position_array = explode(', ',substr($_SERVER['HTTP_X_SECONDLIFE_LOCAL_POSITION'],1,-1));
		$slurl = $region . "/" . round($position_array[0]) . "/" . round($position_array[1]) . "/" . round($position_array[2]);
		
		if(!isValidGuid($owner_key)){
			echo "INVALID USER";
		}
		else{
			$given_count = intval($_REQUEST['c']);
			$given_text = mysqli_real_escape_string($link, $_REQUEST['t']);

			$sql = "SELECT * FROM $avpos_table WHERE webkey = '$given_webkey'";
			
			$result = mysqli_query($link,$sql) or email_death("ERR01: " . mysqli_error($link));
			if(mysqli_num_rows($result) == 0){ // a new webkey
				if($given_count == 1){
					if(!isAllowedIP($ip_address)){
						$response = "BAD IP";
						$sql = "INSERT INTO $avpos_table (owner_uuid,owner_name,webkey,text,count,ip,timestamp)
						VALUES ('$owner_key','$owner_name','$given_webkey','The IP address of the sim ($ip_address) was not in the allowed range. Please report the problem if you think this is in error.','10001','$ip_packed',NOW())";
					}
					else{
						$response = "ADDED NEW";
						if(endsWith($_REQUEST['t'],"\n\nend")){
							$given_count+=10000;
							$response = "FINISHING";
						}
						$sql = "INSERT INTO $avpos_table (owner_uuid,owner_name,webkey,text,count,ip,timestamp)
						VALUES ('$owner_key','$owner_name','$given_webkey','$given_text','$given_count','$ip_packed',NOW())";
					}
					$result = mysqli_query($link,$sql) or email_death("ERR02: " . mysqli_error($link));					
				}
				else{
					$response = "WRONG COUNT";						
				}
			}
			else{ // an existing webkey
				if(!isAllowedIP($ip_address)){
					$response = "BAD IP";
				}
				else{
					$row = mysqli_fetch_assoc($result);
					$newtext = mysqli_real_escape_string($link,$row['text']) . $given_text;
					if($row['count']+1 == $given_count){
						$response = "ADDING";
	
						if(endsWith($_REQUEST['t'],"\n\nend")){
							$given_count+=10000;
							$response = "FINISHING";
						}
						
						$sql = "UPDATE $avpos_table SET
						text = '$newtext',
						count = '$given_count',
						timestamp = NOW()
						WHERE webkey = '$given_webkey'";
						$result = mysqli_query($link,$sql) or email_death("ERR03: " . mysqli_error($link));
						
					}
					else{
						$response = "WRONG COUNT";
					}
				}
			}
			echo $response;
		}		
	}
}
else if(isset($_REQUEST['q'])){ // read a record
	
	$given_webkey = mysqli_real_escape_string($link, $_REQUEST['q']);
	$sql = "SELECT * FROM $avpos_table WHERE webkey = '$given_webkey'";
	
	$result = mysqli_query($link,$sql) or email_death("ERR04: " . mysqli_error($link));
	if(mysqli_num_rows($result) == 0){
		$out= "Not found. Expired links are deleted.";
	}
	else{
		$row = mysqli_fetch_assoc($result);
		if($row['count']>10000){
			$out.= $row['text'];
			
			if(1==2){ // switch on to 'keep' any record that ever was accessed
				$sql = "UPDATE $avpos_table SET
				keep = '1'
				WHERE webkey = '$given_webkey'";
				$result = mysqli_query($link,$sql) or email_death("ERR05: " . mysqli_error($link));
			}

			// delete all entries older than 10 minutes that are not flagged keep
			$sql = "DELETE FROM $avpos_table WHERE timestamp < DATE_SUB(NOW(), INTERVAL 10 MINUTE) AND keep = '0'";
			$result = mysqli_query($link,$sql) or email_death("ERR06: " . mysqli_error($link));
			
		}
		else{
			$out.="Data was incomplete, please try again.\n\nThis feature is new and experimental - you're welcome to report any issues.";
		}
	}
	echo $out;	
}

function parse_llHTTPRequest_headers(){
	$position_array = explode(', ',substr($_SERVER['HTTP_X_SECONDLIFE_LOCAL_POSITION'],1,-1));
	$rotation_array = explode(', ',substr($_SERVER['HTTP_X_SECONDLIFE_LOCAL_ROTATION'],1,-1));
	$velocity_array = explode(', ',substr($_SERVER['HTTP_X_SECONDLIFE_LOCAL_VELOCITY'],1,-1));
	list($global_x,$global_y) = explode(',',trim(substr($_SERVER['HTTP_X_SECONDLIFE_REGION'],$position_of_left_bracket + 1,-1)));
	$region_array = array($region_name,(integer)$global_x,(integer)$global_y);
	$headers = array('Accept'=>$_SERVER['HTTP_ACCEPT'],
			'User-Agent'=>$_SERVER['HTTP_USER_AGENT'],
			'X-SecondLife-Shard'=>$_SERVER['HTTP_X_SECONDLIFE_SHARD'],
			'X-SecondLife-Object-Name'=>$_SERVER['HTTP_X_SECONDLIFE_OBJECT_NAME'],
			'X-SecondLife-Object-Key'=>$_SERVER['HTTP_X_SECONDLIFE_OBJECT_KEY'],
			'X-SecondLife-Region'=>$_SERVER['HTTP_X_SECONDLIFE_REGION'],
			'X-SecondLife-Region-Array'=> $region_array,
			'X-SecondLife-Local-Position'=>array(	'x'=>(float)$position_array[0],'y'=>(float)$position_array[1],'z'=>(float)$position_array[2]),
			'X-SecondLife-Local-Rotation'=>array(	'x'=>(float)$rotation_array[0],'y'=>(float)$rotation_array[1],'z'=>(float)$rotation_array[2],'w'=>(float)$rotation_array[3]),
			'X-SecondLife-Local-Velocity'=>array(	'x'=>(float)$velocity_array[0],'y'=>(float)$velocity_array[1],'z'=>(float)$velocity_array[2]),
			'X-SecondLife-Owner-Name'=>$_SERVER['HTTP_X_SECONDLIFE_OWNER_NAME'],
			'X-SecondLife-Owner-Key'=>$_SERVER['HTTP_X_SECONDLIFE_OWNER_KEY']
	);
	if(!strstr($headers['X-SecondLife-Owner-Name'],' ') && $_POST['X-SecondLife-Owner-Name']){
		$headers['X-SecondLife-Owner-Name'] == $_POST['X-SecondLife-Owner-Name'];
	}
	if(is_array($headers)){
		return $headers;
	}
	else{
		return FALSE;
	}
}

function isValidGuid($guid){
	return !empty($guid) && preg_match('/^\{?[a-zA-Z0-9]{8}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{4}-[a-zA-Z0-9]{12}\}?$/', $guid);
}

function email_death($error){
	$body.="\n";
	$body.="\n\$_SERVER\n";
	foreach($_SERVER as $key_name => $key_value) {
		$body.= $key_name . " = " . $key_value . "\n";
	}
	$body.="\n\$_GET\n";
	foreach($_GET as $key_name => $key_value) {
		$body.= $key_name . " = " . $key_value . "\n";
	}
	$body.="\n\$_POST\n";
	foreach($_POST as $key_name => $key_value) {
		$body.= $key_name . " = " . $key_value . "\n";
	}
	$to = $GLOBALS['email_to'];
	$subject = "avsitter: $error";
	$email_headers = "From: ". $GLOBALS['email_from'] ."\r\n" . "X-Mailer: php";
	mail($to, $subject, $body, $email_headers);
	die($error);
}

function startsWith($haystack, $needle) {
	// search backwards starting from haystack length characters from the end
	return $needle === "" || strrpos($haystack, $needle, -strlen($haystack)) !== FALSE;
}

function endsWith($haystack, $needle) {
	// search forward starting from end minus needle length characters
	return $needle === "" || (($temp = strlen($haystack) - strlen($needle)) >= 0 && strpos($haystack, $needle, $temp) !== FALSE);
}

function isAllowedIP($ip){
	if($GLOBALS['check_ip']==false){
		return true;
	}
	$llsubnets = array(
		"8.2.32.0/22",
		"8.4.128.0/22",
		"8.10.144.0/21",
		"63.210.156.0/22",
		"64.154.220.0/22",
		"216.82.0.0/18"
	);
	foreach($llsubnets as $range){
		if(ip_in_range($ip,$range)) return true;
	}
	return false;
}

// check if an ip_address in a particular range
function ip_in_range( $ip, $range ) {
	// $range is in IP/CIDR format eg 127.0.0.1/24
	list( $range, $netmask ) = explode( '/', $range, 2 );
	$range_decimal = ip2long( $range );
	$ip_decimal = ip2long( $ip );
	$wildcard_decimal = pow( 2, ( 32 - $netmask ) ) - 1;
	$netmask_decimal = ~ $wildcard_decimal;
	return ( ( $ip_decimal & $netmask_decimal ) == ( $range_decimal & $netmask_decimal ) );
}

?>