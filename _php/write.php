<?php
gen_filename();
# randomize a name for it

function gen_filename() {
	$filename='/splits/' . rand(1,1000000) . '.splits';
	if (file_exists($filename)) { # it exists
		gen_filename();
	} else {
		main_thing();
	}
}

function main_thing() {
# this is the main thing
$title=$_POST['runtitle'];
echo 'Run title: '.$title.'<br>';

$attempts=$_POST['attempts'];
echo 'Attempts: '.$attempts.'<br>';
}



?>