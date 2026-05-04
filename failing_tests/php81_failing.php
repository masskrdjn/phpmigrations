<?php
// Code PHP 8.1 avec problèmes de migration
// Utilisation de return par référence implicite (warnings)
function &myFunction() {
    static $var = 1;
    return $var;
}

// Utilisation de mysql_xdevapi (certaines dépréciations)
use mysql_xdevapi\Session;

// Fonctions serialize avec objets non sérialisables (warnings)
class NonSerializable {
    private $resource;
}
$obj = new NonSerializable();
serialize($obj);

// Utilisation de $GLOBALS dans fonctions (warnings si modifié)
function modifyGlobal() {
    $GLOBALS['var'] = 'modified';
}

// Nested ternary sans parenthèses (continué de 7.4)
$result = $a ? $b : $c ? $d : $e;
?>