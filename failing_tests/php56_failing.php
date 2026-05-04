<?php
// Code PHP 5.6 avec problèmes de migration
// Utilisation de mysql_ functions (dépréciées depuis PHP 5.5, supprimées en 7.0)
$link = mysql_connect('localhost', 'user', 'password');
mysql_select_db('database', $link);
$result = mysql_query('SELECT * FROM table', $link);
while ($row = mysql_fetch_assoc($result)) {
    echo $row['column'];
}
mysql_close($link);

// Autres problèmes : utilisation de ereg (déprécié)
if (ereg('pattern', $string)) {
    // code
}

// Variables non initialisées (peut causer warnings)
echo $undefined_var;
?>