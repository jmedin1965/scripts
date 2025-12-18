#!/usr/local/bin/php-cgi -f
<?php
/*
 * backup.php
 *
 * part of pfSense (https://www.pfsense.org)
 * Copyright (c) 2015-2023 Rubicon Communications, LLC (Netgate)
 * Copyright (c) 2008 Mark J Crane
 * All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#require_once "pfsense-utils.inc";
#require_once "functions.inc";
#require_once "filter.inc";
require_once "shaper.inc";
if (file_exists("/usr/local/pkg/backup.inc")) {
    require_once("/usr/local/pkg/backup.inc");
}

global $config, $backup_dir, $backup_filename, $backup_path;

if (!is_array($config['installedpackages']['backup'])) {
	$config['installedpackages']['backup'] = array();
}
if (!is_array($config['installedpackages']['backup']['config'])) {
	$config['installedpackages']['backup']['config'] = array();
}

$a_backup = &$config['installedpackages']['backup']['config'];
$backup_dir = "/root/backup";
$backup_filename = "pfsense.bak.tgz";
$backup_path = "{$backup_dir}/{$backup_filename}";

$has_backup = false; # assume no
$out = null;
$rc = 1;             # assume fail
if (count($a_backup) > 0) {
	/* Do NOT remove the trailing space after / from $backup_cmd below!!! */
	$backup_cmd = "/usr/bin/tar --exclude {$backup_path} --create --verbose --gzip --file {$backup_path} --directory / ";
	foreach ($a_backup as $ent) {
		if ($ent['enabled'] == "true") {
			$backup_cmd .= escapeshellarg($ent['path']) . ' ';
			$has_backup = true;
		}
	}
	$backup_cmd .= " 2>&1 ";

	if( $has_backup ) {
		exec($backup_cmd, $out, $rc);
	}
	$has_backup = ($has_backup && ($rc === 0));
	if( $has_backup ) {
		print "$backup_path\n";
	}
}
?>
