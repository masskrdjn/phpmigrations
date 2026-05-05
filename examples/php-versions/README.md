# PHP Version Examples / Exemples de versions PHP

> **Test cases for Rector PHP Analysis Tools**
> **Cas de test pour Rector PHP Analysis Tools**

## 📋 Overview / Vue d'ensemble

This directory contains code examples for each PHP version supported by our migration tool. Each example demonstrates specific features and syntax that can be modernized using Rector.

Ce répertoire contient des exemples de code pour chaque version PHP supportée par notre outil de migration. Chaque exemple démontre des fonctionnalités et syntaxes spécifiques qui peuvent être modernisées avec Rector.

## 🎯 Testing Strategy / Stratégie de test

### 1. Progressive Migration / Migration progressive
Test migration from each version to the next:
- PHP 5.6 → PHP 7.0
- PHP 7.0 → PHP 7.1
- PHP 7.1 → PHP 7.2
- etc.

### 2. Direct Migration / Migration directe
Test direct migration to maintained PHP 8.x versions:
- PHP 5.6 → PHP 8.4
- PHP 7.0 → PHP 8.4
- PHP 7.4 → PHP 8.4

### 3. Specific Features / Fonctionnalités spécifiques
Test specific language features:
- Type declarations
- Anonymous classes
- Arrow functions
- Match expressions
- Enums
- Property hooks

## 📁 Directory Structure / Structure des répertoires

```
php-versions/
├── php56/           # PHP 5.6 examples
├── php70/           # PHP 7.0 examples
├── php71/           # PHP 7.1 examples
├── php72/           # PHP 7.2 examples
├── php73/           # PHP 7.3 examples
├── php74/           # PHP 7.4 examples
├── php80/           # PHP 8.0 examples
├── php81/           # PHP 8.1 examples
├── php82/           # PHP 8.2 examples
├── php83/           # PHP 8.3 examples
├── php84/           # PHP 8.4 examples
└── migration-tests/ # Test scenarios
```

## 🧪 How to Test / Comment tester

### Using VS Code Tasks / Utilisation des tâches VS Code

1. Open VS Code in the project root / Ouvrez VS Code à la racine du projet
2. Use Ctrl+Shift+P → "Tasks: Run Task" / Utilisez Ctrl+Shift+P → "Tâches : Exécuter la tâche"
3. Select the appropriate migration task / Sélectionnez la tâche de migration appropriée

### Using PowerShell / Utilisation de PowerShell

```powershell
# Test specific version migration
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php56" -ConfigFile "config\rector-php70.php"

# Test with dry run (safe)
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php56" -ConfigFile "config\rector-php70.php" -DryRun:$true

# Interactive menu
.\rector-analyze.ps1
```

## 📊 Expected Results / Résultats attendus

Each test should demonstrate:
- Syntax modernization / Modernisation de la syntaxe
- Type improvements / Améliorations des types
- Performance optimizations / Optimisations de performance
- Code quality enhancements / Améliorations de la qualité du code

## 🔍 Verification / Vérification

After running migrations, verify:
1. Code still works / Le code fonctionne toujours
2. Modern syntax is applied / La syntaxe moderne est appliquée
3. No breaking changes / Aucun changement cassant
4. Performance improvements / Améliorations de performance

---

💡 **Tip**: Start with dry-run mode to see what changes would be made
💡 **Conseil** : Commencez par le mode dry-run pour voir les changements qui seraient apportés
