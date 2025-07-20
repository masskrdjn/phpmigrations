# Rector PHP Analysis Tools

> **Outils d'analyse et de modernisation PHP avec Rector - Scripts PowerShell pour rapports lisibles**
> **✨ Nouveau : Support de migration depuis toutes les versions PHP principales !**

## 🎯 Vue d'ensemble

Ce projet fournit une suite d'outils PowerShell pour analyser et moderniser votre code PHP avec [Rector](https://github.com/rectorphp/rector). Il transforme la sortie JSON brute de Rector en rapports lisibles et exploitables, et supporte maintenant la migration depuis **toutes les versions PHP principales** (5.6 → 8.4).

## ✨ Fonctionnalités

- **Migration multi-versions** : PHP 5.6, 7.x, 8.x → version moderne
- **Analyse automatique** : Scan complet de votre code PHP
- **Rapports lisibles** : Conversion JSON → Markdown/HTML
- **Multiple formats** : Simple, détaillé, ou sur-mesure
- **Interface interactive** : Menu PowerShell intuitif
- **Configurations pré-définies** : 11 versions PHP supportées
- **Migration progressive** : Étape par étape ou directe
- **Compatible Windows** : Optimisé pour PowerShell 5.1+

## 🚀 Installation rapide

1. **Cloner le projet**
   ```powershell
   git clone [URL_DU_REPO]
   cd phpmigrations
   ```

2. **Installer Rector**
   ```powershell
   .\scripts\install-rector.ps1
   ```

3. **Premier scan**
   ```powershell
   .\rector-analyze.ps1
   ```

## 📁 Structure du projet

```
phpmigrations/
├── scripts/           # Scripts PowerShell principaux
├── config/           # Configurations Rector
├── templates/        # Modèles de rapports
├── examples/         # Exemples d'utilisation
├── docs/            # Documentation détaillée
└── output/          # Rapports générés
```

## 🔧 Scripts disponibles

| Script | Description | Usage |
|--------|-------------|-------|
| `rector-analyze.ps1` | **Menu principal** | Interface interactive |
| `analyze-rector-simple.ps1` | Rapport basique | Résumé rapide |
| `analyze-rector-readable.ps1` | Rapport détaillé | Analyse complète |
| `analyze-rector-detailed.ps1` | Rapport exhaustif | Avec explications |

## 🎯 Versions PHP supportées

| Version Source | Version Cible | Configuration | Complexité |
|----------------|---------------|---------------|------------|
| **PHP 5.6** | PHP 7.0+ | `rector-php70.php` | ⭐⭐⭐ |
| **PHP 7.0** | PHP 7.4+ | `rector-php74.php` | ⭐⭐ |
| **PHP 7.4** | PHP 8.0+ | `rector-php80.php` | ⭐⭐ |
| **PHP 8.0** | PHP 8.1+ | `rector-php81.php` | ⭐ |
| **PHP 8.1** | PHP 8.2+ | `rector-php82.php` | ⭐ |
| **PHP 8.2** | PHP 8.3+ | `rector-php83.php` | ⭐ |
| **PHP 8.3** | PHP 8.4 | `rector-php84.php` | ⭐ |
| **Legacy** | Moderne | `rector-legacy-to-modern.php` | ⭐⭐⭐⭐ |

## 📖 Guide d'utilisation

### Interface interactive
```powershell
# Menu interactif - choisissez votre configuration
.\rector-analyze.ps1
```

### Migration spécifique (projets simples)
```powershell
# PHP 7.4 → PHP 8.1
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector-php81.php"

# Legacy → Moderne (migration directe)
.\rector-analyze.ps1 -ProjectPath "C:\ancien\projet" -ConfigFile "rector-legacy-to-modern.php"
```

### Migration par étapes (recommandée pour projets complexes)
```powershell
# Étape 1 : PHP ancien → PHP 7.4
.\rector-analyze.ps1 -ProjectPath "C:\projet" -ConfigFile "rector-php74.php"

# Étape 2 : PHP 7.4 → PHP 8.1  
.\rector-analyze.ps1 -ProjectPath "C:\projet" -ConfigFile "rector-php81.php"

# Étape 3 : PHP 8.1 → PHP 8.4
.\rector-analyze.ps1 -ProjectPath "C:\projet" -ConfigFile "rector-php84.php"
```

## ⚙️ Configuration

### Configurations pré-définies
Le projet inclut 11 configurations prêtes à l'emploi :

```
config/
├── rector-php56.php      # Migration vers PHP 5.6
├── rector-php70.php      # Migration vers PHP 7.0  
├── rector-php71.php      # Migration vers PHP 7.1
├── rector-php72.php      # Migration vers PHP 7.2
├── rector-php73.php      # Migration vers PHP 7.3
├── rector-php74.php      # Migration vers PHP 7.4
├── rector-php80.php      # Migration vers PHP 8.0
├── rector-php81.php      # Migration vers PHP 8.1
├── rector-php82.php      # Migration vers PHP 8.2
├── rector-php83.php      # Migration vers PHP 8.3
├── rector-php84.php      # Migration vers PHP 8.4
├── rector-flexible.php        # Configuration personnalisable
└── rector-legacy-to-modern.php # Migration complète ancien→moderne
```

### Choisir la bonne configuration

**Migration progressive (recommandée) :**
- Projets complexes ou critiques
- Migration étape par étape pour minimiser les risques
- Tests après chaque étape

**Migration directe :**
- Projets simples ou scripts de petite taille
- `rector-legacy-to-modern.php` pour migration complète
- Plus rapide mais plus risquée

### Personnalisation
```php
// rector-custom.php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_82,  // Votre version cible
    SetList::CODE_QUALITY,       // Règles selon vos besoins
]);
```

## 🎨 Exemples de rapports

### Format simple
```markdown
# Analyse Rector - MonProjet

📊 **Résumé** : 15 fichiers, 42 améliorations possibles
🎯 **Cible** : PHP 8.4
⚡ **Impact** : Modernisation recommandée
```

### Format détaillé
```markdown
## 📂 src/Models/User.php
- **Ligne 23** : `AddArrayDefaultToArrayPropertyRector`
- **Suggestion** : Ajouter `= []` par défaut
- **Avant** : `private array $roles;`
- **Après** : `private array $roles = [];`
```

## 🛠️ Prérequis

- **Windows** : PowerShell 5.1 ou supérieur
- **PHP** : 7.4+ (recommandé : 8.1+)
- **Composer** : Pour l'installation de Rector
- **Git** : Pour le clonage et les mises à jour

## 📚 Documentation

- [Guide de démarrage](docs/getting-started.md)
- [Configuration avancée](docs/advanced-config.md)
- [Personnalisation](docs/customization.md)
- [Dépannage](docs/troubleshooting.md)
- [🇺🇸 English documentation](README-EN.md)

## 🤝 Contribution

Les contributions sont les bienvenues ! Consultez [CONTRIBUTING.md](CONTRIBUTING.md) pour les détails.

📖 **Documentation de contribution** : [🇫🇷 Français](CONTRIBUTING.md) | [🇺🇸 English](CONTRIBUTING-EN.md)

## 📄 Licence

MIT License - voir [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

- [Rector](https://github.com/rectorphp/rector) - L'outil de modernisation PHP
- Communauté PHP - Pour le feedback et les améliorations

---

**Made with ❤️ for PHP developers**
