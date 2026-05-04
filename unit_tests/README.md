# Tests Unitaires / Unit Tests

Ce dossier contient les tests unitaires pour le projet de migrations PHP.

This folder contains unit tests for the PHP migrations project.

## Installation / Installation

1. Installer les dépendances avec Composer :
   Install dependencies with Composer:

   ```bash
   composer install
   ```

## Exécution des tests / Running Tests

### Via Composer / Using Composer

```bash
composer test
```

### Via PHPUnit directement / Using PHPUnit directly

```bash
./vendor/bin/phpunit
```

## Description des tests / Test Description

### MigrationFailureTest

Ce test vérifie que les migrations Rector échouent correctement lorsqu'elles rencontrent du code incompatible ou avec des erreurs.

This test verifies that Rector migrations fail properly when encountering incompatible code or errors.

#### testMigrationFailsOnSyntaxError

- **Objectif** : Vérifier qu'une migration échoue sur du code avec une erreur de syntaxe
- **Code testé** : Fichier PHP avec un point-virgule manquant
- **Attendu** : Rector doit détecter l'erreur de parsing et la signaler

#### testMigrationFailsOnDeprecatedFeature

- **Objectif** : Vérifier qu'une migration détecte les fonctionnalités dépréciées
- **Code testé** : Utilisation de `create_function()` (supprimée en PHP 8.0)
- **Attendu** : Rector doit signaler l'utilisation de la fonctionnalité dépréciée

## Structure des fichiers / File Structure

```
unit_tests/
├── composer.json          # Configuration Composer
├── phpunit.xml           # Configuration PHPUnit
├── tests/
│   └── MigrationFailureTest.php  # Tests de migration qui échouent
└── README.md             # Ce fichier
```

## Notes importantes / Important Notes

- Les tests utilisent des fichiers temporaires pour éviter de modifier le code source
- Les tests sont exécutés en mode dry-run pour ne pas appliquer les changements
- Assurez-vous que Rector est installé et configuré avant de lancer les tests

- Tests use temporary files to avoid modifying source code
- Tests run in dry-run mode to not apply changes
- Make sure Rector is installed and configured before running tests