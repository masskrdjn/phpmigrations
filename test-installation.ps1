# ==============================================================================
# Script de test et validation - Rector PHP Analysis Tools
# ==============================================================================

param(
    [switch]$Quick = $false,
    [switch]$Verbose = $false,
    [switch]$Help = $false
)

if ($Help) {
    Write-Host @"
RECTOR PHP ANALYSIS TOOLS - Tests et Validation

SYNOPSIS:
    .\test-installation.ps1 [-Quick] [-Verbose] [-Help]

DESCRIPTION:
    Teste l'installation et valide le fonctionnement des outils.

PARAMETRES:
    -Quick      Tests rapides uniquement
    -Verbose    Affichage detaille
    -Help       Affiche cette aide

EXEMPLES:
    .\test-installation.ps1
    .\test-installation.ps1 -Quick -Verbose

"@ -ForegroundColor Cyan
    exit 0
}

# ==============================================================================
# FONCTIONS DE TEST
# ==============================================================================

function Write-TestHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 60 -ForegroundColor Blue
    Write-Host "  $Title" -ForegroundColor Blue
    Write-Host "=" * 60 -ForegroundColor Blue
}

function Write-TestResult {
    param([bool]$Success, [string]$Message)
    if ($Success) {
        Write-Host "✅ $Message" -ForegroundColor Green
    } else {
        Write-Host "❌ $Message" -ForegroundColor Red
    }
}

function Test-Prerequisites {
    Write-TestHeader "Test des prérequis"
    
    $allGood = $true
    
    # Test PowerShell
    try {
        $psVersion = $PSVersionTable.PSVersion
        Write-TestResult $true "PowerShell $psVersion détecté"
        if ($Verbose) {
            Write-Host "   Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Gray
        }
    } catch {
        Write-TestResult $false "PowerShell non détecté"
        $allGood = $false
    }
    
    # Test PHP
    try {
        $phpVersion = php -v 2>$null
        if ($LASTEXITCODE -eq 0) {
            $version = ($phpVersion -split "`n")[0]
            Write-TestResult $true "PHP détecté: $version"
        } else {
            throw "PHP non trouvé"
        }
    } catch {
        Write-TestResult $false "PHP non installé ou pas dans le PATH"
        $allGood = $false
    }
    
    # Test Composer
    try {
        $composerVersion = composer --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult $true "Composer détecté: $composerVersion"
        } else {
            throw "Composer non trouvé"
        }
    } catch {
        Write-TestResult $false "Composer non installé ou pas dans le PATH"
        $allGood = $false
    }
    
    return $allGood
}

function Test-ProjectStructure {
    Write-TestHeader "Test de la structure du projet"
    
    $allGood = $true
    $requiredDirs = @("scripts", "config", "examples", "docs", "templates")
    $requiredFiles = @("rector-analyze.ps1", "README.md", "LICENSE")
    
    # Test des dossiers
    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            Write-TestResult $true "Dossier '$dir' présent"
        } else {
            Write-TestResult $false "Dossier '$dir' manquant"
            $allGood = $false
        }
    }
    
    # Test des fichiers
    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-TestResult $true "Fichier '$file' présent"
        } else {
            Write-TestResult $false "Fichier '$file' manquant"
            $allGood = $false
        }
    }
    
    # Test des scripts
    $scripts = Get-ChildItem "scripts\*.ps1" -ErrorAction SilentlyContinue
    if ($scripts.Count -gt 0) {
        Write-TestResult $true "$($scripts.Count) scripts PowerShell trouvés"
        if ($Verbose) {
            foreach ($script in $scripts) {
                Write-Host "   - $($script.Name)" -ForegroundColor Gray
            }
        }
    } else {
        Write-TestResult $false "Aucun script PowerShell trouvé"
        $allGood = $false
    }
    
    return $allGood
}

function Test-Scripts {
    Write-TestHeader "Test des scripts PowerShell"
    
    $allGood = $true
    
    # Test syntaxe du script principal
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize(
            (Get-Content "rector-analyze.ps1" -Raw), [ref]$null
        )
        Write-TestResult $true "Syntaxe du script principal valide"
    } catch {
        Write-TestResult $false "Erreur de syntaxe dans rector-analyze.ps1: $($_.Exception.Message)"
        $allGood = $false
    }
    
    # Test des scripts individuels
    $scripts = @(
        "scripts\install-rector.ps1",
        "scripts\analyze-rector-simple.ps1",
        "scripts\analyze-rector-readable.ps1",
        "scripts\analyze-rector-detailed.ps1"
    )
    
    foreach ($scriptPath in $scripts) {
        if (Test-Path $scriptPath) {
            try {
                $null = [System.Management.Automation.PSParser]::Tokenize(
                    (Get-Content $scriptPath -Raw), [ref]$null
                )
                Write-TestResult $true "Script $(Split-Path $scriptPath -Leaf) - syntaxe OK"
            } catch {
                Write-TestResult $false "Erreur dans $(Split-Path $scriptPath -Leaf): $($_.Exception.Message)"
                $allGood = $false
            }
        } else {
            Write-TestResult $false "Script $scriptPath manquant"
            $allGood = $false
        }
    }
    
    return $allGood
}

function Test-ExampleProject {
    Write-TestHeader "Test du projet d'exemple"
    
    $allGood = $true
    $examplePath = "examples\sample-php-project"
    
    if (Test-Path $examplePath) {
        Write-TestResult $true "Projet d'exemple trouvé"
        
        # Test des fichiers PHP
        $phpFiles = Get-ChildItem "$examplePath\src\*.php" -ErrorAction SilentlyContinue
        if ($phpFiles.Count -gt 0) {
            Write-TestResult $true "$($phpFiles.Count) fichiers PHP d'exemple"
            
            # Test syntaxe PHP
            foreach ($phpFile in $phpFiles) {
                try {
                    $syntax = php -l $phpFile.FullName 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-TestResult $true "Syntaxe PHP OK: $($phpFile.Name)"
                    } else {
                        Write-TestResult $false "Erreur syntaxe PHP: $($phpFile.Name)"
                        $allGood = $false
                    }
                } catch {
                    Write-TestResult $false "Impossible de tester $($phpFile.Name)"
                    $allGood = $false
                }
            }
        } else {
            Write-TestResult $false "Aucun fichier PHP d'exemple trouvé"
            $allGood = $false
        }
    } else {
        Write-TestResult $false "Projet d'exemple manquant"
        $allGood = $false
    }
    
    return $allGood
}

function Test-FunctionalTest {
    Write-TestHeader "Test fonctionnel"
    
    if ($Quick) {
        Write-Host "⏩ Tests fonctionnels ignorés (mode Quick)" -ForegroundColor Yellow
        return $true
    }
    
    $allGood = $true
    $examplePath = "examples\sample-php-project"
    
    if (!(Test-Path $examplePath)) {
        Write-TestResult $false "Projet d'exemple nécessaire pour les tests fonctionnels"
        return $false
    }
    
    try {
        Write-Host "Exécution du script principal..." -ForegroundColor Yellow
        
        # Test avec aide
        $helpOutput = & ".\rector-analyze.ps1" -Help 2>&1
        if ($helpOutput -match "RECTOR PHP ANALYSIS TOOLS") {
            Write-TestResult $true "Aide du script principal fonctionnelle"
        } else {
            Write-TestResult $false "Aide du script principal défaillante"
            $allGood = $false
        }
        
        # Test script simple
        Write-Host "Test du script d'analyse simple..." -ForegroundColor Yellow
        $simpleOutput = & ".\scripts\analyze-rector-simple.ps1" -Help 2>&1
        if ($simpleOutput -match "RECTOR ANALYSIS") {
            Write-TestResult $true "Script d'analyse simple fonctionnel"
        } else {
            Write-TestResult $false "Script d'analyse simple défaillant"
            $allGood = $false
        }
        
    } catch {
        Write-TestResult $false "Erreur lors des tests fonctionnels: $($_.Exception.Message)"
        $allGood = $false
    }
    
    return $allGood
}

function Show-Summary {
    param([hashtable]$Results)
    
    Write-TestHeader "Résumé des tests"
    
    $totalTests = $Results.Count
    $passedTests = ($Results.Values | Where-Object { $_ -eq $true }).Count
    $failedTests = $totalTests - $passedTests
    
    Write-Host "Total des tests: $totalTests" -ForegroundColor Cyan
    Write-Host "Tests réussis:   $passedTests" -ForegroundColor Green
    Write-Host "Tests échoués:   $failedTests" -ForegroundColor Red
    
    $percentage = [math]::Round(($passedTests / $totalTests) * 100, 1)
    Write-Host "Taux de réussite: $percentage%" -ForegroundColor $(if($percentage -ge 80) {"Green"} elseif($percentage -ge 60) {"Yellow"} else {"Red"})
    
    Write-Host ""
    if ($failedTests -eq 0) {
        Write-Host "🎉 Tous les tests sont passés ! L'installation est correcte." -ForegroundColor Green
        Write-Host "Vous pouvez maintenant utiliser: .\rector-analyze.ps1" -ForegroundColor Cyan
    } elseif ($failedTests -le 2) {
        Write-Host "⚠️  Quelques problèmes mineurs détectés, mais l'outil devrait fonctionner." -ForegroundColor Yellow
    } else {
        Write-Host "❌ Problèmes importants détectés. Veuillez corriger avant utilisation." -ForegroundColor Red
    }
}

# ==============================================================================
# SCRIPT PRINCIPAL
# ==============================================================================

Write-Host @"
🧪 RECTOR PHP ANALYSIS TOOLS - TESTS DE VALIDATION
==================================================
"@ -ForegroundColor Green

Write-Host "Mode: $(if($Quick) {"Rapide"} else {"Complet"})" -ForegroundColor Cyan
Write-Host "Verbosité: $(if($Verbose) {"Activée"} else {"Standard"})" -ForegroundColor Cyan

$results = @{}

# Exécution des tests
$results["Prerequisites"] = Test-Prerequisites
$results["Structure"] = Test-ProjectStructure
$results["Scripts"] = Test-Scripts
$results["Examples"] = Test-ExampleProject

if (!$Quick) {
    $results["Functional"] = Test-FunctionalTest
}

# Affichage du résumé
Show-Summary $results

Write-Host ""
Write-Host "Pour commencer à utiliser l'outil:" -ForegroundColor Yellow
Write-Host "1. .\scripts\install-rector.ps1" -ForegroundColor Cyan
Write-Host "2. .\rector-analyze.ps1" -ForegroundColor Cyan

exit $(if(($results.Values | Where-Object { $_ -eq $false }).Count -eq 0) {0} else {1})
