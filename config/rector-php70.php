<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 7.0
 * 
 * Cette configuration modernise votre code pour PHP 7.0 avec
 * scalar type declarations, return type declarations, etc.
 */
return static function (RectorConfig $rectorConfig): void {
    // Configuration des chemins - sera écrasée par le script principal
    $rectorConfig->paths([
        getcwd() . '/*.php',
        getcwd() . '/src',
        getcwd() . '/classes', 
        getcwd() . '/lib',
        getcwd() . '/public',
        __DIR__ . '/app',
        // Ajoutez vos dossiers ici
    ]);

    // Migration vers PHP 7.0
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_70,
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

    // Configuration spécifique PHP 7.0
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_70);
    
    // Parallel processing pour de meilleures performances
    $rectorConfig->parallel();
    
    // Règles spécifiques à PHP 7.0
    $rectorConfig->rules([
        // Scalar type declarations (PHP 7.0)
        \Rector\TypeDeclaration\Rector\ClassMethod\AddParamTypeDeclarationRector::class,
        // Return type declarations
        \Rector\TypeDeclaration\Rector\ClassMethod\AddReturnTypeDeclarationRector::class,
        // Spaceship operator
        \Rector\Php70\Rector\If_\IfToSpaceshipRector::class,
    ]);
};
