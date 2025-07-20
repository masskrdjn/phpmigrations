# ==============================================================================
# Script d'installation de Rector PHP Analysis Tools
# ==============================================================================

param(
    [string]$ProjectPath = "",
    [switch]$Global = $false,
    [switch]$Force = $false,
    [switch]$Help = $false
)

# Affichage de l'aide
if ($Help) {
    Write-Host @"
RECTOR PHP ANALYSIS TOOLS - Installation

SYNOPSIS:
    .\install-rector.ps1 [-ProjectPath <chemin>] [-Global] [-Force] [-Help]

DESCRIPTION:
    Installe Rector et configure l'environnement d'analyse PHP.

PARAMETRES:
    -ProjectPath <chemin>   Chemin du projet PHP a analyser
    -Global                 Installation globale de Rector
    -Force                  Force la reinstallation
    -Help                   Affiche cette aide

EXEMPLES:
    .\install-rector.ps1
    .\install-rector.ps1 -ProjectPath "C:\mon\projet"
    .\install-rector.ps1 -Global -Force

"@ -ForegroundColor Cyan
    exit 0
}

Write-Host "===========================================" -ForegroundColor Green
Write-Host "   RECTOR PHP ANALYSIS TOOLS - SETUP" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""

# Verification de PHP
Write-Host "Verification de PHP..." -ForegroundColor Yellow
try {
    $phpVersion = php -v 2>$null
    if ($LASTEXITCODE -eq 0) {
        $version = ($phpVersion -split "`n")[0]
        Write-Host "PHP trouve: $version" -ForegroundColor Green
    } else {
        throw "PHP non trouve"
    }
} catch {
    Write-Host "ERREUR: PHP n'est pas installe ou pas dans le PATH" -ForegroundColor Red
    Write-Host "Veuillez installer PHP avant de continuer." -ForegroundColor Red
    exit 1
}

# Verification de Composer
Write-Host "Verification de Composer..." -ForegroundColor Yellow
try {
    $composerVersion = composer --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Composer trouve: $composerVersion" -ForegroundColor Green
    } else {
        throw "Composer non trouve"
    }
} catch {
    Write-Host "ERREUR: Composer n'est pas installe ou pas dans le PATH" -ForegroundColor Red
    Write-Host "Veuillez installer Composer avant de continuer." -ForegroundColor Red
    exit 1
}

# Configuration du projet
if ($ProjectPath -eq "") {
    $ProjectPath = Read-Host "Entrez le chemin du projet PHP a analyser (ou laissez vide pour exemple)"
    if ($ProjectPath -eq "") {
        $ProjectPath = Join-Path $PSScriptRoot "..\examples\sample-php-project"
        Write-Host "Utilisation du projet d'exemple: $ProjectPath" -ForegroundColor Cyan
    }
}

# Verification/creation du projet cible
if (!(Test-Path $ProjectPath)) {
    Write-Host "Le chemin $ProjectPath n'existe pas." -ForegroundColor Yellow
    $createExample = Read-Host "Voulez-vous creer un projet d'exemple ? (o/N)"
    if ($createExample -eq "o" -or $createExample -eq "O") {
        New-Item -ItemType Directory -Path $ProjectPath -Force | Out-Null
        Write-Host "Dossier cree: $ProjectPath" -ForegroundColor Green
    } else {
        Write-Host "Installation annulee." -ForegroundColor Red
        exit 1
    }
}

# Installation de Rector
Write-Host ""
Write-Host "Installation de Rector..." -ForegroundColor Yellow

if ($Global) {
    Write-Host "Installation globale de Rector..."
    composer global require rector/rector --with-all-dependencies
} else {
    Push-Location $ProjectPath
    try {
        # Verification si composer.json existe
        if (!(Test-Path "composer.json")) {
            Write-Host "Initialisation de Composer dans le projet..."
            composer init --no-interaction --name="analysis/project" --description="Projet d'analyse PHP"
        }
        
        # Installation de Rector
        if ($Force) {
            composer require rector/rector --dev --with-all-dependencies --ignore-platform-reqs
        } else {
            composer require rector/rector --dev --with-all-dependencies
        }
        
        Write-Host "Rector installe avec succes dans le projet." -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de l'installation: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    } finally {
        Pop-Location
    }
}

# Copie des configurations Rector
Write-Host ""
Write-Host "Configuration de Rector..." -ForegroundColor Yellow

$configSource = Join-Path $PSScriptRoot "..\config"
$configTarget = Join-Path $ProjectPath "rector-configs"

if (!(Test-Path $configTarget)) {
    New-Item -ItemType Directory -Path $configTarget -Force | Out-Null
}

# Copie des fichiers de configuration
$configFiles = @("rector-php81.php", "rector-php82.php", "rector-php84.php")
foreach ($configFile in $configFiles) {
    $sourcePath = Join-Path $configSource $configFile
    $targetPath = Join-Path $configTarget $configFile
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $targetPath -Force
        Write-Host "Configuration copiee: $configFile" -ForegroundColor Green
    }
}

# Creation du fichier rector.php par defaut
$defaultRectorConfig = Join-Path $ProjectPath "rector.php"
if (!(Test-Path $defaultRectorConfig) -or $Force) {
    $configContent = @"
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

return static function (RectorConfig `$rectorConfig): void {
    `$rectorConfig->paths([
        __DIR__ . '/src',
        __DIR__ . '/classes',
        __DIR__ . '/lib',
        __DIR__ . '/public',
        // Ajoutez vos dossiers ici
    ]);

    // Modernisation vers PHP 8.4
    `$rectorConfig->sets([
        LevelSetList::UP_TO_PHP_84,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
    ]);

    // Exclusions
    `$rectorConfig->skip([
        __DIR__ . '/vendor',
        __DIR__ . '/cache',
        __DIR__ . '/tmp',
    ]);
};
"@
    
    Set-Content -Path $defaultRectorConfig -Value $configContent -Encoding UTF8
    Write-Host "Configuration Rector creee: rector.php" -ForegroundColor Green
}

# Creation du dossier de sortie
$outputDir = Join-Path $ProjectPath "rector-output"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    Write-Host "Dossier de sortie cree: rector-output" -ForegroundColor Green
}

# Test d'installation
Write-Host ""
Write-Host "Test de l'installation..." -ForegroundColor Yellow

Push-Location $ProjectPath
try {
    if ($Global) {
        $testCommand = "rector --version"
    } else {
        $testCommand = "vendor\bin\rector --version"
    }
    
    $result = Invoke-Expression $testCommand 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Test reussi: $result" -ForegroundColor Green
    } else {
        Write-Host "ATTENTION: Test echoue, mais l'installation peut etre correcte." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Test impossible, mais l'installation peut etre correcte." -ForegroundColor Yellow
} finally {
    Pop-Location
}

# Fin
Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host "        INSTALLATION TERMINEE" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Projet configure: $ProjectPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Prochaines etapes:" -ForegroundColor Yellow
Write-Host "1. Modifier rector.php selon vos besoins"
Write-Host "2. Lancer: .\rector-analyze.ps1"
Write-Host "3. Consulter les rapports dans rector-output/"
Write-Host ""
Write-Host "Pour l'aide: .\rector-analyze.ps1 -Help"
