<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration vers PHP 8.4
 * 
 * Configuration avancée pour adopter toutes les dernières
 * fonctionnalités PHP 8.4 et optimisations modernes.
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

    // Migration complète vers PHP 8.4
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_84,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
        SetList::PRIVATIZATION,
        SetList::INSTANCEOF,
        SetList::STRICT_BOOLEANS,
        SetList::CARBON_2,
    ]);

    // Exclusions étendues
    $rectorConfig->skip([
        __DIR__ . '/vendor',
        __DIR__ . '/cache',
        __DIR__ . '/tmp',
        __DIR__ . '/storage',
        __DIR__ . '/var',
        __DIR__ . '/node_modules',
        __DIR__ . '/bootstrap/cache',
        __DIR__ . '/public/assets',
        __DIR__ . '/resources/views',
    ]);

    // Configuration optimale PHP 8.4
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_84);
    
    // Options de performance
    $rectorConfig->parallel();
    $rectorConfig->importShortClasses();
    $rectorConfig->importNames();
    
    // Cache pour de meilleures performances
    $rectorConfig->cacheDirectory(__DIR__ . '/var/cache/rector');
};
