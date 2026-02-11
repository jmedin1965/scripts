#!/usr/local/bin/php-cgi -f
<?php

$f = "/usr/local/www/packages/backup/backup.php";
if ( file_exists($f)) {
  require_once "$f";
} else {
  print "$f: script does not exist.\n";
}
?>
