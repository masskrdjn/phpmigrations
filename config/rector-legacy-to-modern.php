<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector pour migration depuis PHP ancien vers moderne
 * 
 * Cette configuration est spécialement conçue pour migrer des projets
 * PHP très anciens (5.x et début 7.x) vers des versions modernes.
 * Elle inclut toutes les transformations progressives nécessaires.
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
        __DIR__ . '/inc',
        __DIR__ . '/functions',
        __DIR__ . '/core',
        // Ajoutez vos dossiers ici
    ]);

    // Migration progressive complète
    $rectorConfig->sets([
        // Migration vers les dernières versions PHP
        LevelSetList::UP_TO_PHP_84,
        
        // Amélioration de la qualité du code
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
        SetList::PRIVATIZATION,
        SetList::INSTANCEOF,
        SetList::STRICT_BOOLEANS,
        
        // Optimisations modernes
        SetList::CARBON_2,
    ]);

    // Exclusions étendues pour projets legacy
    $rectorConfig->skip([
        // Dossiers système
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
        __DIR__ . '/images',
        __DIR__ . '/img',
        
        // Dossiers legacy communs
        __DIR__ . '/backup',
        __DIR__ . '/backups',
        __DIR__ . '/old',
        __DIR__ . '/archive',
        __DIR__ . '/deprecated',
        
        // Configuration
        __DIR__ . '/config/cache',
        __DIR__ . '/bootstrap/cache',
        
        // Templates (peuvent contenir du PHP mélangé)
        __DIR__ . '/templates',
        __DIR__ . '/tpl',
        __DIR__ . '/views',
        __DIR__ . '/smarty',
        
        // Fichiers spécifiques aux anciens projets
        __DIR__ . '/install.php',
        __DIR__ . '/setup.php',
        __DIR__ . '/migration.php',
        
        // CMS legacy patterns
        __DIR__ . '/wp-admin',
        __DIR__ . '/wp-includes',
        __DIR__ . '/wp-content',
        __DIR__ . '/administrator',
        __DIR__ . '/components',
        __DIR__ . '/modules/*/tmpl',
        
        // Certaines règles qui peuvent être problématiques pour code legacy
        \Rector\Php74\Rector\Property\TypedPropertyRector::class,
        \Rector\TypeDeclaration\Rector\Property\TypedPropertyFromStrictConstructorRector::class,
    ]);

    // Configuration pour PHP moderne
    $rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_84);
    
    // Performances optimisées
    $rectorConfig->parallel();
    $rectorConfig->cacheDirectory(__DIR__ . '/var/cache/rector');
    
    // Règles personnalisées pour migration legacy
    $rectorConfig->rules([
        // Modernisation des constructeurs PHP 4 -> PHP 5+
        \Rector\Php55\Rector\String_\StringClassNameToClassConstantRector::class,
        
        // Modernisation des arrays
        \Rector\Php54\Rector\Array_\LongArrayToShortArrayRector::class,
        
        // Modernisation des fonctions
        \Rector\DeadCode\Rector\Function_\RemoveUnusedFunctionRector::class,
        
        // Amélioration de la lisibilité
        \Rector\CodeQuality\Rector\If_\SimplifyIfReturnBoolRector::class,
        \Rector\CodeQuality\Rector\Ternary\TernaryToElvisRector::class,
        
        // Type declarations progressives
        \Rector\TypeDeclaration\Rector\ClassMethod\AddVoidReturnTypeWhereNoReturnRector::class,
    ]);
    
    // Configuration spéciale pour maintenir la compatibilité
    // pendant la migration progressive
    $rectorConfig->importNames();
    $rectorConfig->importShortClasses();
};
