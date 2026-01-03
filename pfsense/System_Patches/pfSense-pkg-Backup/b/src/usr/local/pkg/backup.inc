<?php
/*
 * backup.inc
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

$debug = false;
$debug = true;

#
# check if has_command_line.
# if we have been called from command line instead of the CGI GUI
#
if ( isset($argv) ) {
	$has_command_line = true;
	require_once("shaper.inc");
}
else {
	$has_command_line = false;
	require_once("guiconfig.inc");
}

#
# Check for undefined $config for backup package
#
if (!is_array($config['installedpackages']['backup'])) {
	$config['installedpackages']['backup'] = array();
}
if (!is_array($config['installedpackages']['backup']['config'])) {
	$config['installedpackages']['backup']['config'] = array();
}



function backup_sync_package() {
	// this was broken code.
}

function backup_install_command() {
	// Create the backup directory
	safe_mkdir("/root/backup/");
	backup_sync_package();
}

function send_error( $str )
{
	# only send file_notice if called from command line
	if( isset($argv) ) {
		file_notice(3, "error: {__FILE__}: $str");
	}
}

function do_backup ( $file )
{
	global $a_backup, $has_command_line, $backup_dir, $backup_status, $backup_status_path;

	$backup_status['last_backup'] = array();
	$backup_status['last_backup']['start'] = date('Y-m-d H:i:s');
	if ( $has_command_line ) {
		$backup_status['last_backup']['run_from'] = "Command Line";
	}
	else {
		$backup_status['last_backup']['run_from'] = "Web GUI";
	}

	/* assume no... */
	$backup_status['last_backup']['has_backup'] = false;
	$backup_status['last_backup']['rc'] = 99;
	$backup_status['last_backup']['Backup Location Count'] = count($a_backup);
	$backup_status['last_backup']['Backup Locations'] = array();
	if (count($a_backup) > 0) {
		/* Do NOT remove the trailing space after / from $backup_cmd below!!! */
		$backup_cmd = "/usr/bin/tar --exclude {$backup_dir} --create --verbose --gzip --file {$file} --directory / ";

		foreach ($a_backup as $ent) {
			if ($ent['enabled'] == "true") {
				$backup_cmd .= escapeshellarg($ent['path']) . ' ';
				$backup_status['last_backup']['Backup Locations'][] = $ent['path'];
			}
			$backup_status['last_backup']['has_backup'] = true;
		}

		/* Only interested in stderr */
		$backup_cmd .= " 2>&1 1>/dev/null";

		exec($backup_cmd, $out, $rc);

		$backup_status['last_backup']['has_backup'] = ($backup_status['last_backup']['has_backup'] && ($rc === 0));
		$backup_status['last_backup']['rc'] = $rc;
	}

	$backup_status['last_backup']['Errors'] = array();
	if( $backup_status['last_backup']['has_backup'] ) {
		if ( $has_command_line ) {
			print "created: $file\n";
		}
		$backup_status['last_backup']['file'] = "$file";
	}
	else {
		foreach( $out as $err ) {
			if ( $has_command_line ) {
				print "error: $err\n";
			}
			send_error( $err );
			$backup_status['last_backup']['Errors'][] = $err;
		}
	}

	$backup_status['last_backup']['end'] = date('Y-m-d H:i:s');

	// write status to file
	file_put_contents("$backup_status_path",  '<?php return ' . var_export($backup_status, true) . ';' );

	// update GUI status message
	update_backup_status();

	return( $backup_status['last_backup']['has_backup'] );
}

function update_backup_status()
{
	global $backup_status;

	if ($backup_status !== false) {

		$msg .= "Last backup started on {$backup_status['last_backup']['start']}";
		if ( $backup_status['last_backup']['rc'] == 0 ) {
			info_box_add( $msg . " was successful.", 'success' );
		}
		else {
			info_box_add( $msg . " failed with error code {$backup_status['last_backup']['rc']}.", 'danger' );
		}
		
		if ( $backup_status['last_backup']['has_backup'] ) {
			info_box_append( "Backup file {$backup_status['last_backup']['file']} was created successful on {$backup_status['last_backup']['end']}." );
		}
		else {
			info_box_append( "Failed to create backup file {$backup_status['last_backup']['file']}." );
		}
		info_box_append( "The backup command was run from the {$backup_status['last_backup']['run_from']}.") ;

		foreach( $backup_status['last_backup']['Errors'] as $err ) {
			info_box_append( "Error: $err." );
		}
	}
}


function info_box_add( $msg, $type = "" )
{
	global $info_box_a;

	$info_box_a[] = array (
		'msg'  => gettext("$msg"),
		'type' => "$type"
	);
	return( count($info_box_a) - 1 );
}

function info_box_append( $msg, $index = -1, $type = -1 )
{
	global $info_box_a;

	if( $msg == "" ) {
		$msg = " ";
	}

	if ( $index == -1 ) {
		$index = count($info_box_a) - 1;
	}

	if( isset( $info_box_a[$index]['msg'] ) ) {
		$info_box_a[$index]['msg'] .= "<br />" . gettext("$msg"); 
		if( $type != -1 ) {
			$info_box_a[$index]['type'] = $type;
		}
		return( true );
	}
	else {
		return( false );
	}
}

function info_box_print()
{
	global $info_box_a, $debug;

	$count = 0;

	if( $debug ) {

		info_box_add( "debug = true", "info" );

		global $_GET;
		info_box_append( "" );
		info_box_append( "_GET:" );
		foreach( $_GET as $key => $value ) {
			info_box_append( "_GET[$key] = $value" );
		}
		global $_POST;
		info_box_append( "" );
		info_box_append( "_POST:" );
		foreach( $_POST as $key => $value ) {
			info_box_append( "_POST[$key] = $value" );
		}

		global $_REQUEST;
		info_box_append( "" );
		info_box_append( "_REQUEST:" );
		foreach( $_REQUEST as $key => $value ) {
			info_box_append( "_REQUEST[$key] = $value" );
		}
	}

	foreach( $info_box_a as $i ) {
		$count += 1;
		if( $i['type'] == "" ) {
			print_info_box($i['msg']);
		}
		else {
			print_info_box($i['msg'], $i['type']);
		}
	}
}

?>
