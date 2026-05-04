<?php
// Code PHP 8.0 avec problèmes de migration
// Utilisation de required parameters après optional (erreur en 8.0)
function myFunction($optional = null, $required) {
    // code
}

// Utilisation de curly brace array access (déprécié)
$array = [1, 2, 3];
echo $array{0};

// Fonctions get_magic_quotes_gpc (supprimées)
if (get_magic_quotes_gpc()) {
    // code
}

// Utilisation de create_function (déprécié)
$func = create_function('$a', 'return $a + 1;');
echo $func(5);

// Required parameters après optional dans méthodes
class MyClass {
    public function method($opt = null, $req) {}
}
?>