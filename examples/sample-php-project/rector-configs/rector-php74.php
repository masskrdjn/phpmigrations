<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 7.4
 * 
 * Cette configuration modernise votre code pour PHP 7.4 avec
 * typed properties, arrow functions, et autres améliorations.
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

    // Migration vers PHP 7.4
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_74,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
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

    // Configuration spécifique PHP 7.4
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_74);
    
    // Parallel processing pour de meilleures performances
    $rectorConfig->parallel();
    
    // Règles spécifiques à PHP 7.4
    $rectorConfig->rules([
        // Arrow functions (PHP 7.4)
        \Rector\Php74\Rector\Closure\ClosureToArrowFunctionRector::class,
        // Typed properties (PHP 7.4)
        \Rector\TypeDeclaration\Rector\Property\TypedPropertyFromAssignsRector::class,
        // Null coalescing assignment operator (PHP 7.4)
        \Rector\Php74\Rector\Assign\NullCoalescingOperatorRector::class,
    ]);
};
