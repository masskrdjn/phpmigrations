# 📚 Documentation Index / Index de Documentation

> **Complete documentation for Rector PHP Analysis Tools**
> **Documentation complète pour Rector PHP Analysis Tools**

## 🌐 Languages / Langues

### 🇫🇷 Documentation en Français

#### Guides principaux
- **[README.md](../README.md)** - Documentation principale du projet
- **[Guide de démarrage rapide](quick-start.md)** - Mise en route en 5 minutes
- **[Guide de migration](migration-guide.md)** - Migration complète multi-versions
- **[Nouvelles fonctionnalités](../NOUVELLES-FONCTIONNALITES.md)** - Extension multi-versions

#### Guides spécialisés
- **[Configuration avancée](advanced-config.md)** - Personnalisation approfondie
- **[Premiers pas](getting-started.md)** - Installation et premiers tests

#### Historique du projet
- **[Historique de développement](../DEVELOPMENT-HISTORY.md)** - Évolution complète du projet
- **[Rapport de création](../CREATION-REPORT.md)** - Genèse du projet
- **[Guide de contribution](../CONTRIBUTING.md)** - Comment contribuer

### 🇺🇸 English Documentation

#### Main guides
- **[README-EN.md](../README-EN.md)** - Main project documentation
- **[Quick Start Guide](quick-start-en.md)** - Setup in 5 minutes
- **[Migration Guide](migration-guide-en.md)** - Complete multi-version migration
- **[New Features](../NEW-FEATURES-EN.md)** - Multi-version extension

#### Specialized guides
- **[Advanced Configuration](advanced-config.md)** - In-depth customization
- **[Getting Started](getting-started.md)** - Installation and first tests

#### Project history
- **[Development History](../DEVELOPMENT-HISTORY.md)** - Complete project evolution
- **[Creation Report](../CREATION-REPORT.md)** - Project genesis
- **[Contributing Guide](../CONTRIBUTING-EN.md)** - How to contribute

## 🎯 Documentation par scénario / Documentation by Scenario

### Migration Scenarios / Scénarios de migration

| Scenario | Français | English |
|----------|----------|---------|
| **Démarrage rapide** | [quick-start.md](quick-start.md) | [quick-start-en.md](quick-start-en.md) |
| **Migration progressive** | [migration-guide.md](migration-guide.md) | [migration-guide-en.md](migration-guide-en.md) |
| **Configuration custom** | [advanced-config.md](advanced-config.md) | [advanced-config.md](advanced-config.md) |

### Project Levels / Niveaux de projet

| Level | Description | Documentation |
|-------|-------------|---------------|
| **Débutant / Beginner** | First use | [getting-started.md](getting-started.md) |
| **Intermédiaire / Intermediate** | Common migrations | [quick-start.md](quick-start.md) / [quick-start-en.md](quick-start-en.md) |
| **Avancé / Advanced** | Custom configurations | [advanced-config.md](advanced-config.md) |
| **Expert** | Contribution & development | [CONTRIBUTING.md](../CONTRIBUTING.md) / [CONTRIBUTING-EN.md](../CONTRIBUTING-EN.md) |

## 🤝 Contributing / Contribution

### How to contribute / Comment contribuer

| Task / Tâche | Français | English |
|--------------|----------|---------|
| **Bug report / Signaler un bug** | [CONTRIBUTING.md](../CONTRIBUTING.md) | [CONTRIBUTING-EN.md](../CONTRIBUTING-EN.md) |
| **Feature request / Demander une fonctionnalité** | [CONTRIBUTING.md](../CONTRIBUTING.md) | [CONTRIBUTING-EN.md](../CONTRIBUTING-EN.md) |
| **Code contribution / Contribution de code** | [CONTRIBUTING.md](../CONTRIBUTING.md) | [CONTRIBUTING-EN.md](../CONTRIBUTING-EN.md) |
| **Documentation / Documentation** | [CONTRIBUTING.md](../CONTRIBUTING.md) | [CONTRIBUTING-EN.md](../CONTRIBUTING-EN.md) |

## 🔧 Technical Documentation / Documentation Technique

### Configuration Files / Fichiers de configuration

| Version | Configuration | Description |
|---------|---------------|-------------|
| **PHP 5.6** | `config/rector-php56.php` | Legacy projects |
| **PHP 7.0** | `config/rector-php70.php` | First modern migration |
| **PHP 7.4** | `config/rector-php74.php` | Typed properties |
| **PHP 8.0** | `config/rector-php80.php` | Union types, match |
| **PHP 8.1** | `config/rector-php81.php` | Enums, fibers |
| **PHP 8.2** | `config/rector-php82.php` | Readonly classes |
| **PHP 8.3** | `config/rector-php83.php` | Typed constants |
| **PHP 8.4** | `config/rector-php84.php` | Property hooks |
| **Flexible** | `config/rector-flexible.php` | Customizable |
| **Legacy→Modern** | `config/rector-legacy-to-modern.php` | Complete migration |

### Scripts / Scripts

| Script | Purpose | Documentation |
|--------|---------|---------------|
| `rector-analyze.ps1` | Main interface | [README.md](../README.md) |
| `scripts/install-rector.ps1` | Installation | [getting-started.md](getting-started.md) |
| `scripts/analyze-*.ps1` | Report generation | [quick-start.md](quick-start.md) |

## 🎮 VS Code Integration / Intégration VS Code

### Tasks / Tâches disponibles

- **🚀 Rector: Menu Interactif** - Interface complète
- **🔄 Migration: PHP Legacy → Moderne** - Migration complète
- **🎯 Migration: PHP 7.4 → 8.1** - Migration courante
- **🚀 Migration: PHP 8.x → 8.4** - Dernière version
- **🛠️ Configuration: Flexible** - Configuration personnalisable

### Extensions recommandées

- **PowerShell** - Pour l'exécution des scripts
- **PHP** - Support du langage PHP
- **Rector** - Support Rector (si disponible)

## 📊 Quick Reference / Référence Rapide

### Common Commands / Commandes courantes

```powershell
# Interactive menu / Menu interactif
.\rector-analyze.ps1

# Quick migration / Migration rapide
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php"

# Safe analysis / Analyse sécurisée
.\rector-analyze.ps1 -DryRun:$true

# Complete migration / Migration complète
.\rector-analyze.ps1 -ConfigFile "config\rector-legacy-to-modern.php"
```

### Migration Paths / Chemins de migration

```
PHP 5.6 → PHP 7.0 → PHP 7.4 → PHP 8.1 → PHP 8.4
      ↘ PHP 7.4 ↗      ↘ PHP 8.4 ↗
```

---

💡 **Tip / Conseil** : Start with the Quick Start guide appropriate to your language / Commencez par le guide de démarrage rapide dans votre langue !
