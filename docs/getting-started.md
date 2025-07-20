# Guide de démarrage - Rector PHP Analysis Tools

## 🚀 Installation et première utilisation

### Prérequis
- Windows avec PowerShell 5.1+
- PHP 7.4+ (recommandé : PHP 8.1+)
- Composer

### Installation rapide

1. **Cloner le projet**
   ```powershell
   git clone [URL_DU_REPO] phpmigrations
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

## 📊 Votre première analyse

### Mode interactif (recommandé)
```powershell
.\rector-analyze.ps1
```

Le script vous guidera à travers :
- Sélection du projet PHP
- Choix de la configuration Rector
- Format de rapport souhaité
- Options de sauvegarde

### Mode ligne de commande
```powershell
# Analyse simple du répertoire actuel
.\rector-analyze.ps1 -ProjectPath "." -OutputFormat simple

# Rapport détaillé avec sauvegarde
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -OutputFormat detailed -OutputFile "rapport.md"
```

## 📋 Formats de rapport disponibles

### 1. Simple
- Résumé rapide
- Statistiques de base
- Fichiers impactés

### 2. Readable (recommandé)
- Rapport détaillé
- Explication des changements
- Recommandations

### 3. Detailed
- Analyse exhaustive
- Plan d'action
- Exemples de code

### 4. JSON
- Sortie brute Rector
- Pour traitement automatisé

## 🔧 Configuration personnalisée

### Adapter rector.php
```php
<?php
return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->paths([
        __DIR__ . '/src',        // Votre code source
        __DIR__ . '/app',        // Application Laravel/Symfony
        __DIR__ . '/lib',        // Bibliothèques
    ]);

    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_84,  // Version cible
        SetList::CODE_QUALITY,       // Qualité du code
    ]);

    $rectorConfig->skip([
        __DIR__ . '/vendor',     // Exclusions
        __DIR__ . '/cache',
    ]);
};
```

### Utiliser les configurations pré-définies
```powershell
# PHP 8.1
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php"

# PHP 8.2
.\rector-analyze.ps1 -ConfigFile "config\rector-php82.php"

# PHP 8.4 (complet)
.\rector-analyze.ps1 -ConfigFile "config\rector-php84.php"
```

## 📈 Workflow recommandé

### 1. Analyse initiale
```powershell
.\rector-analyze.ps1 -OutputFormat readable -OutputFile "analyse-initiale.md"
```

### 2. Sauvegarde
```bash
git add .
git commit -m "Avant modernisation Rector"
git checkout -b feature/rector-modernization
```

### 3. Application progressive
```bash
# Appliquer par catégorie
rector process --only=TypeDeclarationRector --dry-run
rector process --only=TypeDeclarationRector

# Ou tout en une fois
rector process
```

### 4. Validation
```bash
# Tests
./vendor/bin/phpunit

# Analyse post-migration
.\rector-analyze.ps1 -OutputFormat simple
```

## 🛟 Dépannage

### Problèmes courants

**Rector introuvable**
```powershell
# Installation globale
composer global require rector/rector

# Ou installation locale
composer require rector/rector --dev
```

**Erreurs de permissions**
```powershell
# Exécuter en tant qu'administrateur
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Encodage PowerShell**
```powershell
# Forcer UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

### Obtenir de l'aide
```powershell
# Aide du script principal
.\rector-analyze.ps1 -Help

# Aide des scripts individuels
.\scripts\analyze-rector-simple.ps1 -Help
```

## 💡 Conseils d'utilisation

### Pour les petits projets
- Utilisez le format **simple**
- Appliquez tous les changements en une fois
- Testez immédiatement

### Pour les gros projets
- Commencez par le format **detailed**
- Appliquez par catégories
- Testez après chaque étape

### Pour les équipes
- Partagez les rapports via Git
- Discutez les changements en code review
- Documentez les décisions

## 🔗 Ressources utiles

- [Documentation Rector](https://github.com/rectorphp/rector)
- [Migration PHP](https://www.php.net/migration84)
- [Meilleures pratiques](https://phptherightway.com/)
- [Tests PHPUnit](https://phpunit.de/)

---

**Prêt à moderniser votre code PHP ? Lancez votre première analyse !** 🚀
