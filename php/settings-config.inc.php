<?php

$dbhost = 'localhost'; // database host
$dbuser = '?'; // database user
$dbpass = '?'; // database password
$dbname = '?'; // database name
$avpos_table='avpos';

$email_to="you@yourmail.com"; // your email (for error reporting)
$email_from="you@yourhost.com"; // your server's sending email (for error reporting)

$allow_install = false; // enable to allow action=install (clear/format database)

// Enable to check if the sim IP submitting the data is in the allowed range.
// WARNING: After the migration of SL to cloud servers, ensure this setting
//          is set to FALSE, otherwise validation will always fail even for
//          good addresses. If other means of verification are provided, this
//          script will be updated accordingly.
$check_ip = false;
