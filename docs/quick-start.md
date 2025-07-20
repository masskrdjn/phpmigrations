# 🚀 Guide de Démarrage Rapide - Migration Multi-versions

> **Mise en route express pour migrer votre code PHP vers une version moderne**

## 🎯 Premiers pas (5 minutes)

### 1. Identifier votre version PHP actuelle

```powershell
# Dans le dossier de votre projet
php -v
```

### 2. Choisir votre stratégie de migration

| Situation | Configuration recommandée | Temps estimé |
|-----------|---------------------------|--------------|
| **Projet PHP 5.6-7.3** | `rector-legacy-to-modern.php` | 2-4 heures |
| **Projet PHP 7.4** | `rector-php81.php` | 30 minutes |
| **Projet PHP 8.0-8.2** | `rector-php84.php` | 15 minutes |
| **Migration progressive** | Configurations étape par étape | Variable |

### 3. Lancer votre première analyse

```powershell
# Mode interactif (recommandé pour débuter)
.\rector-analyze.ps1

# Mode direct (si vous connaissez votre configuration)
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php" -DryRun:$true
```

## 🎮 Utilisation dans VS Code

### Via les tâches (Ctrl+Shift+P → "Tasks: Run Task")

- **🚀 Rector: Menu Interactif** - Interface complète
- **🔄 Migration: PHP Legacy → Moderne** - Migration complète
- **🎯 Migration: PHP 7.4 → 8.1** - Migration courante
- **🚀 Migration: PHP 8.x → 8.4** - Dernière version

### Via la ligne de commande

```powershell
# Migration la plus courante : PHP 7.4 → PHP 8.1
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php"

# Projet très ancien → PHP moderne
.\rector-analyze.ps1 -ConfigFile "config\rector-legacy-to-modern.php"

# Dernière version PHP
.\rector-analyze.ps1 -ConfigFile "config\rector-php84.php"
```

## 📊 Comprendre les rapports

### Format Simple
```markdown
📊 Résumé : 25 fichiers analysés, 67 améliorations possibles
🎯 Cible : PHP 8.1
⚡ Impact : Migration recommandée (gain de performance attendu)
```

### Format Détaillé
- **Par fichier** : Liste des modifications spécifiques
- **Par catégorie** : Types d'améliorations (performance, sécurité, lisibilité)
- **Exemples** : Code avant/après les transformations

## ⚡ Migrations express

### Scénario 1 : Site WordPress ancien
```powershell
# Étape 1 : Analyser la faisabilité
.\rector-analyze.ps1 -ProjectPath "C:\wordpress" -ConfigFile "config\rector-php74.php" -DryRun:$true

# Étape 2 : Si OK, appliquer (retirez -DryRun)
.\rector-analyze.ps1 -ProjectPath "C:\wordpress" -ConfigFile "config\rector-php74.php" -DryRun:$false
```

### Scénario 2 : Application Laravel moderne
```powershell
# Migration directe vers PHP 8.4
.\rector-analyze.ps1 -ProjectPath "C:\mon-laravel" -ConfigFile "config\rector-php84.php"
```

### Scénario 3 : Script PHP personnalisé
```powershell
# Configuration flexible adaptable
.\rector-analyze.ps1 -ProjectPath "C:\mon-script" -ConfigFile "config\rector-flexible.php"
```

## 🛡️ Mode sécurisé (recommandé)

```powershell
# TOUJOURS commencer en mode dry-run (par défaut)
.\rector-analyze.ps1 -DryRun:$true

# Appliquer SEULEMENT après validation
.\rector-analyze.ps1 -DryRun:$false
```

## 🎯 Configurations spécialisées

### Migration progressive (projets complexes)
```powershell
# Étape 1 : PHP ancien → PHP 7.4
.\rector-analyze.ps1 -ConfigFile "config\rector-php74.php"

# Étape 2 : PHP 7.4 → PHP 8.1
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php"

# Étape 3 : PHP 8.1 → PHP 8.4
.\rector-analyze.ps1 -ConfigFile "config\rector-php84.php"
```

### Migration directe (projets simples)
```powershell
# Tout en une fois
.\rector-analyze.ps1 -ConfigFile "config\rector-legacy-to-modern.php"
```

## 🔧 Personnalisation rapide

### Modifier une configuration existante

1. **Copier** une configuration de base :
   ```powershell
   copy config\rector-php81.php config\rector-custom.php
   ```

2. **Éditer** selon vos besoins :
   ```php
   // Dans rector-custom.php
   $rectorConfig->skip([
       __DIR__ . '/mon-dossier-special',  // Exclure des dossiers
       \Rector\Php81\Rector\SomeRule::class,  // Exclure des règles
   ]);
   ```

3. **Utiliser** votre configuration :
   ```powershell
   .\rector-analyze.ps1 -ConfigFile "config\rector-custom.php"
   ```

## 📋 Checklist avant migration

- [ ] **Backup** du projet complet
- [ ] **Tests** existants fonctionnels
- [ ] **Environnement de test** disponible
- [ ] **Version PHP cible** installée sur le serveur
- [ ] **Dépendances Composer** vérifiées

## 📋 Checklist après migration

- [ ] **Tests automatisés** passent
- [ ] **Test manuel** de l'application
- [ ] **Performance** vérifiée
- [ ] **Logs** sans erreurs PHP
- [ ] **Documentation** mise à jour

## 🆘 Résolution rapide de problèmes

### "Class not found"
```powershell
composer install
composer update
```

### "Memory limit exceeded"
```powershell
php -d memory_limit=2G .\rector-analyze.ps1
```

### "Too many changes"
```powershell
# Migration étape par étape
.\rector-analyze.ps1 -ConfigFile "config\rector-php74.php"  # D'abord 7.4
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php"  # Puis 8.1
```

## 💡 Conseils pro

1. **Commencez petit** : Testez sur un sous-dossier d'abord
2. **Mode dry-run** : Toujours analyser avant d'appliquer
3. **Git** : Committez avant toute migration
4. **Tests** : Lancez vos tests après chaque étape
5. **Progressive** : Préférez les migrations étape par étape pour les gros projets

---

🎉 **Prêt à moderniser votre code PHP !** 

Pour plus de détails, consultez le [Guide complet de migration](migration-guide.md).
