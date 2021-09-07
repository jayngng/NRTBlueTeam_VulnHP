<?php
session_start();
?>
<html>
    <head>
	<link href="https://fonts.googleapis.com/css?family=IBM+Plex+Sans" rel="stylesheet"> 
	<link rel="stylesheet" type="text/css" href="style.css">
    </head>
    <body>
	<div class="menu">
	    <a href="index.php">Main Page</a>
	    <a href="index.php?view=about-us.html">About Us</a>
	</div>
<?php

if(!isset($_GET['view']) || ($_GET['view']=="index.php")) {
   echo"<p><b>NRT Blue Team</b><br><br>Currently, the website is under development. Please comeback later!.</br></p>";
}
else {
	echo "<p>";
	include("/var/www/html/development/" .$_GET['view']);
	echo "</p>";
}
?>
    </body>
</html>
