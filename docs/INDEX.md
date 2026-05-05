# Documentation Index

Complete documentation for Rector PHP Analysis Tools.

## Languages

### English Documentation

#### Main Guides
- **[README.md](../README.md)** - Main project documentation
- **[Quick Start Guide](quick-start-en.md)** - Setup in 5 minutes
- **[Migration Guide](migration-guide-en.md)** - Complete multi-version migration

#### Specialized Guides
- **[Advanced Configuration](advanced-config.md)** - In-depth customization
- **[Getting Started](getting-started.md)** - First installation and first analysis

#### Project
- **[Contributing Guide](../CONTRIBUTING-EN.md)** - How to contribute

### Documentation en Francais

#### Guides Principaux
- **[README-FR.md](../README-FR.md)** - Documentation principale du projet
- **[Guide de demarrage rapide](quick-start.md)** - Mise en route en 5 minutes
- **[Guide de migration](migration-guide.md)** - Migration complete multi-versions

#### Guides Specialises
- **[Configuration avancee](advanced-config.md)** - Personnalisation approfondie
- **[Premiers pas](getting-started.md)** - Installation et premiere analyse

#### Projet
- **[Guide de contribution](../CONTRIBUTING.md)** - Comment contribuer

## Terms

| Term | Meaning |
|------|---------|
| **Legacy / ancien** | A PHP codebase written for an old runtime or old conventions, usually PHP 5.x, PHP 7.0-7.3, or code that has not followed current PHP practices for several years. |
| **Modern / moderne** | Code targeting a currently maintained PHP version and syntax style. In this project, that usually means PHP 8.1 to PHP 8.4 depending on your production constraints. |

## Documentation by Scenario

### Migration Scenarios

| Scenario | English | Francais |
|----------|---------|----------|
| **Quick start** | [quick-start-en.md](quick-start-en.md) | [quick-start.md](quick-start.md) |
| **Progressive migration** | [migration-guide-en.md](migration-guide-en.md) | [migration-guide.md](migration-guide.md) |
| **Custom configuration** | [advanced-config.md](advanced-config.md) | [advanced-config.md](advanced-config.md) |

### Project Levels

| Level | Description | Documentation |
|-------|-------------|---------------|
| **Beginner** | First use | [getting-started.md](getting-started.md) |
| **Intermediate** | Common migrations | [quick-start-en.md](quick-start-en.md) / [quick-start.md](quick-start.md) |
| **Advanced** | Custom configurations | [advanced-config.md](advanced-config.md) |
| **Expert** | Contribution and development | [CONTRIBUTING-EN.md](../CONTRIBUTING-EN.md) / [CONTRIBUTING.md](../CONTRIBUTING.md) |

## Technical Reference

### Configuration Files

| Version | Configuration | Description |
|---------|---------------|-------------|
| **PHP 5.6** | `config/rector-php56.php` | For legacy PHP 5.6 projects, usually as a first compatibility step. |
| **PHP 7.0** | `config/rector-php70.php` | First step toward PHP 7 syntax and type declarations. |
| **PHP 7.4** | `config/rector-php74.php` | Typed properties and common PHP 7 modernization. |
| **PHP 8.0** | `config/rector-php80.php` | Union types, match expressions, and PHP 8 baseline changes. |
| **PHP 8.1** | `config/rector-php81.php` | Enums, readonly properties, and common current-runtime targets. |
| **PHP 8.2** | `config/rector-php82.php` | Readonly classes and PHP 8.2 compatibility. |
| **PHP 8.3** | `config/rector-php83.php` | Typed constants and PHP 8.3 compatibility. |
| **PHP 8.4** | `config/rector-php84.php` | Latest target currently covered by this project. |
| **Customizable** | `config/rector-customizable.php` | Copy-and-edit starter config. |
| **Old Code to PHP 8.4** | `config/rector-old-code-to-php84.php` | Direct migration profile for old PHP 5.x or early PHP 7.x codebases targeting PHP 8.4. |

### Scripts

| Script | Purpose | Documentation |
|--------|---------|---------------|
| `rector-analyze.ps1` | Main interface | [README.md](../README.md) |
| `scripts/install-rector.ps1` | Rector installation helper | [getting-started.md](getting-started.md) |
| `scripts/analyze-*.ps1` | Report generation | [quick-start-en.md](quick-start-en.md) |

## Quick Reference

```powershell
# Interactive menu
.\rector-analyze.ps1

# Recommended dynamic target selection
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -PhpVersion 84

# Safe analysis, explicit dry-run
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -PhpVersion 81 -DryRun:$true

# Use an existing Rector config exactly as-is
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -ConfigFile "rector.php" -UseRawConfig
```

## Migration Paths

```text
PHP 5.6 -> PHP 7.0 -> PHP 7.4 -> PHP 8.1 -> PHP 8.4
PHP 7.4 -> PHP 8.1 -> PHP 8.4
PHP 8.x -> PHP 8.4
```

Start with the quick start guide in your preferred language, then move to the migration guide when you need a broader strategy.
