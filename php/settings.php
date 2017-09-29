<?php

/*
MIT License

Copyright (c) the AVsitter Contributors (http://avsitter.github.io)

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

require_once("settings-config.inc.php");

$link = mysqli_connect($dbhost, $dbuser, $dbpass, $dbname) or die("Error " . mysqli_error($link));

if (mysqli_connect_errno()) {
    die ("Connect failed: " . mysqli_connect_error());
}
// Set the character set for communication with the database
if (!mysqli_set_charset($link, 'utf8mb4')) {
    die('Invalid charset: utf8mb4');
}

// Pre-escape $avpos_table for convenience. That's the only variable
// that should go directly into a query. All others should go through
// IntSQL or StrSQL as appropriate.
$avpos_table = IdentSQL($avpos_table);

undo_magic_quotes($_REQUEST);

if($_REQUEST['action']=="install" && $allow_install==true){
    $sql = "DROP TABLE IF EXISTS $avpos_table;";
    $result = mysqli_query($link,$sql) or die("Error creating table: ".mysqli_error($link));
    $sql = "CREATE TABLE IF NOT EXISTS $avpos_table (
    `id` int(11) NOT NULL auto_increment,
    `webkey` varchar(36) default NULL,
    `owner_uuid` varchar(36) default NULL,
    `owner_name` varchar(63) default NULL,
    `text` TEXT CHARSET utf8mb4 default NULL,
    `keep` tinyint(1) default 0,
    `count` int(5) default NULL,
    `ip` varbinary(16) default NULL,
    `timestamp` datetime NOT NULL,
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
    $given_webkey = $_REQUEST['w'];

    $ip_address = $_SERVER['REMOTE_ADDR'];
    $ip_packed = inet_pton($ip_address);

    if(!isValidGuid($given_webkey)){
        echo "INVALID WEBKEY";
    }
    else{
        $owner_key = $_SERVER['HTTP_X_SECONDLIFE_OWNER_KEY'];
        //$object_name = $_SERVER['HTTP_X_SECONDLIFE_OBJECT_NAME'];
        $owner_name = $_SERVER['HTTP_X_SECONDLIFE_OWNER_NAME'];
        //$object_key = $_SERVER['HTTP_X_SECONDLIFE_OBJECT_KEY'];
        //$region = trim(substr($_SERVER['HTTP_X_SECONDLIFE_REGION'],0,strrpos($_SERVER['HTTP_X_SECONDLIFE_REGION'],'(')));
        //$position_array = explode(', ',substr($_SERVER['HTTP_X_SECONDLIFE_LOCAL_POSITION'],1,-1));
        //$slurl = rawurlencode($region) . "/" . round($position_array[0]) . "/" . round($position_array[1]) . "/" . round($position_array[2]);

        if(!isValidGuid($owner_key)){
            echo "INVALID USER";
        }
        else{
            $given_count = intval($_REQUEST['c']);
            $given_text = $_REQUEST['t'];

            $sql = "SELECT * FROM $avpos_table"
                . ' WHERE webkey = ' . StrSQL($given_webkey);

            $result = mysqli_query($link,$sql) or email_death("ERR01: " . mysqli_error($link));
            if(mysqli_num_rows($result) == 0){ // a new webkey
                if($given_count == 1){
                    if(!isAllowedIP($ip_address)){
                        $response = "BAD IP";
                        $sql = "INSERT INTO $avpos_table"
                            . ' (owner_uuid,owner_name,webkey,text,count,ip,timestamp)'
                            . ' VALUES '
                            . '(' . StrSQL($owner_key)
                            . ',' . StrSQL($owner_name)
                            . ',' . StrSQL($given_webkey)
                            . ',' . StrSQL("The IP address of the sim ($ip_address) was not in the allowed range. Please report the problem if you think this is in error")
                            . ',10001'
                            . ',' . StrSQL($ip_packed)
                            . ',NOW()'
                            . ')';
                    }
                    else{
                        $response = "ADDED NEW";
                        if(endsWith($_REQUEST['t'],"\n\nend")){
                            $given_count+=10000;
                            $response = "FINISHING";
                        }
                        $sql = "INSERT INTO $avpos_table"
                            . ' (owner_uuid,owner_name,webkey,text,count,ip,timestamp)'
                            . ' VALUES '
                            . '(' . StrSQL($owner_key)
                            . ',' . StrSQL($owner_name)
                            . ',' . StrSQL($given_webkey)
                            . ',' . StrSQL($given_text)
                            . ',' . IntSQL($given_count)
                            . ',' . StrSQL($ip_packed)
                            . ',NOW()'
                            . ')';
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
                    $newtext = $row['text'] . $given_text;
                    if (strlen($newtext) > 65535) {
                        $sql = "UPDATE $avpos_table"
                        . ' SET text = ' . StrSQL("64K limit exceeded.\n"
                                                . "The text that was generated can't"
                                                . " be saved as a notecard because it's"
                                                . " too long.")
                        .    ', count = ' . IntSQL(10000+$given_count)
                        .    ', timestamp = NOW()'
                        . ' WHERE webkey = ' . StrSQL($given_webkey);
                        mysqli_query($link,$sql) or email_death("ERR03: " . mysqli_error($link));
                        $response = "NOTECARD TOO LONG";
                    }
                    else if (startsWith($newtext, '64K limit exceeded')) {
                        $response = "NOTECARD TOO LONG";
                    }
                    else if($row['count']+1 == $given_count){
                        $response = "ADDING";

                        if(endsWith($_REQUEST['t'],"\n\nend")){
                            $given_count+=10000;
                            $response = "FINISHING";
                        }

                        $sql = "UPDATE $avpos_table"
                        . ' SET text = ' . StrSQL($newtext)
                        .    ', count = ' . IntSQL($given_count)
                        .    ', timestamp = NOW()'
                        . ' WHERE webkey = ' . StrSQL($given_webkey);
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

    $out = "";

    $given_webkey = $_REQUEST['q'];
    $sql = "SELECT * FROM $avpos_table"
        . ' WHERE webkey = ' . StrSQL($given_webkey);

    $result = mysqli_query($link,$sql) or email_death("ERR04: " . mysqli_error($link));
    if(mysqli_num_rows($result) == 0){
        $out= "Not found. Expired links are deleted.";
    }
    else{
        $row = mysqli_fetch_assoc($result);
        if($row['count']>10000){
            $out.= $row['text'];

            if(1==2){ // switch on to 'keep' any record that ever was accessed
                $sql = "UPDATE $avpos_table"
                    . ' SET keep = 1'
                    . ' WHERE webkey = ' . StrSQL($given_webkey);
                $result = mysqli_query($link,$sql) or email_death("ERR05: " . mysqli_error($link));
            }

            // delete all entries older than 10 minutes that are not flagged keep
            $sql = "DELETE FROM $avpos_table"
                . ' WHERE timestamp < DATE_SUB(NOW(), INTERVAL 10 MINUTE)'
                .   ' AND keep = 0';
            $result = mysqli_query($link,$sql) or email_death("ERR06: " . mysqli_error($link));

        }
        else{
            $out.="Data was incomplete, please try again.\n\nThis feature is new and experimental - you're welcome to report any issues.";
        }
    }
    echo $out;
}
else{
    header('HTTP/1.0 400 Bad Request');
    die("400 Bad Request: No valid action specified.");
}

function undo_magic_quotes(&$var)
{
    // Does anyone still use these? Probably not but just in case.
    if (function_exists('get_magic_quotes_gpc') && get_magic_quotes_gpc())
    {
        // This doesn't remove the slashes in the keys, but that doesn't matter for us.
        foreach ($var as $k => &$v)
        {
            if (is_array($v))
                undo_magic_quotes($v);
            else
                $v = stripslashes($v);
        }
    }
}

function IdentSQL($str){
    return '`' . str_replace('`', '``', $str) . '`';
}

function StrSQL($str){
    if ($str === null)
        return "NULL";
    return "'" . mysqli_real_escape_string($GLOBALS['link'], strval($str)) . "'";
}

function IntSQL($int){
    return strval(intval($int));
}

function isValidGuid($guid){
    return !empty($guid) && preg_match('/^\{?[a-zA-Z0-9]{8}(?:-[a-zA-Z0-9]{4}){4}[a-zA-Z0-9]{8}\}?$/', $guid);
}

function email_death($error){
    $body="\n";
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
