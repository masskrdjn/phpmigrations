# ==============================================================================
# Script de test et validation - Rector PHP Analysis Tools
# ==============================================================================

param(
    [switch]$Quick = $false,
    [switch]$Verbose = $false,
    [switch]$Help = $false
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

if ($Help) {
    Write-Host @"
RECTOR PHP ANALYSIS TOOLS - Tests et Validation

SYNOPSIS:
    .\test-installation.ps1 [-Quick] [-Verbose] [-Help]

DESCRIPTION:
    Teste l'installation et valide le fonctionnement des outils.

PARAMETRES:
    -Quick      Tests rapides uniquement
    -Verbose    Affichage détaillé
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
    $banner = "=" * 60
    Write-Host ""
    Write-Host $banner -ForegroundColor Blue
    Write-Host "  $Title" -ForegroundColor Blue
    Write-Host $banner -ForegroundColor Blue
}

function Write-TestResult {
    param([bool]$Success, [string]$Message)
    if ($Success) {
        Write-Host "[OK]   $Message" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $Message" -ForegroundColor Red
    }
}

function Test-Prerequisites {
    Write-TestHeader "Test des prérequis"

    $allGood = $true

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
    # NB: 'templates' a été retiré — il n'existe plus dans le projet.
    $requiredDirs  = @("scripts", "config", "examples", "docs", "logs")
    $requiredFiles = @(
        "rector-analyze.ps1",
        "analyze-rector-readable.ps1",
        "analyze-rector-detailed.ps1",
        "README.md",
        "LICENSE"
    )

    foreach ($dir in $requiredDirs) {
        if (Test-Path $dir) {
            Write-TestResult $true "Dossier '$dir' présent"
        } else {
            Write-TestResult $false "Dossier '$dir' manquant"
            $allGood = $false
        }
    }

    foreach ($file in $requiredFiles) {
        if (Test-Path $file) {
            Write-TestResult $true "Fichier '$file' présent"
        } else {
            Write-TestResult $false "Fichier '$file' manquant"
            $allGood = $false
        }
    }

    $scripts = Get-ChildItem "scripts\*.ps1" -ErrorAction SilentlyContinue
    if ($scripts.Count -gt 0) {
        Write-TestResult $true "$($scripts.Count) script(s) PowerShell dans scripts/"
        if ($Verbose) {
            foreach ($script in $scripts) {
                Write-Host "   - $($script.Name)" -ForegroundColor Gray
            }
        }
    } else {
        Write-TestResult $false "Aucun script PowerShell dans scripts/"
        $allGood = $false
    }

    return $allGood
}

function Test-Scripts {
    Write-TestHeader "Test des scripts PowerShell"

    $allGood = $true

    $scriptsToCheck = @(
        "rector-analyze.ps1",
        "analyze-rector-readable.ps1",
        "analyze-rector-detailed.ps1",
        "scripts\install-rector.ps1"
    )

    foreach ($scriptPath in $scriptsToCheck) {
        if (-not (Test-Path $scriptPath)) {
            Write-TestResult $false "Script $scriptPath manquant"
            $allGood = $false
            continue
        }
        try {
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content $scriptPath -Raw), [ref]$null
            )
            Write-TestResult $true "Script $(Split-Path $scriptPath -Leaf) - syntaxe OK"
        } catch {
            Write-TestResult $false "Erreur dans $(Split-Path $scriptPath -Leaf): $($_.Exception.Message)"
            $allGood = $false
        }
    }

    return $allGood
}

function Test-Encoding {
    Write-TestHeader "Test de l'encodage des scripts (UTF-8 BOM)"

    $allGood = $true
    $scripts = @(
        "rector-analyze.ps1",
        "analyze-rector-readable.ps1",
        "analyze-rector-detailed.ps1",
        "scripts\install-rector.ps1",
        "test-installation.ps1"
    )
    foreach ($s in $scripts) {
        if (-not (Test-Path $s)) { continue }
        $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $s).Path)
        # Vérifier la présence du BOM UTF-8 (EF BB BF)
        $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        if ($hasBom) {
            Write-TestResult $true "$s est en UTF-8 avec BOM"
        } else {
            Write-TestResult $false "$s n'a PAS de BOM UTF-8 (les accents seront cassés en PS 5.1)"
            $allGood = $false
        }
    }
    return $allGood
}

function Test-ExampleProject {
    Write-TestHeader "Test du projet d'exemple"

    $allGood = $true
    $examplePath = "examples\sample-php-project"

    if (!(Test-Path $examplePath)) {
        Write-TestResult $false "Projet d'exemple manquant"
        return $false
    }
    Write-TestResult $true "Projet d'exemple trouvé"

    $phpFiles = Get-ChildItem "$examplePath\src\*.php" -ErrorAction SilentlyContinue
    if (-not $phpFiles -or $phpFiles.Count -eq 0) {
        Write-TestResult $false "Aucun fichier PHP d'exemple trouvé"
        return $false
    }
    Write-TestResult $true "$($phpFiles.Count) fichier(s) PHP d'exemple"

    foreach ($phpFile in $phpFiles) {
        try {
            $null = php -l $phpFile.FullName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-TestResult $true "Syntaxe PHP OK : $($phpFile.Name)"
            } else {
                Write-TestResult $false "Erreur syntaxe PHP : $($phpFile.Name)"
                $allGood = $false
            }
        } catch {
            Write-TestResult $false "Impossible de tester $($phpFile.Name)"
            $allGood = $false
        }
    }

    return $allGood
}

function Test-FunctionalTest {
    Write-TestHeader "Test fonctionnel"

    if ($Quick) {
        Write-Host "[..] Tests fonctionnels ignorés (mode Quick)" -ForegroundColor Yellow
        return $true
    }

    $allGood = $true

    try {
        Write-Host "Exécution de l'aide du script principal..." -ForegroundColor Yellow
        $helpOutput = & ".\rector-analyze.ps1" -Help 2>&1
        if ($helpOutput -match "RECTOR PHP ANALYSIS TOOLS") {
            Write-TestResult $true "Aide du script principal fonctionnelle"
        } else {
            Write-TestResult $false "Aide du script principal défaillante"
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

    $totalTests  = $Results.Count
    $passedTests = ($Results.Values | Where-Object { $_ -eq $true }).Count
    $failedTests = $totalTests - $passedTests

    Write-Host "Total des tests : $totalTests" -ForegroundColor Cyan
    Write-Host "Tests réussis   : $passedTests" -ForegroundColor Green
    Write-Host "Tests échoués   : $failedTests" -ForegroundColor Red

    $percentage = [math]::Round(($passedTests / $totalTests) * 100, 1)
    $color = if ($percentage -ge 80) { "Green" } elseif ($percentage -ge 60) { "Yellow" } else { "Red" }
    Write-Host "Taux de réussite : $percentage%" -ForegroundColor $color

    Write-Host ""
    if ($failedTests -eq 0) {
        Write-Host "Tous les tests sont passés. L'installation est correcte." -ForegroundColor Green
        Write-Host "Vous pouvez maintenant utiliser : .\rector-analyze.ps1" -ForegroundColor Cyan
    } elseif ($failedTests -le 2) {
        Write-Host "Quelques problèmes mineurs détectés, mais l'outil devrait fonctionner." -ForegroundColor Yellow
    } else {
        Write-Host "Problèmes importants détectés. Veuillez corriger avant utilisation." -ForegroundColor Red
    }
}

# ==============================================================================
# SCRIPT PRINCIPAL
# ==============================================================================

Write-Host @"
RECTOR PHP ANALYSIS TOOLS - TESTS DE VALIDATION
==================================================
"@ -ForegroundColor Green

Write-Host "Mode      : $(if ($Quick) { 'Rapide' } else { 'Complet' })" -ForegroundColor Cyan
Write-Host "Verbosité : $(if ($Verbose) { 'Activée' } else { 'Standard' })" -ForegroundColor Cyan

$results = @{}

$results["Prerequisites"] = Test-Prerequisites
$results["Structure"]     = Test-ProjectStructure
$results["Scripts"]       = Test-Scripts
$results["Encoding"]      = Test-Encoding
$results["Examples"]      = Test-ExampleProject

if (!$Quick) {
    $results["Functional"] = Test-FunctionalTest
}

Show-Summary $results

Write-Host ""
Write-Host "Pour commencer à utiliser l'outil :" -ForegroundColor Yellow
Write-Host "  1. .\scripts\install-rector.ps1" -ForegroundColor Cyan
Write-Host "  2. .\rector-analyze.ps1" -ForegroundColor Cyan

exit $(if (($results.Values | Where-Object { $_ -eq $false }).Count -eq 0) { 0 } else { 1 })
