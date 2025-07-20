# Guide de Migration PHP Multi-versions

> **Guide complet pour migrer votre code PHP depuis n'importe quelle version vers une version plus récente**

## 📋 Versions PHP supportées

Notre outil supporte maintenant la migration depuis et vers toutes les versions principales de PHP :

### Versions supportées comme source ET cible :
- **PHP 5.6** - Dernière version PHP 5.x stable
- **PHP 7.0** - Première version PHP 7.x avec types scalaires
- **PHP 7.1** - Nullable types, void return type
- **PHP 7.2** - Object type hint, parameter type widening
- **PHP 7.3** - Flexible heredoc/nowdoc, trailing commas
- **PHP 7.4** - Typed properties, arrow functions
- **PHP 8.0** - Union types, constructor property promotion, match
- **PHP 8.1** - Enums, fibers, intersection types
- **PHP 8.2** - Readonly classes, DNF types
- **PHP 8.3** - Typed class constants, json_validate()
- **PHP 8.4** - Property hooks, asymmetric visibility

## 🎯 Configurations disponibles

### Configurations par version cible

| Configuration | Description | Recommandé pour |
|---------------|-------------|-----------------|
| `rector-php56.php` | Migration vers PHP 5.6 | Projets legacy très anciens |
| `rector-php70.php` | Migration vers PHP 7.0 | Premier pas vers PHP moderne |
| `rector-php71.php` | Migration vers PHP 7.1 | Ajout des nullable types |
| `rector-php72.php` | Migration vers PHP 7.2 | Amélioration des types |
| `rector-php73.php` | Migration vers PHP 7.3 | Syntaxe moderne |
| `rector-php74.php` | Migration vers PHP 7.4 | Typed properties |
| `rector-php80.php` | Migration vers PHP 8.0 | Features majeures PHP 8 |
| `rector-php81.php` | Migration vers PHP 8.1 | Enums et améliorations |
| `rector-php82.php` | Migration vers PHP 8.2 | Readonly classes |
| `rector-php83.php` | Migration vers PHP 8.3 | Constantes typées |
| `rector-php84.php` | Migration vers PHP 8.4 | Dernières innovations |

### Configurations spécialisées

| Configuration | Description | Usage |
|---------------|-------------|-------|
| `rector-flexible.php` | Configuration adaptable | Personnalisation avancée |
| `rector-legacy-to-modern.php` | Migration complète | Projets très anciens → PHP moderne |

## 🚀 Scénarios de migration courants

### 1. Migration progressive (recommandée)

Pour un projet PHP 5.6, migrez étape par étape :

```powershell
# Étape 1 : PHP 5.6 → PHP 7.0
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector-php70.php"

# Étape 2 : PHP 7.0 → PHP 7.4
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector-php74.php"

# Étape 3 : PHP 7.4 → PHP 8.1
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector-php81.php"
```

### 2. Migration directe (projets simples)

Pour migrer directement vers une version récente :

```powershell
# PHP ancien → PHP 8.4 (dernière version)
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector-legacy-to-modern.php"
```

### 3. Migration ciblée

Pour migrer vers une version spécifique :

```powershell
# Vers PHP 8.0 pour compatibilité serveur
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector-php80.php"
```

## 📊 Matrice de compatibilité

### Depuis PHP 5.6
- ✅ **PHP 7.0** - Migration sûre, changements majeurs
- ✅ **PHP 7.4** - Migration progressive recommandée
- ⚠️ **PHP 8.0** - Attention aux breaking changes
- ⚠️ **PHP 8.4** - Utiliser `rector-legacy-to-modern.php`

### Depuis PHP 7.x
- ✅ **PHP 8.1** - Migration naturelle
- ✅ **PHP 8.2** - Peu de breaking changes
- ✅ **PHP 8.3** - Migration sûre
- ✅ **PHP 8.4** - Recommandée

### Depuis PHP 8.x
- ✅ **Versions supérieures** - Migration très sûre
- ✅ **Features modernes** - Adoption progressive

## ⚙️ Utilisation avec l'interface interactive

1. **Lancez le script principal :**
   ```powershell
   .\rector-analyze.ps1
   ```

2. **Sélectionnez votre projet** (option 1-4)

3. **Choisissez la configuration** appropriée selon votre migration

4. **Sélectionnez le format de rapport** selon vos besoins

## 🎛️ Configurations personnalisées

### Adapter une configuration existante

Copiez une configuration et modifiez-la :

```php
// Dans rector-custom.php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_82,  // Votre version cible
    SetList::CODE_QUALITY,       // Règles selon vos besoins
]);

$rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_82);
```

### Exclure certaines règles

```php
$rectorConfig->skip([
    // Exclure des dossiers
    __DIR__ . '/legacy',
    
    // Exclure des règles spécifiques
    \Rector\Php74\Rector\Property\TypedPropertyRector::class,
]);
```

## 🔍 Analyse avant migration

### Vérifier la version PHP actuelle

```powershell
# Dans votre projet
php -v

# Rechercher les incompatibilités potentielles
.\rector-analyze.ps1 -OutputFormat "detailed" -DryRun:$true
```

### Estimer la complexité de migration

| Taille du projet | PHP 5.x → 7.x | PHP 7.x → 8.x | PHP 8.x → 8.y |
|------------------|---------------|---------------|---------------|
| < 10 fichiers    | 1-2 heures    | 30 minutes    | 15 minutes    |
| 10-100 fichiers  | 1-2 jours     | 2-4 heures    | 1 heure       |
| 100+ fichiers    | 1-2 semaines  | 1-2 jours     | 2-4 heures    |

## ⚠️ Précautions importantes

### Avant la migration

1. **Backup complet** de votre projet
2. **Tests existants** fonctionnels
3. **Documentation** des dépendances
4. **Environnement de test** préparé

### Pendant la migration

1. **Mode dry-run** activé par défaut
2. **Migration progressive** recommandée
3. **Tests fréquents** après chaque étape
4. **Validation** sur environnement de test

### Après la migration

1. **Tests complets** de l'application
2. **Performance** vérifiée
3. **Dépendances** mises à jour
4. **Documentation** actualisée

## 🏗️ Exemples pratiques

### Projet WordPress ancien

```powershell
# WordPress PHP 5.6 → PHP 7.4
.\rector-analyze.ps1 -ProjectPath "C:\wordpress" -ConfigFile "rector-php74.php"
```

### Application Laravel

```powershell
# Laravel → PHP 8.2
.\rector-analyze.ps1 -ProjectPath "C:\mon-laravel" -ConfigFile "rector-php82.php"
```

### Script personnalisé

```powershell
# Script personnalisé → PHP moderne
.\rector-analyze.ps1 -ProjectPath "C:\mon-script" -ConfigFile "rector-legacy-to-modern.php"
```

## 📈 Avantages par version

### Migration vers PHP 7.x
- **Performance** : 2x plus rapide que PHP 5.6
- **Types scalaires** : Meilleure fiabilité
- **Return types** : Code plus robuste
- **Null coalescing** : Syntaxe simplifiée

### Migration vers PHP 8.x
- **JIT Compiler** : Performance accrue
- **Union types** : Flexibilité des types
- **Match expressions** : Alternative à switch
- **Constructor promotion** : Code plus concis

### Migration vers PHP 8.4
- **Property hooks** : Encapsulation moderne
- **Asymmetric visibility** : Contrôle granulaire
- **Performance** : Optimisations continues
- **Sécurité** : Corrections de bugs

## 🆘 Résolution de problèmes

### Erreurs fréquentes

**Erreur :** "Class not found"
```powershell
# Solution : Installer/mettre à jour Composer
composer install
composer update
```

**Erreur :** "Memory limit exceeded"
```powershell
# Solution : Augmenter la limite PHP
php -d memory_limit=2G vendor/bin/rector
```

**Erreur :** "Syntax error"
```powershell
# Solution : Migration progressive
# Utilisez une version intermédiaire
```

---

💡 **Conseil** : Commencez toujours par une migration en mode `dry-run` pour évaluer l'ampleur des changements avant de les appliquer !
