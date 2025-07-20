# Configuration avancée - Rector PHP Analysis Tools

## 🎛️ Configuration personnalisée de Rector

### Structure des fichiers de configuration

```
phpmigrations/
├── config/
│   ├── rector-php81.php     # Migration vers PHP 8.1
│   ├── rector-php82.php     # Migration vers PHP 8.2
│   └── rector-php84.php     # Migration complète vers PHP 8.4
└── rector.php               # Configuration par défaut du projet
```

### Création d'une configuration sur-mesure

```php
<?php
// rector-custom.php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use Rector\TypeDeclaration\Rector\ClassMethod\AddVoidReturnTypeWhereNoReturnRector;

return static function (RectorConfig $rectorConfig): void {
    // Dossiers à analyser
    $rectorConfig->paths([
        __DIR__ . '/src',
        __DIR__ . '/app/Models',
        __DIR__ . '/app/Services',
        // Ajustez selon votre structure
    ]);

    // Sets de règles
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_82,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::TYPE_DECLARATION,
        SetList::EARLY_RETURN,
    ]);

    // Règles spécifiques
    $rectorConfig->rule(AddVoidReturnTypeWhereNoReturnRector::class);

    // Exclusions
    $rectorConfig->skip([
        __DIR__ . '/vendor',
        __DIR__ . '/storage',
        __DIR__ . '/bootstrap/cache',
        
        // Exclure des règles spécifiques
        AddVoidReturnTypeWhereNoReturnRector::class => [
            __DIR__ . '/app/Legacy',
        ],
    ]);

    // Performance
    $rectorConfig->parallel();
    $rectorConfig->importShortClasses();
    
    // Cache
    $rectorConfig->cacheDirectory(__DIR__ . '/var/cache/rector');
};
```

### Configurations par environnement

#### Development (rector-dev.php)
```php
<?php
return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_81,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
    ]);
    
    // Mode verbeux pour le développement
    $rectorConfig->importNames();
    $rectorConfig->importShortClasses(false);
};
```

#### Production (rector-prod.php)
```php
<?php
return static function (RectorConfig $rectorConfig): void {
    $rectorConfig->sets([
        LevelSetList::UP_TO_PHP_84,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::TYPE_DECLARATION,
        SetList::PRIVATIZATION,
        SetList::STRICT_BOOLEANS,
    ]);
    
    // Optimisations maximales
    $rectorConfig->parallel();
    $rectorConfig->importShortClasses();
    $rectorConfig->importNames();
};
```

## 📊 Personnalisation des rapports

### Modèles de rapport

Créez vos propres modèles dans `templates/` :

#### Template minimal (templates/minimal.ps1)
```powershell
function Format-MinimalReport {
    param([string]$JsonContent, [string]$ProjectPath)
    
    $data = $JsonContent | ConvertFrom-Json
    
    return @"
🔍 Analyse Rector : $(Split-Path $ProjectPath -Leaf)
📊 Résultats : $($data.totals.applied_rectors) changements sur $($data.totals.changed_files) fichiers
$(Get-Date -Format "HH:mm")
"@
}
```

#### Template HTML (templates/html.ps1)
```powershell
function Format-HtmlReport {
    param([string]$JsonContent, [string]$ProjectPath)
    
    $data = $JsonContent | ConvertFrom-Json
    
    return @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport Rector - $(Split-Path $ProjectPath -Leaf)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .summary { background: #f0f8ff; padding: 15px; border-radius: 5px; }
        .file { margin: 10px 0; padding: 10px; border-left: 3px solid #007acc; }
        .rector { background: #f9f9f9; margin: 5px 0; padding: 8px; }
    </style>
</head>
<body>
    <h1>🔍 Rapport d'analyse Rector</h1>
    <div class="summary">
        <p><strong>Projet :</strong> $ProjectPath</p>
        <p><strong>Fichiers analysés :</strong> $($data.totals.changed_files + $data.totals.unchanged_files)</p>
        <p><strong>Changements proposés :</strong> $($data.totals.applied_rectors)</p>
    </div>
    <!-- Plus de contenu HTML... -->
</body>
</html>
"@
}
```

### Scripts personnalisés

#### Script avec filtrage (scripts/analyze-security.ps1)
```powershell
# Analyse focalisée sur la sécurité
param([string]$ProjectPath)

$securityRectors = @(
    "Rector\DeadCode\Rector\Assign\RemoveUnusedVariableAssignRector",
    "Rector\CodeQuality\Rector\If_\ExplicitBoolCompareRector"
)

# Exécution avec filtres...
```

#### Script avec métriques (scripts/analyze-metrics.ps1)
```powershell
# Calcul de métriques de qualité
function Calculate-QualityMetrics {
    param($RectorData)
    
    $metrics = @{
        ComplexityReduction = 0
        TypeSafety = 0
        Performance = 0
        Maintainability = 0
    }
    
    # Calculs basés sur les règles appliquées...
    return $metrics
}
```

## 🔧 Intégration dans votre workflow

### Git Hooks

#### Pre-commit hook (.git/hooks/pre-commit)
```bash
#!/bin/sh
# Analyse Rector avant commit

echo "Vérification Rector..."
powershell -Command ".\rector-analyze.ps1 -OutputFormat simple -ProjectPath ."

if [ $? -ne 0 ]; then
    echo "❌ Erreur Rector détectée"
    exit 1
fi

echo "✅ Analyse Rector OK"
```

#### Pre-push hook (.git/hooks/pre-push)
```bash
#!/bin/sh
# Analyse complète avant push

powershell -Command ".\rector-analyze.ps1 -OutputFormat detailed -OutputFile 'rector-report.md'"
```

### CI/CD Integration

#### GitHub Actions (.github/workflows/rector.yml)
```yaml
name: Rector Analysis

on: [push, pull_request]

jobs:
  rector:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: '8.1'
        
    - name: Install Composer dependencies
      run: composer install
      
    - name: Run Rector Analysis
      run: |
        powershell -Command ".\scripts\install-rector.ps1 -ProjectPath ."
        powershell -Command ".\rector-analyze.ps1 -OutputFormat json" > rector-report.json
        
    - name: Upload Rector Report
      uses: actions/upload-artifact@v2
      with:
        name: rector-analysis
        path: rector-report.json
```

#### GitLab CI (.gitlab-ci.yml)
```yaml
rector_analysis:
  stage: test
  image: php:8.1
  script:
    - apt-get update && apt-get install -y powershell
    - composer install
    - pwsh ./scripts/install-rector.ps1 -ProjectPath .
    - pwsh ./rector-analyze.ps1 -OutputFormat readable > rector-report.md
  artifacts:
    reports:
      junit: rector-report.md
    expire_in: 1 week
```

### IDE Integration

#### VS Code (tasks.json)
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Rector: Analyse Simple",
            "type": "shell",
            "command": "powershell",
            "args": [
                "-Command",
                ".\\rector-analyze.ps1 -OutputFormat simple"
            ],
            "group": "test",
            "presentation": {
                "echo": true,
                "reveal": "always",
                "focus": false,
                "panel": "new"
            }
        },
        {
            "label": "Rector: Analyse Détaillée",
            "type": "shell",
            "command": "powershell",
            "args": [
                "-Command",
                ".\\rector-analyze.ps1 -OutputFormat detailed -OutputFile rector-detailed.md"
            ],
            "group": "test"
        }
    ]
}
```

#### PhpStorm (External Tools)
```xml
<!-- Settings > Tools > External Tools -->
<tool name="Rector Analysis"
      program="powershell"
      arguments="-Command &quot;.\rector-analyze.ps1 -ProjectPath $ProjectFileDir$&quot;"
      workingDir="$ProjectFileDir$"
      synchronizeAfterRun="true" />
```

## 📈 Monitoring et métriques

### Dashboard personnalisé (scripts/dashboard.ps1)
```powershell
# Tableau de bord de qualité du code
function Generate-QualityDashboard {
    param([string]$ProjectPath)
    
    # Collecte des métriques
    $rectorMetrics = Get-RectorMetrics $ProjectPath
    $phpMetrics = Get-PhpMetrics $ProjectPath
    $testMetrics = Get-TestMetrics $ProjectPath
    
    # Génération du dashboard...
}
```

### Historique des analyses (scripts/history.ps1)
```powershell
# Suivi de l'évolution de la qualité
function Track-QualityEvolution {
    param([string]$ProjectPath)
    
    $historyFile = "$ProjectPath\rector-history.json"
    $currentAnalysis = Get-RectorAnalysis $ProjectPath
    
    # Sauvegarde historique...
}
```

### Alertes automatiques (scripts/alerts.ps1)
```powershell
# Système d'alertes sur régression
function Check-QualityRegression {
    param([string]$ProjectPath, [int]$Threshold = 10)
    
    $lastAnalysis = Get-LastAnalysis $ProjectPath
    $currentAnalysis = Get-RectorAnalysis $ProjectPath
    
    if ($currentAnalysis.Issues -gt $lastAnalysis.Issues + $Threshold) {
        Send-Alert "Régression qualité détectée: +$($currentAnalysis.Issues - $lastAnalysis.Issues) problèmes"
    }
}
```

## 🔒 Bonnes pratiques de sécurité

### Validation des entrées
- Toujours valider les chemins de projet
- Échapper les paramètres PowerShell
- Vérifier les permissions de fichiers

### Isolation des environnements
- Utiliser des configurations séparées dev/prod
- Limiter les accès aux dossiers sensibles
- Audit trail des modifications

### Sauvegardes automatiques
- Backup avant application des changements
- Versioning des configurations
- Recovery procedures documentées

---

**Configuration avancée terminée ! Votre setup Rector est maintenant professionnel.** 🎯
