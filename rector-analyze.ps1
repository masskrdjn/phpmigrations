# ==============================================================================
# RECTOR PHP ANALYSIS TOOLS - Script Principal
# Version 2.0 - Interface interactive complete
# ==============================================================================

param(
    [string]$ProjectPath = "",
    [string]$ConfigFile = "",
    [string]$OutputFormat = "readable",
    [string]$OutputFile = "",
    [switch]$DryRun = $true,
    [switch]$Interactive = $true,
    [switch]$Help = $false
)

# =============================================================================
# FONCTIONS UTILITAIRES
# =============================================================================

function Show-Header {
    Clear-Host
    Write-Host @"
==========================================
   RECTOR PHP ANALYSIS TOOLS v2.0
==========================================
"@ -ForegroundColor Green
    Write-Host ""
}

function Show-Help {
    Write-Host @"
RECTOR PHP ANALYSIS TOOLS - Script Principal

SYNOPSIS:
    .\rector-analyze.ps1 [options]

OPTIONS:
    -ProjectPath <chemin>   Chemin du projet PHP a analyser
    -ConfigFile <fichier>   Fichier de configuration Rector specifique
    -OutputFormat <format>  Format de sortie (simple|readable|detailed|json)
    -OutputFile <fichier>   Fichier de sauvegarde du rapport
    -DryRun                 Mode dry-run (par defaut: true)
    -Interactive            Mode interactif (par defaut: true)
    -Help                   Affiche cette aide

EXEMPLES:
    .\rector-analyze.ps1
    .\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -OutputFormat detailed
    .\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -OutputFile "rapport.md" -DryRun:`$false

FORMATS DE SORTIE:
    simple     - Resume basique
    readable   - Rapport detaille lisible
    detailed   - Rapport exhaustif avec explications
    json       - Sortie JSON brute

"@ -ForegroundColor Cyan
}

function Get-ProjectPath {
    param([string]$CurrentPath)
    
    if ($CurrentPath -ne "" -and (Test-Path $CurrentPath)) {
        return $CurrentPath
    }
    
    Write-Host "Selection du projet PHP a analyser:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Projet actuel ($(Get-Location))"
    Write-Host "2. Parcourir..."
    Write-Host "3. Entrer un chemin manuellement"
    Write-Host "4. Utiliser l'exemple fourni"
    Write-Host ""
    
    do {
        $choice = Read-Host "Votre choix (1-4)"
        
        switch ($choice) {
            "1" { 
                return Get-Location 
            }
            "2" { 
                Add-Type -AssemblyName System.Windows.Forms
                $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
                $folderBrowser.Description = "Selectionnez le dossier du projet PHP"
                $folderBrowser.ShowNewFolderButton = $false
                
                if ($folderBrowser.ShowDialog() -eq "OK") {
                    return $folderBrowser.SelectedPath
                } else {
                    Write-Host "Selection annulee." -ForegroundColor Red
                    return ""
                }
            }
            "3" { 
                $path = Read-Host "Entrez le chemin complet du projet"
                if (Test-Path $path) {
                    return $path
                } else {
                    Write-Host "Chemin invalide: $path" -ForegroundColor Red
                    return ""
                }
            }
            "4" {
                $examplePath = Join-Path $PSScriptRoot "..\examples\sample-php-project"
                if (!(Test-Path $examplePath)) {
                    Write-Host "Creation du projet d'exemple..." -ForegroundColor Yellow
                    Create-ExampleProject $examplePath
                }
                return $examplePath
            }
            default { 
                Write-Host "Choix invalide. Veuillez entrer 1, 2, 3 ou 4." -ForegroundColor Red 
            }
        }
    } while ($true)
}

function Get-ConfigFile {
    param([string]$ProjectPath)
    
    Write-Host "Selection de la configuration Rector:" -ForegroundColor Yellow
    Write-Host ""
    
    # Recherche des configurations disponibles
    $configs = @()
    
    # Configuration par defaut du projet
    $defaultConfig = Join-Path $ProjectPath "rector.php"
    if (Test-Path $defaultConfig) {
        $configs += @{Path = $defaultConfig; Name = "Configuration par defaut (rector.php)"; Default = $true}
    }
    
    # Configurations du toolkit
    $toolkitConfigs = Join-Path $PSScriptRoot "..\config"
    if (Test-Path $toolkitConfigs) {
        Get-ChildItem "$toolkitConfigs\*.php" | ForEach-Object {
            $configs += @{Path = $_.FullName; Name = "Toolkit: $($_.BaseName)"; Default = $false}
        }
    }
    
    # Configurations du projet
    $projectConfigs = Join-Path $ProjectPath "rector-configs"
    if (Test-Path $projectConfigs) {
        Get-ChildItem "$projectConfigs\*.php" | ForEach-Object {
            $configs += @{Path = $_.FullName; Name = "Projet: $($_.BaseName)"; Default = $false}
        }
    }
    
    if ($configs.Count -eq 0) {
        Write-Host "Aucune configuration trouvee. Creation d'une configuration par defaut..." -ForegroundColor Yellow
        Create-DefaultRectorConfig $ProjectPath
        return Join-Path $ProjectPath "rector.php"
    }
    
    # Affichage des options
    for ($i = 0; $i -lt $configs.Count; $i++) {
        $marker = if ($configs[$i].Default) { " (recommande)" } else { "" }
        Write-Host "$($i + 1). $($configs[$i].Name)$marker"
    }
    Write-Host ""
    
    do {
        $choice = Read-Host "Votre choix (1-$($configs.Count))"
        $index = [int]$choice - 1
        
        if ($index -ge 0 -and $index -lt $configs.Count) {
            return $configs[$index].Path
        } else {
            Write-Host "Choix invalide." -ForegroundColor Red
        }
    } while ($true)
}

function Get-OutputFormat {
    Write-Host "Selection du format de rapport:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Simple - Resume rapide"
    Write-Host "2. Readable - Rapport detaille lisible (recommande)"
    Write-Host "3. Detailed - Rapport exhaustif avec explications"
    Write-Host "4. JSON - Sortie JSON brute"
    Write-Host ""
    
    do {
        $choice = Read-Host "Votre choix (1-4)"
        
        switch ($choice) {
            "1" { return "simple" }
            "2" { return "readable" }
            "3" { return "detailed" }
            "4" { return "json" }
            default { Write-Host "Choix invalide." -ForegroundColor Red }
        }
    } while ($true)
}

function Run-RectorAnalysis {
    param(
        [string]$ProjectPath,
        [string]$ConfigFile,
        [bool]$DryRun
    )
    
    Write-Host "Execution de l'analyse Rector..." -ForegroundColor Yellow
    Write-Host "Projet: $ProjectPath" -ForegroundColor Cyan
    Write-Host "Configuration: $ConfigFile" -ForegroundColor Cyan
    Write-Host "Mode: $(if ($DryRun) { 'Dry-run (simulation)' } else { 'Application des changements' })" -ForegroundColor Cyan
    Write-Host ""
    
    Push-Location $ProjectPath
    try {
        # Construction de la commande
        $rectorBin = if (Test-Path "vendor\bin\rector.bat") {
            "vendor\bin\rector.bat"
        } elseif (Test-Path "vendor\bin\rector") {
            "vendor\bin\rector"
        } else {
            "rector"
        }
        
        $arguments = @("process")
        if ($DryRun) {
            $arguments += "--dry-run"
        }
        $arguments += @("--output-format=json", "--config=$ConfigFile")
        
        Write-Host "Commande: $rectorBin $($arguments -join ' ')" -ForegroundColor Gray
        Write-Host ""
        
        # Execution
        $output = & $rectorBin $arguments 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-Host "Analyse terminee avec succes." -ForegroundColor Green
            return $output -join "`n"
        } else {
            Write-Host "Analyse terminee avec des avertissements (code: $exitCode)." -ForegroundColor Yellow
            return $output -join "`n"
        }
        
    } catch {
        Write-Host "Erreur lors de l'analyse: $($_.Exception.Message)" -ForegroundColor Red
        throw
    } finally {
        Pop-Location
    }
}

function Format-Output {
    param(
        [string]$JsonOutput,
        [string]$Format,
        [string]$ProjectPath
    )
    
    switch ($Format) {
        "simple" {
            return Format-SimpleOutput $JsonOutput $ProjectPath
        }
        "readable" {
            return Format-ReadableOutput $JsonOutput $ProjectPath
        }
        "detailed" {
            return Format-DetailedOutput $JsonOutput $ProjectPath
        }
        "json" {
            return $JsonOutput
        }
        default {
            return Format-ReadableOutput $JsonOutput $ProjectPath
        }
    }
}

function Format-SimpleOutput {
    param([string]$JsonOutput, [string]$ProjectPath)
    
    try {
        $data = $JsonOutput | ConvertFrom-Json -ErrorAction Stop
        
        $output = @"
# Analyse Rector - $(Split-Path $ProjectPath -Leaf)

**Rapport genere le**: $(Get-Date -Format "dd/MM/yyyy HH:mm")
**Projet**: $ProjectPath

## Resultats

"@
        
        if ($data.totals) {
            $output += @"
- **Fichiers analyses**: $($data.totals.changed_files + $data.totals.unchanged_files)
- **Fichiers modifies**: $($data.totals.changed_files)
- **Changements appliques**: $($data.totals.applied_rectors)

"@
        }
        
        if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
            $output += "## Fichiers impactes`n`n"
            foreach ($file in $data.file_diffs) {
                $relativePath = $file.file -replace [regex]::Escape($ProjectPath), ""
                $output += "- ``$relativePath`` ($($file.applied_rectors.Count) changements)`n"
            }
        } else {
            $output += "**Aucun changement detecte** - Votre code est deja optimise !"
        }
        
        return $output
        
    } catch {
        return @"
# Erreur d'analyse

Impossible de parser la sortie JSON:
``````
$JsonOutput
``````
"@
    }
}

function Format-ReadableOutput {
    param([string]$JsonOutput, [string]$ProjectPath)
    
    # Utilisation du script existant
    $scriptPath = Join-Path $PSScriptRoot "analyze-rector-readable.ps1"
    if (Test-Path $scriptPath) {
        try {
            $tempFile = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $tempFile -Value $JsonOutput -Encoding UTF8
            
            $result = & $scriptPath -JsonFile $tempFile -ProjectPath $ProjectPath
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            
            return $result
        } catch {
            return "Erreur lors du formatage: $($_.Exception.Message)"
        }
    } else {
        return Format-SimpleOutput $JsonOutput $ProjectPath
    }
}

function Format-DetailedOutput {
    param([string]$JsonOutput, [string]$ProjectPath)
    
    # Utilisation du script existant
    $scriptPath = Join-Path $PSScriptRoot "analyze-rector-detailed.ps1"
    if (Test-Path $scriptPath) {
        try {
            $tempFile = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $tempFile -Value $JsonOutput -Encoding UTF8
            
            $result = & $scriptPath -JsonFile $tempFile -ProjectPath $ProjectPath
            Remove-Item $tempFile -ErrorAction SilentlyContinue
            
            return $result
        } catch {
            return "Erreur lors du formatage: $($_.Exception.Message)"
        }
    } else {
        return Format-ReadableOutput $JsonOutput $ProjectPath
    }
}

function Save-Output {
    param(
        [string]$Content,
        [string]$OutputFile,
        [string]$ProjectPath
    )
    
    if ($OutputFile -eq "") {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $outputDir = Join-Path $ProjectPath "rector-output"
        if (!(Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        $OutputFile = Join-Path $outputDir "rector-analysis_$timestamp.md"
    }
    
    Set-Content -Path $OutputFile -Value $Content -Encoding UTF8
    Write-Host "Rapport sauvegarde: $OutputFile" -ForegroundColor Green
    
    return $OutputFile
}

function Create-DefaultRectorConfig {
    param([string]$ProjectPath)
    
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
    
    $configFile = Join-Path $ProjectPath "rector.php"
    Set-Content -Path $configFile -Value $configContent -Encoding UTF8
    Write-Host "Configuration par defaut creee: $configFile" -ForegroundColor Green
}

function Create-ExampleProject {
    param([string]$ExamplePath)
    
    New-Item -ItemType Directory -Path $ExamplePath -Force | Out-Null
    New-Item -ItemType Directory -Path "$ExamplePath\src" -Force | Out-Null
    
    # Exemple de code PHP ancien
    $exampleCode = @"
<?php

class UserManager 
{
    private `$users;
    
    public function __construct() 
    {
        `$this->users = array();
    }
    
    public function addUser(`$name, `$email = null) 
    {
        if (`$name != null && `$name != '') {
            `$user = array('name' => `$name, 'email' => `$email);
            array_push(`$this->users, `$user);
            return true;
        }
        return false;
    }
    
    public function getUsers() 
    {
        return `$this->users;
    }
}
"@
    
    Set-Content -Path "$ExamplePath\src\UserManager.php" -Value $exampleCode -Encoding UTF8
    Write-Host "Projet d'exemple cree: $ExamplePath" -ForegroundColor Green
}

# =============================================================================
# SCRIPT PRINCIPAL
# =============================================================================

if ($Help) {
    Show-Help
    exit 0
}

Show-Header

if ($Interactive) {
    Write-Host "Mode interactif - Configuration de l'analyse" -ForegroundColor Cyan
    Write-Host ""
    
    # Selection du projet
    $ProjectPath = Get-ProjectPath $ProjectPath
    if ($ProjectPath -eq "") {
        Write-Host "Aucun projet selectionne. Arret." -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    
    # Selection de la configuration
    if ($ConfigFile -eq "") {
        $ConfigFile = Get-ConfigFile $ProjectPath
    }
    
    Write-Host ""
    
    # Selection du format
    if ($OutputFormat -eq "readable") {
        $OutputFormat = Get-OutputFormat
    }
    
    Write-Host ""
    
    # Mode dry-run
    $dryRunChoice = Read-Host "Mode dry-run (simulation uniquement) ? (O/n)"
    $DryRun = ($dryRunChoice -ne "n" -and $dryRunChoice -ne "N")
    
    Write-Host ""
    
    # Fichier de sortie
    if ($OutputFile -eq "") {
        $saveFile = Read-Host "Sauvegarder le rapport dans un fichier ? (o/N)"
        if ($saveFile -eq "o" -or $saveFile -eq "O") {
            $OutputFile = Read-Host "Nom du fichier (laissez vide pour auto-genere)"
        }
    }
    
    Write-Host ""
    Write-Host "Configuration terminee. Demarrage de l'analyse..." -ForegroundColor Green
    Write-Host ""
}

# Validation des parametres
if (!(Test-Path $ProjectPath)) {
    Write-Host "Erreur: Le projet '$ProjectPath' n'existe pas." -ForegroundColor Red
    exit 1
}

if ($ConfigFile -ne "" -and !(Test-Path $ConfigFile)) {
    Write-Host "Erreur: Le fichier de configuration '$ConfigFile' n'existe pas." -ForegroundColor Red
    exit 1
}

# Execution de l'analyse
try {
    $jsonOutput = Run-RectorAnalysis $ProjectPath $ConfigFile $DryRun
    $formattedOutput = Format-Output $jsonOutput $OutputFormat $ProjectPath
    
    # Affichage du resultat
    Write-Host $formattedOutput
    
    # Sauvegarde si demandee
    if ($OutputFile -ne "" -or ($Interactive -and $saveFile -eq "o")) {
        $savedFile = Save-Output $formattedOutput $OutputFile $ProjectPath
        
        if ($Interactive) {
            Write-Host ""
            $openFile = Read-Host "Ouvrir le fichier ? (o/N)"
            if ($openFile -eq "o" -or $openFile -eq "O") {
                Start-Process $savedFile
            }
        }
    }
    
} catch {
    Write-Host "Erreur lors de l'analyse: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($Interactive) {
    Write-Host ""
    Write-Host "Analyse terminee. Appuyez sur une touche pour continuer..." -ForegroundColor Gray
    $Host.UI.RawUI.ReadKey() | Out-Null
}
