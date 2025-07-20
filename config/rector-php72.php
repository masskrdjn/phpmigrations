<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 7.2
 * 
 * Cette configuration modernise votre code pour PHP 7.2 avec
 * object type hint, parameter type widening, etc.
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

    // Migration vers PHP 7.2
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_72,
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

    // Configuration spécifique PHP 7.2
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_72);
    
    // Parallel processing pour de meilleures performances
    $rectorConfig->parallel();
    
    // Règles spécifiques à PHP 7.2
    $rectorConfig->rules([
        // Object type hint (PHP 7.2)
        \Rector\TypeDeclaration\Rector\ClassMethod\AddParamTypeDeclarationRector::class,
        // Parameter type widening
        \Rector\Php72\Rector\FuncCall\GetClassOnNullRector::class,
        // Trailing comma in grouped namespaces
        \Rector\Php72\Rector\FuncCall\StringifyDefineRector::class,
    ]);
};
