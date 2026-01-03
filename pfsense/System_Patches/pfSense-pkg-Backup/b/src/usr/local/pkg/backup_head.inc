<?php
/*
 * backup_header.inc
 *
 * a common header for all backup tab_arrays
 *
*/

$pgtitle = array(gettext("Diagnostics"), gettext("Backup Files and Directories"), gettext($thispage));

include("head.inc");

info_box_print();

if (isset($savemsg)) {
	print_info_box($savemsg, 'success');
}

if (isset($_REQUEST['savemsg'])) {
	$savemsg = htmlspecialchars($_REQUEST['savemsg']);
	print_info_box($savemsg);
}


/*
        A test to get print_apply_box working
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
if( $thispage == "Edit" ) {
        $tab_array[] = array(gettext("Edit"), false, "/packages/backup/backup_edit.php");
} else {
        $tab_array[] = array(gettext("Add"), false, "/packages/backup/backup_edit.php");
}
$tab_array[] = array(gettext("Fred"), false, "/packages/backup/backup_edit.php");

display_top_tabs($tab_array);


#print_info_box("a warning message", 'warning');
#print_info_box("a sucess message", 'success');
#print_info_box("a danger message", 'danger');
#info_box_add( $msg, $type = "" );
#info_box_append( $msg, $index = -1 )

/*
print_info_box("a nothing message");            // its a warning
print_info_box("a default message", 'default'); // black on while
print_info_box("a info message", 'info');       // blue
print_info_box("a warning message", 'warning'); // yelow
print_info_box("a sucess message", 'success');  // green
print_info_box("a danger message", 'danger');   // red
print_info_box("a danger message, chaged button", 'danger', "cross", "cross text");
*/
?>
