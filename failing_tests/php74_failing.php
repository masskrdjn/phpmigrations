<?php
// Code PHP 7.4 avec problèmes de migration
// Utilisation de (real) cast (déprécié en 7.4)
$value = (real) 3.14;

// Utilisation de get_defined_functions avec exclude_disabled (paramètre supprimé)
$functions = get_defined_functions(true);

// Fonctions mb_ereg (certaines dépréciations)
mb_ereg_replace('pattern', 'replacement', $string);

// Utilisation de array_key_exists avec objets (warnings en 7.4)
class MyClass {}
$obj = new MyClass();
if (array_key_exists('property', $obj)) {
    // code
}

// Nested ternary sans parenthèses (warnings)
$result = $a ? $b : $c ? $d : $e;
?>