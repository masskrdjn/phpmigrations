<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\ValueObject\PhpVersion;

/**
 * Configuration Rector pour migration vers PHP 7.0 - VERSION TEST
 * 
 * Cette configuration modernise votre code pour PHP 7.0 avec
 * scalar type declarations, return type declarations, etc.
 */
return static function (RectorConfig $rectorConfig): void {
    // Configuration des chemins - analyser tous les fichiers PHP du dossier courant
    $rectorConfig->paths([
        getcwd(),
    ]);

    // Ignorer les dossiers vendor et cache
    $rectorConfig->skip([
        '*/vendor/*',
        '*/cache/*',
        '*/tmp/*',
        '*/temp/*',
        '*/.git/*'
    ]);

    // Définir la version PHP cible
    $rectorConfig->phpVersion(PhpVersion::PHP_70);

    // Appliquer les ensembles de règles pour PHP 7.0
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_70,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
    ]);

    // Configuration du cache
    $rectorConfig->cacheDirectory(sys_get_temp_dir() . '/rector_cache');
    
    // Configuration des imports
    $rectorConfig->importNames();
    $rectorConfig->importShortClasses();
};
