<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 7.3
 * 
 * Cette configuration modernise votre code pour PHP 7.3 avec
 * flexible heredoc/nowdoc syntax, trailing commas, etc.
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

    // Migration vers PHP 7.3
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_73,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
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

    // Configuration spécifique PHP 7.3
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_73);
    
    // Parallel processing pour de meilleures performances
    $rectorConfig->parallel();
    
    // Règles spécifiques à PHP 7.3
    $rectorConfig->rules([
        // Trailing commas in function calls (PHP 7.3)
        \Rector\Php73\Rector\FuncCall\JsonThrowOnErrorRector::class,
        // Flexible heredoc/nowdoc syntax
        \Rector\Php73\Rector\String_\SensitiveHereNowDocRector::class,
    ]);
};
