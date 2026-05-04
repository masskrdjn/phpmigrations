<?php
// Code PHP 7.0 avec problèmes de migration
// Utilisation de call_user_method (supprimé en 7.0)
class MyClass {
    public function myMethod() {
        echo "Hello";
    }
}

$obj = new MyClass();
call_user_method('myMethod', $obj);

// Utilisation de set_magic_quotes_runtime (supprimé)
set_magic_quotes_runtime(true);

// Fonctions ereg (supprimées en 7.0)
ereg_replace('pattern', 'replacement', $string);

// Variables non typées dans fonctions (warnings en 7.0+)
function myFunction($param) {
    // $param peut être null, causant warnings
}
myFunction();
?>