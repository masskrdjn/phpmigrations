<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 8.3
 * 
 * Cette configuration modernise votre code pour PHP 8.3 avec
 * typed class constants, readonly classes améliorées, etc.
 */
return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->paths([
        __DIR__ . '/src',
        __DIR__ . '/classes',
        __DIR__ . '/lib',
        __DIR__ . '/public',
        __DIR__ . '/app',
        __DIR__ . '/modules',
        // Ajoutez vos dossiers ici
    ]);

    // Migration vers PHP 8.3
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_83,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
        SetList::PRIVATIZATION,
        SetList::INSTANCEOF,
        SetList::STRICT_BOOLEANS,
    ]);

    // Exclusions communes
    $rectorConfig->skip([
        __DIR__ . '/vendor',
        __DIR__ . '/cache',
        __DIR__ . '/tmp',
        __DIR__ . '/storage',
        __DIR__ . '/var',
        __DIR__ . '/node_modules',
        __DIR__ . '/bootstrap/cache',
        __DIR__ . '/public/assets',
    ]);

    // Configuration spécifique PHP 8.3
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_83);
    
    // Parallel processing pour de meilleures performances
    $rectorConfig->parallel();
    
    // Règles spécifiques à PHP 8.3
    $rectorConfig->rules([
        // Typed class constants (PHP 8.3)
        \Rector\TypeDeclaration\Rector\ClassMethod\AddParamTypeDeclarationRector::class,
        // Improved readonly classes
        \Rector\Php83\Rector\ClassConst\AddTypeToConstRector::class,
        // JSON validation improvements
        \Rector\Php83\Rector\ClassMethod\AddOverrideAttributeToOverriddenMethodsRector::class,
    ]);
};
