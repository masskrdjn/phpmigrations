<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 8.2
 * 
 * Cette configuration modernise votre code pour PHP 8.2 avec
 * les dernières fonctionnalités comme readonly classes, etc.
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

    // Migration vers PHP 8.2
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_82,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
        SetList::PRIVATIZATION,
        SetList::INSTANCEOF,
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
    ]);

    // Configuration spécifique PHP 8.2
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_82);
    
    // Parallel processing
    $rectorConfig->parallel();
    
    // Import short classes
    $rectorConfig->importShortClasses();
};
