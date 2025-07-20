<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 7.1
 * 
 * Cette configuration modernise votre code pour PHP 7.1 avec
 * nullable types, void return type, class constant visibility.
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

    // Migration vers PHP 7.1
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_71,
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

    // Configuration spécifique PHP 7.1
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_71);
    
    // Parallel processing pour de meilleures performances
    $rectorConfig->parallel();
    
    // Règles spécifiques à PHP 7.1
    $rectorConfig->rules([
        // Nullable types (PHP 7.1)
        \Rector\TypeDeclaration\Rector\ClassMethod\AddReturnTypeDeclarationRector::class,
        // Void return type
        \Rector\Php71\Rector\FuncCall\RemoveExtraParametersRector::class,
        // Class constant visibility
        \Rector\Php71\Rector\ClassConst\PublicConstantVisibilityRector::class,
    ]);
};
