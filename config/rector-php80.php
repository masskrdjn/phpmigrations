<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 8.0
 * 
 * Cette configuration modernise votre code pour PHP 8.0 avec
 * union types, match expressions, constructor property promotion.
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

    // Migration vers PHP 8.0
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_80,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
        SetList::PRIVATIZATION,
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

    // Configuration spécifique PHP 8.0
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_80);
    
    // Parallel processing pour de meilleures performances
    $rectorConfig->parallel();
    
    // Règles spécifiques à PHP 8.0
    $rectorConfig->rules([
        // Constructor property promotion (PHP 8.0)
        \Rector\Php80\Rector\Class_\ClassPropertyAssignToConstructorPromotionRector::class,
        // Match expressions (PHP 8.0)
        \Rector\Php80\Rector\Switch_\ChangeSwitchToMatchRector::class,
        // Union types (PHP 8.0)
        \Rector\TypeDeclaration\Rector\ClassMethod\AddParamTypeDeclarationRector::class,
        // Named arguments optimization
        \Rector\Php80\Rector\FuncCall\ClassOnObjectRector::class,
    ]);
};
