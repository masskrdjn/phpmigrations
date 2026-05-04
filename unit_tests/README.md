# Unit Tests

Ce dossier contient les tests PHPUnit du projet `phpmigrations`.

The tests verify the behavior of the PowerShell analyzer, especially how `rector-analyze.ps1` reports failures in temporary PHP projects.

## Installation

Depuis ce dossier :

```bash
composer install
```

Les tests utilisent des fonctions PHP modernes comme `str_contains()`, donc PHP 8.0+ est recommandé pour les lancer.

## Running Tests

Depuis la racine du dépôt :

```powershell
.\run_unit_tests.bat
```

Ou directement depuis `unit_tests/` :

```bash
composer test
```

Equivalent PHPUnit direct call:

```bash
./vendor/bin/phpunit
```

On Windows, this may also be:

```powershell
.\vendor\bin\phpunit.bat
```

## Test Suite

### `MigrationFailureTest`

This suite creates isolated temporary PHP projects, runs the repository-level `rector-analyze.ps1` script with:

```powershell
-Interactive:$false -OutputFormat simple
```

and checks that failures or compatibility issues are visible in the combined stdout/stderr output.

Current tests:

| Test | Purpose |
| --- | --- |
| `testMigrationFailsOnSyntaxError` | Verifies that invalid PHP syntax is reported as an error. |
| `testMigrationDetectsDeprecatedCreateFunction` | Verifies that `create_function()` is detected or produces a Rector warning/error when targeting PHP 8.4. |

## Structure

```text
unit_tests/
  composer.json
  phpunit.xml
  README.md
  tests/
    MigrationFailureTest.php
```

## Notes

- Temporary projects are created under the system temp directory and removed after each test.
- Rector is executed in dry-run mode by default through `rector-analyze.ps1`.
- The tests assume `php` 8.0+, `composer`, PowerShell, and the project-level Rector setup are available.
