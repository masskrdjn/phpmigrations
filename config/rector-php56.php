<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 5.6
 * 
 * Cette configuration modernise votre code pour PHP 5.6 avec
 * les dernières améliorations de PHP 5.x avant PHP 7.
 */
return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->paths([
        __DIR__ . '/src',
        __DIR__ . '/classes',
        __DIR__ . '/lib',
        __DIR__ . '/public',
        __DIR__ . '/app',
        // Ajoutez vos dossiers ici
    ]);

    // Migration vers PHP 5.6
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_56,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
    ]);

    // Exclusions communes
    $rectorConfig->skip([
        __DIR__ . '/vendor',
        __DIR__ . '/cache',
        __DIR__ . '/tmp',
        __DIR__ . '/storage',
        __DIR__ . '/var',
        __DIR__ . '/node_modules',
    ]);

    // Configuration spécifique PHP 5.6
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_56);
    
    // Parallel processing pour de meilleures performances
    $rectorConfig->parallel();
    
    // Règles spécifiques à PHP 5.6
    $rectorConfig->rules([
        // Variadic functions (PHP 5.6)
        \Rector\Php56\Rector\FunctionLike\AddDefaultValueForUndefinedVariableRector::class,
        // Constant expressions
        \Rector\Php56\Rector\FuncCall\PowToExponentiationRector::class,
    ]);
};
