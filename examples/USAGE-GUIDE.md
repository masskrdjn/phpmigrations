# 🧪 Guide d'utilisation des exemples PHP / PHP Examples Usage Guide

> **Comment tester toutes les possibilités de migration avec les exemples fournis**
> **How to test all migration possibilities with the provided examples**

## 🎯 Vue d'ensemble / Overview

Ce guide vous explique comment utiliser les exemples de code pour tester toutes les fonctionnalités de migration Rector disponibles dans ce projet.

This guide explains how to use the code examples to test all Rector migration features available in this project.

## 📁 Structure des exemples / Examples Structure

```
examples/php-versions/
├── README.md                    # Guide principal / Main guide
├── php56/                       # Old PHP 5.6 code
│   └── legacy-code.php         # Code hérité typique : PHP 5.x ou anciennes conventions
├── php70/                       # Fonctionnalités introduites avec PHP 7.0
│   └── modern-code.php         # Fonctionnalités PHP 7 plus récentes
├── php74/                       # PHP 7.4 advanced features
│   └── advanced-features.php   # Fonctionnalités avancées
├── php80/                       # PHP 8.0 cutting edge
│   └── modern-features.php     # Fonctionnalités PHP 8 récentes
├── php81/                       # PHP 8.1 enums & fibers
│   └── enums-and-fibers.php    # Enums et fibers
├── php82/                       # PHP 8.2 readonly & DNF
│   └── readonly-and-dnf.php    # Classes readonly et types DNF
├── php84/                       # PHP 8.4 latest features
│   └── cutting-edge.php        # Dernières fonctionnalités
└── migration-tests/             # Scripts de test automatisés
    ├── README.md               # Guide des tests
    ├── test-php56-to-70.ps1    # Test migration 5.6→7.0
    ├── test-old-code-to-php84.ps1 # Test migration complète
    └── run-all-tests.ps1       # Lance tous les tests
```

## 🚀 Méthodes de test / Testing Methods

### 1. Interface interactive / Interactive Interface

Lancez le menu interactif pour explorer toutes les options :

Launch the interactive menu to explore all options:

```powershell
.\rector-analyze.ps1
```

### 2. Tests automatisés / Automated Tests

#### Via VS Code Tasks / Using VS Code Tasks

1. Ouvrez VS Code : `code .`
2. Utilisez `Ctrl+Shift+P` → "Tasks: Run Task"
3. Sélectionnez un test :
   - 🧪 Test: Migration PHP 5.6 → 7.0
   - 🚀 Test: Migration Old Code → PHP 8.4
   - 🧪 Test: Tous les Tests de Migration

#### Via PowerShell / Using PowerShell

```powershell
# Test d'une migration spécifique
.\examples\php-versions\migration-tests\test-php56-to-70.ps1 -DryRun

# Test de migration complète
.\examples\php-versions\migration-tests\test-old-code-to-php84.ps1 -DryRun -SourceVersion php56

# Tous les tests avec rapport détaillé
.\examples\php-versions\migration-tests\run-all-tests.ps1 -DryRun -Verbose
```

### 3. Tests manuels / Manual Testing

#### Migration Progressive / Progressive Migration

Testez la migration étape par étape :

Test step-by-step migration:

```powershell
# PHP 5.6 → 7.0
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php56" -ConfigFile "config\rector-php70.php" -DryRun:$true

# PHP 7.0 → 7.4
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php70" -ConfigFile "config\rector-php74.php" -DryRun:$true

# PHP 7.4 → 8.1
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php74" -ConfigFile "config\rector-php81.php" -DryRun:$true

# PHP 8.1 → 8.4
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php81" -ConfigFile "config\rector-php84.php" -DryRun:$true
```

#### Migration Directe / Direct Migration

Testez la migration directe vers PHP 8.4 :

Test direct migration to PHP 8.4:

```powershell
# PHP 5.6 → PHP 8.4 (saut direct)
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php56" -ConfigFile "config\rector-old-code-to-php84.php" -DryRun:$true

# Configuration flexible
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php70" -ConfigFile "config\rector-customizable.php" -DryRun:$true
```

## 📊 Types de tests disponibles / Available Test Types

### 1. Tests de Syntaxe / Syntax Tests

| Fonctionnalité / Feature | Source | Target | Commande / Command |
|---------------------------|--------|--------|-------------------|
| **Array syntax** | `array()` | `[]` | `test-php56-to-70.ps1` |
| **Null coalescing** | `isset()` | `??` | `test-php56-to-70.ps1` |
| **Arrow functions** | `function()` | `fn()` | `test-old-code-to-php84.ps1` |
| **Match expressions** | `switch` | `match` | `test-old-code-to-php84.ps1` |

### 2. Tests de Types / Type Tests

| Fonctionnalité / Feature | Source | Target | Configuration |
|---------------------------|--------|--------|---------------|
| **Scalar types** | No hints | `string`, `int` | `rector-php70.php` |
| **Return types** | No types | `: string` | `rector-php70.php` |
| **Union types** | Single type | `string|int` | `rector-php80.php` |
| **Property types** | No types | `public string` | `rector-php74.php` |

### 3. Tests de Fonctionnalités / Feature Tests

| Fonctionnalité / Feature | Version | Exemple / Example | Configuration |
|---------------------------|---------|------------------|---------------|
| **Enums** | PHP 8.1+ | `UserStatus` | `rector-php81.php` |
| **Readonly classes** | PHP 8.2+ | `UserProfile` | `rector-php82.php` |
| **Property hooks** | PHP 8.4+ | `$fahrenheit` | `rector-php84.php` |
| **Fibers** | PHP 8.1+ | `AsyncProcessor` | `rector-php81.php` |

## 🔍 Analyse des résultats / Result Analysis

### Mode Dry-Run (Recommandé) / Dry-Run Mode (Recommended)

Utilisez toujours le mode dry-run d'abord pour voir les changements :

Always use dry-run mode first to see the changes:

```powershell
# Voir les changements sans les appliquer
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php56" -ConfigFile "config\rector-php70.php" -DryRun:$true
```

### Formats de sortie / Output Formats

| Format | Description | Usage |
|--------|-------------|-------|
| **simple** | Résumé basique / Basic summary | Tests rapides / Quick tests |
| **readable** | Format lisible / Human readable | Analyse détaillée / Detailed analysis |
| **detailed** | Complet avec diff / Complete with diff | Debug et vérification / Debug & verification |

### Rapports / Reports

Les rapports sont sauvegardés dans `output/` :

Reports are saved in `output/`:

```
output/
├── rector-detailed.md      # Rapport détaillé / Detailed report
├── test-results/          # Résultats des tests / Test results
│   └── migration-test-report-YYYYMMDD-HHMMSS.json
└── migration-reports/     # Rapports de migration / Migration reports
```

## 🛠️ Personnalisation / Customization

### Créer vos propres tests / Create Your Own Tests

1. Copiez un fichier d'exemple existant
2. Modifiez le code pour tester des fonctionnalités spécifiques
3. Lancez la migration avec la configuration appropriée

1. Copy an existing example file
2. Modify the code to test specific features  
3. Run migration with appropriate configuration

### Configurations personnalisées / Custom Configurations

Utilisez `rector-customizable.php` comme base pour vos propres configurations :

Use `rector-customizable.php` as a base for your own configurations:

```powershell
# Copiez la configuration flexible
cp config\rector-customizable.php config\my-custom-config.php

# Modifiez selon vos besoins
# Edit according to your needs

# Testez votre configuration
.\rector-analyze.ps1 -ConfigFile "config\my-custom-config.php" -ProjectPath "examples\php-versions\php56"
```

## 📋 Checklist de test / Testing Checklist

### Tests Essentiels / Essential Tests

- [ ] **Migration PHP 5.6 → 7.0** : Modernisation de base
- [ ] **Migration PHP 7.4 → 8.1** : Transition vers PHP 8.1
- [ ] **Migration Old Code → PHP 8.4** : Saut complet
- [ ] **Configuration flexible** : Personnalisation

### Tests Avancés / Advanced Tests

- [ ] **Tous les tests automatisés** : Couverture complète
- [ ] **Tests de régression** : Vérification de non-régression
- [ ] **Tests de performance** : Impact sur la performance
- [ ] **Tests de compatibilité** : Compatibilité entre versions

## 🚨 Dépannage / Troubleshooting

### Erreurs communes / Common Errors

| Erreur / Error | Solution |
|----------------|----------|
| **Config file not found** | Vérifiez le chemin vers `config/` |
| **Source directory not found** | Vérifiez le chemin vers `examples/` |
| **Rector not installed** | Lancez `.\scripts\install-rector.ps1` |
| **Permission denied** | Lancez PowerShell en administrateur |

### Mode Debug / Debug Mode

Utilisez le mode verbose pour plus d'informations :

Use verbose mode for more information:

```powershell
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php56" -ConfigFile "config\rector-php70.php" -DryRun:$true -OutputFormat detailed
```

## 📚 Ressources supplémentaires / Additional Resources

- **[Documentation Rector](https://getrector.org/documentation)** - Documentation officielle
- **[PHP Migration Guide](https://www.php.net/manual/en/migration80.php)** - Guide de migration PHP
- **[Rector Rules](https://github.com/rectorphp/rector/blob/main/docs/rector_rules_overview.md)** - Liste des règles disponibles

---

💡 **Conseil / Tip** : Commencez toujours par le mode dry-run et testez sur des copies de vos fichiers !

💡 **Tip**: Always start with dry-run mode and test on copies of your files!
