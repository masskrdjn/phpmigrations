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
                Write-Host "Parcours des dossiers disponibles..." -ForegroundColor Yellow
                try {
                    # Méthode alternative plus robuste
                    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
                    Write-Host ""
                    Write-Host "Lecteurs disponibles:" -ForegroundColor Cyan
                    for ($i = 0; $i -lt $drives.Count; $i++) {
                        $drive = $drives[$i]
                        $freeSpace = [math]::Round($drive.Free / 1GB, 1)
                        Write-Host "$($i + 1). $($drive.Name):\ ($freeSpace GB libre)"
                    }
                    Write-Host ""
                    
                    do {
                        $driveChoice = Read-Host "Choisissez un lecteur (1-$($drives.Count)) ou 'a' pour annuler"
                        if ($driveChoice -eq "a") {
                            Write-Host "Selection annulee." -ForegroundColor Red
                            return ""
                        }
                        
                        $driveIndex = [int]$driveChoice - 1
                        if ($driveIndex -ge 0 -and $driveIndex -lt $drives.Count) {
                            $selectedDrive = $drives[$driveIndex].Name + ":\"
                            break
                        } else {
                            Write-Host "Choix invalide." -ForegroundColor Red
                        }
                    } while ($true)
                    
                    # Demander le chemin manuel à partir du lecteur sélectionné
                    Write-Host "Lecteur sélectionné: $selectedDrive" -ForegroundColor Green
                    $customPath = Read-Host "Entrez le chemin à partir de $selectedDrive (ex: laragon\www\monprojet)"
                    $fullPath = Join-Path $selectedDrive $customPath
                    
                    if (Test-Path $fullPath) {
                        Write-Host "Chemin validé: $fullPath" -ForegroundColor Green
                        return $fullPath
                    } else {
                        Write-Host "Chemin invalide: $fullPath" -ForegroundColor Red
                        Write-Host "Voulez-vous créer ce dossier? (o/N)" -ForegroundColor Yellow
                        $create = Read-Host
                        if ($create -eq "o" -or $create -eq "O") {
                            try {
                                New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
                                Write-Host "Dossier créé: $fullPath" -ForegroundColor Green
                                return $fullPath
                            } catch {
                                Write-Host "Impossible de créer le dossier: $($_.Exception.Message)" -ForegroundColor Red
                                return ""
                            }
                        } else {
                            return ""
                        }
                    }
                } catch {
                    Write-Host "Erreur lors du parcours: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host "Utilisation de la méthode manuelle..." -ForegroundColor Yellow
                    $path = Read-Host "Entrez le chemin complet du projet"
                    if (Test-Path $path) {
                        return $path
                    } else {
                        Write-Host "Chemin invalide: $path" -ForegroundColor Red
                        return ""
                    }
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

function Resolve-ConfigFile {
    param(
        [string]$ConfigFile,
        [string]$ProjectPath = ""
    )
    
    # Si le fichier existe tel quel, le retourner
    if ($ConfigFile -ne "" -and (Test-Path $ConfigFile -PathType Leaf)) {
        return (Resolve-Path $ConfigFile).Path
    }
    
    # Liste des emplacements possibles a verifier
    $searchPaths = @()
    
    # 1. Dossier config du toolkit
    $searchPaths += Join-Path $PSScriptRoot "config\$ConfigFile"
    
    # 2. Dossier config parent (si script dans sous-dossier)
    $searchPaths += Join-Path (Split-Path $PSScriptRoot -Parent) "config\$ConfigFile"
    
    # 3. Dossier rector-configs du projet
    if ($ProjectPath -ne "") {
        $searchPaths += Join-Path $ProjectPath "rector-configs\$ConfigFile"
        $searchPaths += Join-Path $ProjectPath $ConfigFile
    }
    
    # 4. Chemin relatif depuis le dossier courant
    $searchPaths += Join-Path (Get-Location) $ConfigFile
    
    # 5. Avec le prefixe "rector-" si non present
    if (-not $ConfigFile.StartsWith("rector-")) {
        $searchPaths += Join-Path $PSScriptRoot "config\rector-$ConfigFile"
        $searchPaths += Join-Path (Split-Path $PSScriptRoot -Parent) "config\rector-$ConfigFile"
    }
    
    # Rechercher dans tous les emplacements
    foreach ($path in $searchPaths) {
        if (Test-Path $path -PathType Leaf) {
            return (Resolve-Path $path).Path
        }
    }
    
    # Non trouve - retourner le chemin original
    return $ConfigFile
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
        # Construction de la commande - Chercher Rector dans plusieurs emplacements
        $rectorBin = $null
        
        # 1. Dans le projet analysé
        if (Test-Path "vendor\bin\rector.bat") {
            $rectorBin = "vendor\bin\rector.bat"
        } elseif (Test-Path "vendor\bin\rector") {
            $rectorBin = "vendor\bin\rector"
        }
        
        # 2. Dans le projet d'exemples (fallback)
        if (-not $rectorBin) {
            $exampleProject = Join-Path $PSScriptRoot "examples\sample-php-project"
            if (Test-Path (Join-Path $exampleProject "vendor\bin\rector.bat")) {
                $rectorBin = Join-Path $exampleProject "vendor\bin\rector.bat"
            } elseif (Test-Path (Join-Path $exampleProject "vendor\bin\rector")) {
                $rectorBin = Join-Path $exampleProject "vendor\bin\rector"
            }
        }
        
        # 3. Rector global (dernière option)
        if (-not $rectorBin) {
            $globalRector = Get-Command rector -ErrorAction SilentlyContinue
            if ($globalRector) {
                $rectorBin = "rector"
            }
        }
        
        # 4. Si aucun Rector trouvé, installer dans le projet d'exemples
        if (-not $rectorBin) {
            Write-Host "Rector non trouvé. Installation en cours..." -ForegroundColor Yellow
            $installScript = Join-Path $PSScriptRoot "scripts\install-rector.ps1"
            if (Test-Path $installScript) {
                & $installScript
                $exampleProject = Join-Path $PSScriptRoot "examples\sample-php-project"
                if (Test-Path (Join-Path $exampleProject "vendor\bin\rector.bat")) {
                    $rectorBin = Join-Path $exampleProject "vendor\bin\rector.bat"
                }
            }
            
            if (-not $rectorBin) {
                throw "Rector n'a pas pu être installé ou trouvé. Veuillez l'installer manuellement."
            }
        }
        
        # Préparer les arguments et les chemins
        $arguments = @("process", ".")  # Analyser le dossier courant
        if ($DryRun) {
            $arguments += "--dry-run"
        }
        
        # Utiliser le chemin de configuration (déjà résolu par Resolve-ConfigFile)
        $configPath = $ConfigFile
        # Si le chemin n'est pas absolu, essayer de le résoudre
        if (-not ([System.IO.Path]::IsPathRooted($configPath))) {
            $resolvedPath = Resolve-ConfigFile -ConfigFile $ConfigFile -ProjectPath $ProjectPath
            if (Test-Path $resolvedPath -PathType Leaf) {
                $configPath = $resolvedPath
            }
        }
        
        $arguments += @("--output-format=json", "--config=$configPath")
        
        Write-Host "Commande: $rectorBin $($arguments -join ' ')" -ForegroundColor Gray
        Write-Host "Configuration: $configPath" -ForegroundColor Gray
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
        # Nettoyer la sortie - supprimer les warnings PHP et ne garder que le JSON
        $lines = $JsonOutput -split "`n"
        $jsonStart = -1
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].TrimStart().StartsWith("{")) {
                $jsonStart = $i
                break
            }
        }
        
        if ($jsonStart -ge 0) {
            $cleanJson = ($lines[$jsonStart..($lines.Count-1)] -join "`n").Trim()
            $data = $cleanJson | ConvertFrom-Json -ErrorAction Stop
        } else {
            throw "Aucun JSON valide trouvé dans la sortie"
        }
        
        $output = @"
# Analyse Rector - $(Split-Path $ProjectPath -Leaf)

**Rapport genere le**: $(Get-Date -Format "dd/MM/yyyy HH:mm")
**Projet**: $ProjectPath

## Resultats

"@
        
        if ($data.totals) {
            $changedFiles = if ($data.totals.changed_files) { $data.totals.changed_files } else { 0 }
            $errors = if ($data.totals.errors) { $data.totals.errors } else { 0 }
            
            $output += @"
- **Fichiers modifies**: $changedFiles
- **Erreurs detectees**: $errors
- **Statut**: $(if ($changedFiles -gt 0) { "Ameliorations possibles" } else { "Code deja moderne" })

"@
        }
        
        if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
            $output += "## Fichiers impactes`n`n"
            foreach ($file in $data.file_diffs) {
                $fileName = Split-Path $file.file -Leaf
                $rectorsApplied = $file.applied_rectors.Count
                $output += "- **``$fileName``** ($rectorsApplied changements appliques)`n"
                
                # Afficher les types de changements
                $rectorTypes = @()
                foreach ($rector in $file.applied_rectors) {
                    $rectorName = ($rector -split '\\')[-1] -replace 'Rector$', ''
                    $rectorTypes += $rectorName
                }
                if ($rectorTypes.Count -gt 0) {
                    $output += "  - Types: " + ($rectorTypes -join ", ") + "`n"
                }
            }
            $output += "`n"
        } else {
            $output += "## Aucun changement detecte`n`n**Votre code est deja moderne !**`n"
        }
        
        return $output
        
    } catch {
        return @"
# Erreur d'analyse

Impossible de parser la sortie JSON. Voici la sortie brute :

```
$JsonOutput
```
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

# Resolution intelligente du chemin du fichier de configuration
if ($ConfigFile -ne "") {
    $resolvedConfig = Resolve-ConfigFile -ConfigFile $ConfigFile -ProjectPath $ProjectPath
    if (!(Test-Path $resolvedConfig -PathType Leaf)) {
        Write-Host "Erreur: Le fichier de configuration '$ConfigFile' n'existe pas." -ForegroundColor Red
        Write-Host "Emplacements recherches:" -ForegroundColor Yellow
        Write-Host "  - $ConfigFile" -ForegroundColor Gray
        Write-Host "  - $(Join-Path $PSScriptRoot "config\$ConfigFile")" -ForegroundColor Gray
        if ($ProjectPath -ne "") {
            Write-Host "  - $(Join-Path $ProjectPath "rector-configs\$ConfigFile")" -ForegroundColor Gray
        }
        exit 1
    }
    $ConfigFile = $resolvedConfig
    Write-Host "Configuration utilisee: $ConfigFile" -ForegroundColor Cyan
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
