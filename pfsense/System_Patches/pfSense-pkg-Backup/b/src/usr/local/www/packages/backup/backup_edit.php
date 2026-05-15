<?php
/*
 * backup_edit.php
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
require_once("/usr/local/pkg/backup.inc");


$a_backup = &$config['installedpackages']['backup']['config'];


$id = $_GET['id'];
if (isset($_POST['id'])) {
	$id = $_POST['id'];
}

if ($_GET['act'] == "del") {
	if ($_GET['type'] == 'backup') {
		if ($a_backup[$_GET['id']]) {
			unset($a_backup[$_GET['id']]);
			write_config("Backup: Item deleted");
			backup_sync_package();
			$savemsg = gettext("Item deleted sucesfully.");
			header("Location: backup.php?savemsg={$savemsg}");
			exit;
		}
	}
}

if (isset($id) && $a_backup[$id]) {

	$pconfig['name'] = $a_backup[$id]['name'];
	$pconfig['path'] = $a_backup[$id]['path'];
	$pconfig['enabled'] = $a_backup[$id]['enabled'];
	$pconfig['description'] = $a_backup[$id]['description'];

}

if ($_POST) {
	/* TODO - This needs some basic input validation for the path at least */
	unset($input_errors);
	$pconfig = $_POST;
	$savemsg = "";
	$savemsgtype = "sucess";

	$ent = array();
	$ent['name'] = $_POST['name'];
	$ent['path'] = $_POST['path'];
	$ent['enabled'] = $_POST['enabled'];
	$ent['description'] = $_POST['description'];

	// check if path is blank
	if ( $ent['path'] == "" || ctype_space($ent['path']) ) {
		$savemsg .= gettext('Path can not be empty. ') . ' <br /> ';
		$input_errors = true;
	}
	// make all paths start with /
	elseif ( $ent['path'][0] != '/' ) {
		$ent['path'] = "/" . $ent['path'];
		$savemsg .= 'Added leading / to path, ';
	}

	// Check if path exists or if it's just /
	if( $ent['path'] == '/' ) {
		$savemsg .= gettext("Best not to include everything on this system.") . ' <br />';
		$savemsg .= gettext("Please specify just a folder, not /.") . ' <br /> ';
		$input_errors = true;
	}
	elseif( !$input_errors && count( glob( $ent['path'] ) ) == 0 ) {
		$savemsg .= gettext("Path does not exist.") . ' <br /> ';
		$input_errors = true;
	}

	if (!$input_errors) {
		if (isset($id) && $a_backup[$id]) {
			// update
			$a_backup[$id] = $ent;
			$savemsg .= 'Backup location updated sucessfully. ';
		} else {
			// add
			$a_backup[] = $ent;
			$savemsg .= 'Backup location added sucessfully. ';
		}

		write_config("Backup: Settings saved");
		backup_sync_package();

		$savemsg = gettext($savemsg);
		header("Location: backup.php?savemsg={$savemsg}");
		exit;
	}
	else {
		$savemsgtype = "danger";
	}
}

$thispage = gettext("Add");
if (!empty($id)) {
	$thispage = gettext("Edit");
}
include("/usr/local/pkg/backup_head.inc");

$form = new Form();
$section = new Form_Section('Backup Settings');

$section->addInput(new Form_Input(
	'name',
	'Backup Name',
	'text',
	$pconfig['name']
))->setHelp('Enter a name for the backup.');

$section->addInput(new Form_Input(
	'path',
	'Path',
	'text',
	$pconfig['path']
))->setHelp('Enter the full path to the file or directory to backup. Path will have a leading / if it does not have one. Path can include shell glob characters. See <A href=https://www.php.net/manual/en/function.glob.php target=_blank >glob - Manual, pattern</a>.');

$section->addInput(new Form_Select(
	'enabled',
	'Enabled',
	$pconfig['enabled'],
	array( "true" => "Enabled", "false" => "Disabled" )
))->setHelp('Choose whether this backup location is enabled or disabled.');

$section->addInput(new Form_Input(
	'description',
	'Description',
	'text',
	$pconfig['description']
))->setHelp('Enter a description here for reference.');

$form->add($section);

print $form;
?>
<?php include("foot.inc"); ?>
