<html>
<head>
	<title>Create new run</title>
<form action="write.php" method="post">
Title: <input type="text" name="runtitle" value="Run Title"><br>
# of attempts: <input type="number" name="attempts" value="1"><br>
<br>
Format for time should be: HH:MM:SS.xxx (for example: 01:30:27.233)<br>

<?php
$i=0;
while($i<30) {
  echo '<input type="text" name="name' . $i . '" value="Name"> --- <input type="text" name="time' . $i . '" value="Time"><br>';
  $i++;
}
?>

<input type="submit">
</form>

