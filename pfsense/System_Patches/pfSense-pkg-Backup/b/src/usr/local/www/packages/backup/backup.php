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
require_once("shaper.inc");
#require_once("notices.inc");
require_once("/usr/local/pkg/backup.inc");

$has_command_line = false;
if (isset($argv)) {
	$has_command_line = true;
}
else {
	require_once("guiconfig.inc");
}

global $config, $backup_dir, $backup_filename, $backup_path;


function send_error( $str )
{
	global $argv_0;

	file_notice(3, "error: $argv_0: $str");
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

		if ( $has_command_line ) {
			print "exclude: $backup_dir\n";
		}
		foreach ($a_backup as $ent) {
			if ($ent['enabled'] == "true") {
				/* make all paths start with / */
				if( $ent['path'][0] != '/' ) {
					$ent['path'] = '/' . $ent['path'];
				}
				$backup_cmd .= escapeshellarg($ent['path']) . ' ';
				$backup_status['last_backup']['Backup Locations'][] = $ent['path'];
				if ( $has_command_line ) {
					print "include: " . $ent['path'] . "\n";
					if( $ent['path'][0] != '/' ) {
						print "first: = no\n";
					}
				}
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
				send_error( $err );
			}
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
	global $info_box_a;

	$count = 0;

	global $_GET;
	info_box_add( "_GET", "info" );
	foreach( $_GET as $key => $value ) {
		info_box_append( "_GET[$key] = $value" );
	}
	global $_POST;
	info_box_add( "_POST", "info" );
	foreach( $_POST as $key => $value ) {
		info_box_append( "_GET[$key] = $value" );
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

if (!is_array($config['installedpackages']['backup'])) {
	$config['installedpackages']['backup'] = array();
}

if (!is_array($config['installedpackages']['backup']['config'])) {
	$config['installedpackages']['backup']['config'] = array();
}

$a_backup = &$config['installedpackages']['backup']['config'];
$backup_dir = "/root/backup";
$backup_filename = "pfsense.bak.tgz";
$backup_status_path = "{$backup_dir}/backup.status.inc";
$backup_path = "{$backup_dir}/{$backup_filename}";
$argv_0 = __FILE__;
$backup_status = include $backup_status_path;
$info_box_a = [];

if ( $has_command_line ) {

	/*$argv_0 = $argv[0];*/
	array_shift($argv);

	if ( $argc > 1) {
		foreach ($argv as $value) {
			do_backup( $backup_dir . "/" . $value  );
		}	
	}
	else {
		do_backup ( $backup_path );
	}
}

if ($_GET['act'] == "del") {
	if ($_GET['type'] == 'backup') {
		if ($a_backup[$_GET['id']]) {
			unset($a_backup[$_GET['id']]);
			write_config("Backup: Item deleted");
			header("Location: backup.php");
			exit;
		}
	}
}

if ($_GET['a'] == "download") {
	if ($_GET['t'] == "backup") {
		/* assume no... */
		$has_backup = do_backup( $backup_path );

		/* bailout if there is nothing to download */
		/* 
			(
			  if we don't have a backup 
			  and
			  (
			    if the file doesn't exist
			    or
			    its a directory
			  )
			)
			or
			we were not able to open the file
		*/
		if (	!$has_backup &&
			( !file_exists($backup_path) || is_dir($backup_path) )
			|| !($fd = fopen($backup_path, 'rb'))
		   ) {
			#header('Location: backup.php?savemsg=Error+failed+to+create+backup.');
			#info_box_add( "{$backup_path}: Failed to create backup.", 'danger' );
		}
		else {
			#header('Location: backup.php?savemsg=Backup+created+successfully.');
			#info_box_add( "{$backup_path}: Backup created successfully.", 'success' );
		}
	}
}


if ($_GET['a'] == "download") {
	if ($_GET['t'] == "download") {
		/* assume no... */
		$has_backup = do_backup( $backup_path );

		session_cache_limiter('public');

		/* bailout if there is nothing to download */
		/* 
			(
			  if we don't have a backup 
			  and
			  (
			    if the file doesn't exist
			    or
			    its a directory
			  )
			)
			or
			we were not able to open the file
		*/
		if (	!$has_backup &&
			( !file_exists($backup_path) || is_dir($backup_path) )
			|| !($fd = fopen($backup_path, 'rb'))
		   ) {
			send_error( "No backup file exists" );
			header('Location: backup.php');
			exit(0);
		}

		header("Content-Type: application/force-download");
		header("Content-Type: binary/octet-stream");
		header("Content-Type: application/download");
		header("Content-Description: File Transfer");
		header('Content-Disposition: attachment; filename="' . $backup_filename . '"');
		header("Cache-Control: no-cache, must-revalidate");
		header("Expires: Sat, 26 Jul 1997 05:00:00 GMT");
		header("Content-Length: " . filesize($backup_path));

		/* read the file and emit to browser */
		fpassthru($fd);

		fclose($fd);
		header('Location: backup.php');
		exit(0);
	}
}

if ($_GET['a'] == "other") {
	if ($_GET['t'] == "restore") {
		// Extract the tgz file
		if (file_exists($backup_path) && !is_dir($backup_path)) {
			system("/usr/bin/tar -xpzC / -f {$backup_path}");
			header("Location: backup.php?savemsg=Backup+has+been+restored.");
		} else {
			header("Location: backup.php?savemsg=Restore+failed.+Backup+file+not+found.");
		}
		exit;
	}
}

if ($_GET['a'] === 'other') {
	if ($_GET['t'] === 'delete') {
		unlink_if_exists($backup_path);
		header('Location: backup.php');
	}
}

if (($_POST['submit'] == "Upload") && is_uploaded_file($_FILES['ulfile']['tmp_name'])) {
	move_uploaded_file($_FILES['ulfile']['tmp_name'], "{$backup_path}");
	$savemsg = "Uploaded file to {$backup_dir}" . htmlentities($_FILES['ulfile']['name']);
	system("/usr/bin/tar -xpzC / -f {$backup_path}");
}

$pgtitle = array(gettext("Diagnostics"), gettext("Backup Files and Directories"), gettext("Settings"));
if ( $has_command_line ) {
	exit(0);
}

include("head.inc");
info_box_print();
if ($_GET["savemsg"]) {
	print_info_box($_GET["savemsg"]);
}

#print_info_box("a warning message", 'warning');
#print_info_box("a sucess message", 'success');
#print_info_box("a danger message", 'danger');
#info_box_add( $msg, $type = "" );
#info_box_append( $msg, $index = -1 );

//print_info_box("$m");
//$m = "";
//if ($_GET['a'] == "download") {
//	$m .= "downloadrrr ";
//}
//$m .= "_GET[a] = {$_GET['a']}, _GET[t] = {$_GET['t']}, _POST[submit] = {$_POST['submit']}, _GET[act] = {$_GET['act']}";


/*
print_info_box("a nothing message");		// its a warning
print_info_box("a default message", 'default');	// black on while
print_info_box("a info message", 'info');	// blue
print_info_box("a warning message", 'warning');	// yelow
print_info_box("a sucess message", 'success');	// green
print_info_box("a danger message", 'danger');	// red
print_info_box("a danger message, chaged button", 'danger', "cross", "cross text");
*/

$is_dirty = true;
if ($_POST['apply']) {
	// 0 is success
	// non-zero means there was some problem
	$retval = 0;
}
if ($_POST['apply']) {
	print_apply_result_box($retval);
	$is_dirty = false;
}
if ($is_dirty) {
        print_apply_box(gettext("The firewall rule configuration has been changed.") . "<br />" . gettext("The changes must be applied for them to take effect."));
}

$tab_array = array();
$tab_array[] = array(gettext("Settings"), true, "/packages/backup/backup.php");
$tab_array[] = array(gettext("Add"), false, "/packages/backup/backup_edit.php");
display_top_tabs($tab_array);
?>
<div class="panel panel-default">
	<div class="panel-heading"><h2 class="panel-title">Backups</h2></div>
	<div class="panel-body">
		<div class="table-responsive">
			<table class="table table-hover">
				<tr>
					<td>Use this to tool to backup files and directories. The following directories are recommended for backup:
						<table>
							<tr><td><strong>pfSense Config:</strong></td><td>/cf/conf</td></tr>
							<tr><td><strong>RRD Graph Data Files:</strong></td><td>/var/db/rrd</td></tr>
						</table>
					</td>
				</tr>
			</table>
		</div>
	</div>
	<div class="panel-heading"><h2 class="panel-title">Upload Archive</h2></div>
	<div class="panel-body">
		<div class="table-responsive">
			<form action="backup.php" method="post" enctype="multipart/form-data" name="frmUpload" onsubmit="">
				<table class="table table-hover">
				<tr>
					<td colspan="2">
						Restore a backup by selecting the backup archive and clicking <strong>Upload</strong>.
					</td>
				</tr>
				<tr>
					<td>File to upload:</td>
					<td>
						<input name="ulfile" type="file" class="btn btn-info" id="ulfile" />
						<br />
						<button name="submit" type="submit" class="btn btn-primary" id="upload" value="Upload">
							<i class="fa fa-upload icon-embed-btn"></i>
							Upload
						</button>
					</td>
				</tr>
				</table>
			</form>
		</div>
	</div>
	<div class="panel-heading"><h2 class="panel-title">Backup and Restore</h2></div>
	<div class="panel-body">
		<div class="table-responsive">
			<form action="backup.php" method="post" enctype="multipart/form-data" name="frmUpload" onsubmit="">
			<table class="table table-hover">
				<tr>
					<td>
					The 'Backup' button compresses the directories that are listed below to /root/backup/pfsense.bak.tgz; after that it presents the file for download.<br />
					If the backup file does not exist in /root/backup/pfsense.bak.tgz then the 'Restore' and 'Delete' buttons will be hidden.
					</td>
				</tr>
				<tr>
					<td>
						<button type='button' class="btn btn-primary" value='Backup' onclick="document.location.href='backup.php?a=download&amp;t=backup';">
							<i class="fa fa-plus icon-embed-btn"></i>
							Backup
						</button>
						<?php	if (file_exists($backup_path) && !is_dir($backup_path)) { ?>
								<button type='button' class="btn btn-primary" value='Download' onclick="document.location.href='backup.php?a=download&amp;t=download';">
									<i class="fa fa-download icon-embed-btn"></i>
									Download
								</button>
								<button type="button" class="btn btn-warning" value="Restore" onclick="document.location.href='backup.php?a=other&amp;t=restore';">
									<i class="fa fa-undo icon-embed-btn"></i>
									Restore
								</button>
								<button type="button" class="btn btn-danger" value="Delete" target="_new" onclick="document.location.href='backup.php?a=other&amp;t=delete';">
									<i class="fa fa-trash icon-embed-btn"></i>
									Delete
								</button>
						<?php 	} ?>
					</td>
				</tr>
			</table>
			</form>
		</div>
	</div>
	<div class="panel-heading"><h2 class="panel-title">Backup Locations</h2></div>
	<div class="panel-body">
		<div class="table-responsive">
			<form action="backup_edit.php" method="post" name="iform" id="iform">
			<table class="table table-striped table-hover table-condensed">
				<thead>
					<tr>
						<td width="20%">Name</td>
						<td width="25%">Path</td>
						<td width="5%">Enabled</td>
						<td width="40%">Description</td>
						<td width="10%">Actions</td>
					</tr>
				</thead>
				<tbody>
<?php
$i = 0;
if (count($a_backup) > 0):
	foreach ($a_backup as $ent): ?>
					<tr>
						<td><?=$ent['name']?>&nbsp;</td>
						<td><?=$ent['path']?>&nbsp;</td>
						<td><? echo ($ent['enabled'] == "true") ? "Enabled" : "Disabled";?>&nbsp;</td>
						<td><?=htmlspecialchars($ent['description'])?>&nbsp;</td>
						<td>
							<a href="backup_edit.php?id=<?=$i?>"><i class="fa fa-pencil" alt="edit"></i></a>
							<a href="backup_edit.php?type=backup&amp;act=del&amp;id=<?=$i?>"><i class="fa fa-trash" alt="delete"></i></a>
						</td>
					</tr>
<?php	$i++;
	endforeach;
endif; ?>
					<tr>
						<td colspan="5"></td>
						<td>
							<a class="btn btn-small btn-success" href="backup_edit.php"><i class="fa fa-plus" alt="add"></i> Add</a>
						</td>
					</tr>
				</tbody>

			</form>
		</div>
	</div>
</div>

<?php include("foot.inc"); ?>
