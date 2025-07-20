<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector flexible pour migration entre versions PHP
 * 
 * Cette configuration peut être adaptée pour migrer depuis n'importe
 * quelle version PHP vers une version plus récente.
 * 
 * Modifiez les sets selon vos besoins :
 * - UP_TO_PHP_XX : pour migrer vers une version spécifique
 * - phpVersion() : pour définir la version cible
 */
return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->paths([
        __DIR__ . '/src',
        __DIR__ . '/classes',
        __DIR__ . '/lib',
        __DIR__ . '/public',
        __DIR__ . '/app',
        __DIR__ . '/modules',
        __DIR__ . '/includes',
        __DIR__ . '/functions',
        // Ajoutez vos dossiers ici
    ]);

    // =================================================================
    // CONFIGURATION DE MIGRATION - MODIFIEZ SELON VOS BESOINS
    // =================================================================
    
    // Choisissez votre version cible (décommentez la ligne appropriée) :
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_56]);  // Migration vers PHP 5.6
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_70]);  // Migration vers PHP 7.0
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_71]);  // Migration vers PHP 7.1
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_72]);  // Migration vers PHP 7.2
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_73]);  // Migration vers PHP 7.3
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_74]);  // Migration vers PHP 7.4
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_80]);  // Migration vers PHP 8.0
    $rectorConfig->sets([LevelSetList::UP_TO_PHP_81]);     // Migration vers PHP 8.1 (par défaut)
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_82]);  // Migration vers PHP 8.2
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_83]);  // Migration vers PHP 8.3
    // $rectorConfig->sets([LevelSetList::UP_TO_PHP_84]);  // Migration vers PHP 8.4
    
    // Sets de règles additionnelles (recommandées)
    $rectorConfig->sets([
        SetList::CODE_QUALITY,          // Amélioration de la qualité du code
        SetList::DEAD_CODE,             // Suppression du code mort
        SetList::EARLY_RETURN,          // Optimisation des returns
        SetList::TYPE_DECLARATION,      // Déclarations de types
        SetList::PRIVATIZATION,         // Amélioration de l'encapsulation
        SetList::INSTANCEOF,            // Optimisation des instanceof
    ]);

    // =================================================================
    // EXCLUSIONS - DOSSIERS À IGNORER
    // =================================================================
    
    $rectorConfig->skip([
        // Dossiers standards à exclure
        __DIR__ . '/vendor',
        __DIR__ . '/cache',
        __DIR__ . '/tmp',
        __DIR__ . '/temp',
        __DIR__ . '/storage',
        __DIR__ . '/var',
        __DIR__ . '/logs',
        __DIR__ . '/log',
        
        // Dossiers frontend
        __DIR__ . '/node_modules',
        __DIR__ . '/bower_components',
        __DIR__ . '/public/assets',
        __DIR__ . '/assets',
        __DIR__ . '/js',
        __DIR__ . '/css',
        
        // Dossiers framework spécifiques
        __DIR__ . '/bootstrap/cache',
        __DIR__ . '/resources/views',
        __DIR__ . '/config/cache',
        
        // Fichiers de test (décommentez si vous voulez les exclure)
        // __DIR__ . '/tests',
        // __DIR__ . '/test',
        
        // Fichiers de migration/seeds (décommentez si vous voulez les exclure)
        // __DIR__ . '/database/migrations',
        // __DIR__ . '/database/seeds',
    ]);

    // =================================================================
    // CONFIGURATION VERSION PHP CIBLE
    // =================================================================
    
    // Définissez la version PHP cible (modifiez selon vos besoins) :
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_81);
    
    // Autres versions disponibles :
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_56);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_70);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_71);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_72);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_73);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_74);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_80);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_82);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_83);
    // $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_84);
    
    // =================================================================
    // OPTIMISATIONS
    // =================================================================
    
    // Traitement en parallèle pour de meilleures performances
    $rectorConfig->parallel();
    
    // Cache pour accélérer les analyses répétées
    $rectorConfig->cacheDirectory(__DIR__ . '/var/cache/rector');
};
