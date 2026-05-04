# ==============================================================================
# RECTOR PHP ANALYSIS TOOLS - Script Principal
# Version 2.1 - Interface interactive complète
# ==============================================================================

param(
    [string]$ProjectPath = "",
    [string]$ConfigFile = "",
    [string]$PhpVersion = "",
    [string[]]$ExtraSets = @(),
    [switch]$UseRawConfig = $false,
    [string]$OutputFormat = "readable",
    [string]$OutputFile = "",
    [switch]$DryRun = $true,
    [switch]$Interactive = $true,
    [switch]$Help = $false,
    [switch]$ShowHistory = $false,
    [int]$HistoryCount = 10,
    [switch]$ShowLogs = $false
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"

# =============================================================================
# CONSTANTES & ÉTAT GLOBAL
# =============================================================================

$script:LogDirectory = Join-Path $PSScriptRoot "logs"
$script:LogFile = Join-Path $script:LogDirectory "rector-analysis.log"
$script:AnalysisHistoryFile = Join-Path $script:LogDirectory "analysis-history.json"
$script:SettingsFile = Join-Path $script:LogDirectory "user-settings.json"
$script:TempDir = Join-Path $PSScriptRoot "temp"

$script:TempDriveLetter = $null
$script:OriginalProjectPath = $null

# Versions PHP supportées (pour le menu et la validation)
$script:SupportedPhpVersions = @("70", "71", "72", "73", "74", "80", "81", "82", "83", "84")

# Sets Rector additionnels disponibles, avec descriptions FR
$script:AvailableSets = [ordered]@{
    "CODE_QUALITY"      = "Qualité du code (recommandé)"
    "DEAD_CODE"         = "Suppression du code mort (recommandé)"
    "EARLY_RETURN"      = "Retours anticipés"
    "TYPE_DECLARATION"  = "Déclarations de types"
    "PRIVATIZATION"     = "Encapsulation (private/protected)"
    "INSTANCEOF"        = "Optimisation des instanceof"
    "STRICT_BOOLEANS"   = "Comparaisons booléennes strictes"
    "NAMING"            = "Renommages cohérents"
    "CODING_STYLE"      = "Style de code"
}

# Sets sélectionnés par défaut quand l'utilisateur ne précise rien
$script:DefaultSets = @("CODE_QUALITY", "DEAD_CODE", "EARLY_RETURN", "TYPE_DECLARATION")

# =============================================================================
# UTILITAIRES BAS NIVEAU
# =============================================================================

function Write-Utf8File {
    param([string]$Path, [string]$Content, [bool]$WithBom = $false)
    $encoding = New-Object System.Text.UTF8Encoding $WithBom
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Make-Banner {
    param([string]$Char = "=", [int]$Length = 80)
    return ($Char * $Length)
}

# =============================================================================
# GESTION DES CHEMINS UNC
# =============================================================================

function Use-UNCPath {
    <#
    .SYNOPSIS
        Si $Path est UNC (\\server\share), crée un lecteur temporaire via subst
        et renvoie une lettre de lecteur. Sinon renvoie $Path inchangé.
    #>
    param([string]$Path)

    if ($Path -notmatch '^\\\\' -and $Path -notmatch '^//') {
        return $Path
    }

    Write-Host "Chemin UNC détecté: $Path" -ForegroundColor Yellow
    Write-Host "Création d'un lecteur temporaire (subst)..." -ForegroundColor Yellow

    $availableLetters = @('Z','Y','X','W','V','U','T','S','R','Q','P','O','N','M')
    $usedLetters = (Get-PSDrive -PSProvider FileSystem).Name

    foreach ($letter in $availableLetters) {
        if ($letter -in $usedLetters) { continue }
        try {
            $driveLetter = "${letter}:"
            $null = & subst $driveLetter $Path 2>&1
            if ($LASTEXITCODE -eq 0 -or (Test-Path $driveLetter)) {
                $script:TempDriveLetter = $letter
                $script:OriginalProjectPath = $Path
                $newPath = "${letter}:\"
                Write-Host "Lecteur temporaire: $newPath -> $Path" -ForegroundColor Green
                return $newPath
            }
        } catch { continue }
    }

    Write-Host "ATTENTION: Impossible de créer un lecteur temporaire pour le chemin UNC." -ForegroundColor Red
    return $Path
}

function Remove-TempDrive {
    if (-not $script:TempDriveLetter) { return }
    try {
        $driveLetter = "$($script:TempDriveLetter):"
        $null = & subst /D $driveLetter 2>&1
        Write-Host "Lecteur temporaire $driveLetter supprimé." -ForegroundColor Gray
    } catch { }
    $script:TempDriveLetter = $null
}

# =============================================================================
# LOGGING
# =============================================================================

function Initialize-Logging {
    if (!(Test-Path $script:LogDirectory)) {
        New-Item -ItemType Directory -Path $script:LogDirectory -Force | Out-Null
    }
    if (!(Test-Path $script:AnalysisHistoryFile)) {
        '{"analyses":[]}' | Set-Content -Path $script:AnalysisHistoryFile -Encoding UTF8
    }
}

function Write-AnalysisLog {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARNING","ERROR","DEBUG")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $script:LogFile -Value $logEntry -Encoding UTF8

    $color = switch ($Level) {
        "INFO"    { "White" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        "DEBUG"   { "Gray" }
    }
    if ($Level -ne "DEBUG" -or $env:RECTOR_DEBUG -eq "1") {
        Write-Host $logEntry -ForegroundColor $color
    }
}

# =============================================================================
# DÉCOUVERTE FICHIERS PHP
# =============================================================================

function Get-PhpFilesInProject {
    param(
        [string]$ProjectPath,
        [string[]]$ExcludePaths = @("vendor","cache","tmp","storage","var","node_modules","temp","logs","rector-output")
    )
    $phpFiles = New-Object System.Collections.ArrayList
    try {
        Get-ChildItem -Path $ProjectPath -Recurse -Filter "*.php" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $relativePath = $_.FullName.Replace($ProjectPath, "").TrimStart("\","/")
            $excluded = $false
            foreach ($excludePath in $ExcludePaths) {
                if ($relativePath.StartsWith($excludePath) -or
                    $relativePath.Contains("\$excludePath\") -or
                    $relativePath.Contains("/$excludePath/")) {
                    $excluded = $true
                    break
                }
            }
            if (-not $excluded) {
                [void]$phpFiles.Add(@{
                    FullPath = $_.FullName
                    RelativePath = $relativePath
                    Size = $_.Length
                    LastModified = $_.LastWriteTime
                })
            }
        }
    } catch {
        Write-AnalysisLog "Erreur lors de la récupération des fichiers PHP: $($_.Exception.Message)" -Level "ERROR"
    }
    return ,$phpFiles.ToArray()
}

# =============================================================================
# LOGS D'ANALYSE STRUCTURÉS
# =============================================================================

function Write-AnalysisStart {
    param(
        [string]$ProjectPath,
        [string]$ConfigFile,
        [string]$OutputFormat,
        [bool]$DryRun,
        [string]$PhpVersion
    )
    $separator = Make-Banner "=" 80
    Write-AnalysisLog $separator
    Write-AnalysisLog "DÉBUT DE L'ANALYSE RECTOR"
    Write-AnalysisLog $separator
    Write-AnalysisLog "Projet: $ProjectPath"
    Write-AnalysisLog "Configuration: $ConfigFile"
    Write-AnalysisLog "Format de sortie: $OutputFormat"
    Write-AnalysisLog "Mode Dry-Run: $DryRun"
    Write-AnalysisLog "Version PHP cible: $PhpVersion"
    Write-AnalysisLog "Utilisateur: $env:USERNAME"
    Write-AnalysisLog "Machine: $env:COMPUTERNAME"
}

function Extract-PhpVersionFromConfig {
    <#
    .SYNOPSIS
        Extrait "8.4" depuis "rector-php84.php". Retourne $null si introuvable.
    #>
    param([string]$ConfigFile)
    if ($ConfigFile -match "php(\d+)") {
        $version = $matches[1]
        $major = $version.Substring(0, 1)
        $minor = if ($version.Length -gt 1) { $version.Substring(1) } else { "0" }
        return "$major.$minor"
    }
    return $null
}

function Get-PhpVersionDigits {
    <#
    .SYNOPSIS
        "8.4" -> "84"; "rector-php84.php" -> "84"; "" -> "84" (défaut)
    #>
    param([string]$Source)
    if (-not $Source) { return "84" }
    if ($Source -match "(\d{2})") { return $matches[1] }
    if ($Source -match "(\d)\.(\d)") { return "$($matches[1])$($matches[2])" }
    return "84"
}

function Write-FilesAnalyzedLog {
    param([string]$ProjectPath, [array]$PhpFiles)
    $separator = Make-Banner "-" 60
    Write-AnalysisLog $separator
    Write-AnalysisLog "FICHIERS PHP ANALYSÉS: $($PhpFiles.Count) fichiers"
    Write-AnalysisLog $separator

    foreach ($file in $PhpFiles) {
        $sizeKb = [math]::Round($file.Size / 1024, 2)
        Write-AnalysisLog "  [SCAN] $($file.RelativePath) ($sizeKb KB)" -Level "DEBUG"
    }

    $byFolder = $PhpFiles | Group-Object { Split-Path $_.RelativePath -Parent }
    Write-AnalysisLog ""
    Write-AnalysisLog "Répartition par dossier:"
    foreach ($folder in $byFolder | Sort-Object Name) {
        $folderName = if ($folder.Name -eq "") { "(racine)" } else { $folder.Name }
        Write-AnalysisLog "  - $folderName : $($folder.Count) fichiers"
    }
}

function Write-AnalysisResults {
    param(
        [string]$JsonOutput,
        [TimeSpan]$Duration,
        [int]$TotalFiles
    )
    $allRectors = @{}  # initialisé tôt pour bug fix : RulesApplied même si 0 diff
    try {
        $lines = $JsonOutput -split "`n"
        $jsonStart = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i].TrimStart().StartsWith("{")) { $jsonStart = $i; break }
        }
        if ($jsonStart -lt 0) { return $null }

        $cleanJson = ($lines[$jsonStart..($lines.Count-1)] -join "`n").Trim()
        $data = $cleanJson | ConvertFrom-Json -ErrorAction Stop

        $separator = Make-Banner "-" 60
        Write-AnalysisLog $separator
        Write-AnalysisLog "RÉSULTATS DE L'ANALYSE"
        Write-AnalysisLog $separator

        $changedFiles = if ($data.totals.changed_files) { $data.totals.changed_files } else { 0 }
        $errors       = if ($data.totals.errors)        { $data.totals.errors }        else { 0 }

        Write-AnalysisLog "Fichiers modifiés: $changedFiles / $TotalFiles"
        Write-AnalysisLog "Erreurs détectées: $errors"
        $durationStr = $Duration.TotalSeconds.ToString('F2', [System.Globalization.CultureInfo]::InvariantCulture)
        Write-AnalysisLog "Durée de l'analyse: $durationStr secondes"

        if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
            Write-AnalysisLog ""
            Write-AnalysisLog "Fichiers avec modifications suggérées:"

            foreach ($file in $data.file_diffs) {
                $fileName = Split-Path $file.file -Leaf
                Write-AnalysisLog "  [MODIF] $fileName - $($file.applied_rectors.Count) règle(s)"
                foreach ($rector in $file.applied_rectors) {
                    $rectorName = ($rector -split '\\')[-1]
                    if ($allRectors.ContainsKey($rectorName)) {
                        $allRectors[$rectorName]++
                    } else {
                        $allRectors[$rectorName] = 1
                    }
                }
            }

            Write-AnalysisLog ""
            Write-AnalysisLog "Règles Rector appliquées:"
            foreach ($rector in $allRectors.GetEnumerator() | Sort-Object Value -Descending) {
                Write-AnalysisLog "  - $($rector.Key): $($rector.Value) occurrence(s)"
            }
        }

        return @{
            ChangedFiles = $changedFiles
            Errors       = $errors
            Duration     = $Duration.TotalSeconds
            RulesApplied = $allRectors.Keys.Count
        }
    } catch {
        Write-AnalysisLog "Erreur lors du parsing des résultats: $($_.Exception.Message)" -Level "WARNING"
    }
    return $null
}

function Write-AnalysisEnd {
    param([string]$Status = "SUCCESS")
    $separator = Make-Banner "=" 80
    Write-AnalysisLog $separator
    Write-AnalysisLog "FIN DE L'ANALYSE - Statut: $Status"
    Write-AnalysisLog $separator
    Write-AnalysisLog ""
}

# =============================================================================
# HISTORIQUE
# =============================================================================

function Save-AnalysisHistory {
    param(
        [string]$ProjectPath,
        [string]$ConfigFile,
        [string]$PhpVersionTarget,
        [hashtable]$Results,
        [int]$TotalFiles,
        [string]$Status,
        [string[]]$ExtraSets = @()
    )
    try {
        $history = $null
        if (Test-Path $script:AnalysisHistoryFile) {
            try {
                $history = Get-Content -Path $script:AnalysisHistoryFile -Raw -Encoding UTF8 | ConvertFrom-Json
            } catch {
                Write-AnalysisLog "Historique corrompu, réinitialisation: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        if (-not $history -or -not $history.analyses) {
            $history = [PSCustomObject]@{ analyses = @() }
        }

        $entry = [PSCustomObject]@{
            id                = [guid]::NewGuid().ToString()
            timestamp         = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            project           = $ProjectPath
            projectName       = Split-Path $ProjectPath -Leaf
            configFile        = $ConfigFile
            phpVersionTarget  = $PhpVersionTarget
            extraSets         = $ExtraSets
            totalFilesScanned = $TotalFiles
            changedFiles      = if ($Results) { $Results.ChangedFiles } else { 0 }
            errors            = if ($Results) { $Results.Errors }       else { 0 }
            duration          = if ($Results) { $Results.Duration }     else { 0 }
            rulesApplied      = if ($Results) { $Results.RulesApplied } else { 0 }
            status            = $Status
            user              = $env:USERNAME
            machine           = $env:COMPUTERNAME
        }

        $combined = @($entry) + @($history.analyses)
        $history.analyses = $combined | Select-Object -First 100

        # Écriture atomique
        $tmpFile = "$($script:AnalysisHistoryFile).tmp"
        $history | ConvertTo-Json -Depth 10 | Set-Content -Path $tmpFile -Encoding UTF8
        Move-Item -Path $tmpFile -Destination $script:AnalysisHistoryFile -Force

        Write-AnalysisLog "Analyse sauvegardée dans l'historique (ID: $($entry.id))"
    } catch {
        Write-AnalysisLog "Erreur lors de la sauvegarde de l'historique: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Get-AnalysisHistory {
    param([int]$Count = 100)
    if (!(Test-Path $script:AnalysisHistoryFile)) { return @() }
    try {
        $history = Get-Content -Path $script:AnalysisHistoryFile -Raw -Encoding UTF8 | ConvertFrom-Json
        return @($history.analyses | Select-Object -First $Count)
    } catch {
        Write-Host "Historique illisible: $($_.Exception.Message)" -ForegroundColor Yellow
        return @()
    }
}

function Show-AnalysisHistory {
    param([int]$Count = 10)
    $analyses = Get-AnalysisHistory -Count $Count
    if (-not $analyses -or $analyses.Count -eq 0) {
        Write-Host "Aucun historique disponible." -ForegroundColor Yellow
        return
    }

    $banner = Make-Banner "=" 80
    Write-Host ""
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "  HISTORIQUE DES ANALYSES RECTOR (dernières $Count)" -ForegroundColor Cyan
    Write-Host $banner -ForegroundColor Cyan
    Write-Host ""

    $idx = 1
    foreach ($analysis in $analyses) {
        $statusColor = switch ($analysis.status) {
            "SUCCESS" { "Green" }
            "WARNING" { "Yellow" }
            default   { "Red" }
        }
        $num = "{0,3}." -f $idx
        Write-Host "$num [$($analysis.timestamp)]" -ForegroundColor Gray -NoNewline
        Write-Host " $($analysis.projectName)" -ForegroundColor White -NoNewline
        Write-Host " → PHP $($analysis.phpVersionTarget)" -ForegroundColor Cyan -NoNewline
        Write-Host " | $($analysis.totalFilesScanned) fichiers" -ForegroundColor Gray -NoNewline
        Write-Host " | $($analysis.changedFiles) modifiés" -ForegroundColor Yellow -NoNewline
        Write-Host " | $($analysis.status)" -ForegroundColor $statusColor
        $idx++
    }
    Write-Host ""
    Write-Host "  Fichier d'historique: $script:AnalysisHistoryFile" -ForegroundColor Gray
    Write-Host ""
}

# =============================================================================
# SETTINGS UTILISATEUR (mémoire des derniers choix)
# =============================================================================

function Get-UserSettings {
    if (!(Test-Path $script:SettingsFile)) {
        return [PSCustomObject]@{
            lastProjectPath  = $null
            lastPhpVersion   = $null
            lastExtraSets    = @()
            lastOutputFormat = $null
        }
    }
    try {
        return Get-Content -Path $script:SettingsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        return [PSCustomObject]@{
            lastProjectPath  = $null
            lastPhpVersion   = $null
            lastExtraSets    = @()
            lastOutputFormat = $null
        }
    }
}

function Save-UserSettings {
    param(
        [string]$ProjectPath,
        [string]$PhpVersion,
        [string[]]$ExtraSets,
        [string]$OutputFormat
    )
    try {
        $settings = [PSCustomObject]@{
            lastProjectPath  = $ProjectPath
            lastPhpVersion   = $PhpVersion
            lastExtraSets    = @($ExtraSets)
            lastOutputFormat = $OutputFormat
        }
        $tmp = "$($script:SettingsFile).tmp"
        $settings | ConvertTo-Json -Depth 5 | Set-Content -Path $tmp -Encoding UTF8
        Move-Item -Path $tmp -Destination $script:SettingsFile -Force
    } catch {
        Write-AnalysisLog "Impossible de sauvegarder les préférences: $($_.Exception.Message)" -Level "WARNING"
    }
}

# =============================================================================
# AIDE / EN-TÊTE
# =============================================================================

function Show-Header {
    Clear-Host
    Write-Host @"
==========================================
   RECTOR PHP ANALYSIS TOOLS v2.1
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
    -ProjectPath <chemin>   Chemin du projet PHP à analyser
    -PhpVersion <vv>        Version PHP cible (70..84). Ex: 81, 84.
    -ConfigFile <fichier>   Fichier de configuration Rector brut (avancé)
    -ExtraSets <set,set>    Sets Rector additionnels (CODE_QUALITY, DEAD_CODE, ...)
    -UseRawConfig           N'utilise PAS la config dynamique, mais -ConfigFile tel quel
    -OutputFormat <format>  Format de sortie (simple|readable|detailed|json)
    -OutputFile <fichier>   Fichier de sauvegarde du rapport
    -DryRun                 Mode dry-run (par défaut: true). Utilisez -DryRun:`$false pour appliquer
    -Interactive            Mode interactif (par défaut: true)
    -Help                   Affiche cette aide
    -ShowHistory            Affiche l'historique des analyses
    -HistoryCount <n>       Nombre d'analyses à afficher (défaut: 10)
    -ShowLogs               Ouvre le fichier de logs

EXEMPLES:
    .\rector-analyze.ps1
    .\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 81
    .\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 84 -ExtraSets CODE_QUALITY,DEAD_CODE
    .\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -OutputFile "rapport.md" -DryRun:`$false
    .\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector.php" -UseRawConfig
    .\rector-analyze.ps1 -ShowHistory -HistoryCount 20
    .\rector-analyze.ps1 -ShowLogs

FORMATS DE SORTIE:
    simple     - Résumé basique
    readable   - Rapport détaillé groupé par catégorie (recommandé)
    detailed   - Rapport exhaustif avec explications par règle
    json       - Sortie JSON brute

CONFIG DYNAMIQUE vs CONFIG BRUTE:
    Par défaut, le script génère une configuration Rector temporaire qui :
      - scanne le projet pour détecter les dossiers contenant du PHP,
      - applique les exclusions correctes (vendor, cache, node_modules, ...),
      - sélectionne les sets appropriés à la version PHP cible,
      - utilise getcwd() pour que les chemins fonctionnent dans le projet utilisateur.

    Pour utiliser un fichier rector.php existant tel quel, ajoutez -UseRawConfig.

LOGS ET HISTORIQUE:
    Les logs sont sauvegardés dans : logs/rector-analysis.log
    L'historique JSON est dans     : logs/analysis-history.json
    Les préférences utilisateur    : logs/user-settings.json

"@ -ForegroundColor Cyan
}

# =============================================================================
# RÉSOLUTION FICHIER DE CONFIG (mode -UseRawConfig)
# =============================================================================

function Resolve-ConfigFile {
    param(
        [string]$ConfigFile,
        [string]$ProjectPath = ""
    )
    if ($ConfigFile -ne "" -and (Test-Path $ConfigFile -PathType Leaf)) {
        return (Resolve-Path $ConfigFile).Path
    }

    $searchPaths = @(
        Join-Path $PSScriptRoot "config\$ConfigFile"
        Join-Path $PSScriptRoot $ConfigFile
    )
    if ($ProjectPath -ne "") {
        $searchPaths += Join-Path $ProjectPath "rector-configs\$ConfigFile"
        $searchPaths += Join-Path $ProjectPath $ConfigFile
    }
    $searchPaths += Join-Path (Get-Location) $ConfigFile

    if (-not $ConfigFile.StartsWith("rector-")) {
        $searchPaths += Join-Path $PSScriptRoot "config\rector-$ConfigFile"
    }

    foreach ($path in $searchPaths) {
        if (Test-Path $path -PathType Leaf) {
            return (Resolve-Path $path).Path
        }
    }
    return $ConfigFile
}

# =============================================================================
# CONFIGURATION RECTOR DYNAMIQUE
# =============================================================================

function New-DynamicRectorConfig {
    <#
    .SYNOPSIS
        Génère une configuration Rector temporaire pour le projet analysé.
    .DESCRIPTION
        - Scanne le projet pour détecter les dossiers PHP
        - Choisit le LevelSet selon la version PHP demandée
        - Active les SetList::* additionnels demandés
        - Utilise getcwd() pour que les chemins matchent le projet utilisateur
    #>
    param(
        [string]$ProjectPath,
        [string]$PhpVersion = "84",
        [string[]]$ExtraSets = @()
    )

    $excludeDirs = @('vendor','cache','tmp','storage','node_modules','logs','sessions','var','.git','.gitlab','.idea','.vscode','rector-output','rector-configs','temp')

    Write-Host "Scan des dossiers contenant des fichiers PHP..." -ForegroundColor Gray
    $foundDirs = @()

    try {
        $allSubDirs = Get-ChildItem -Path $ProjectPath -Directory -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notin $excludeDirs -and -not $_.Name.StartsWith('.')
        }
        foreach ($subDir in $allSubDirs) {
            $hasPhp = Get-ChildItem -Path $subDir.FullName -Filter "*.php" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hasPhp) { $foundDirs += $subDir.Name }
        }
    } catch {
        Write-Host "Avertissement lors du scan: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    $rootPhp = Get-ChildItem -Path $ProjectPath -Filter "*.php" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($rootPhp) { $foundDirs += '.' }

    if ($foundDirs.Count -eq 0) {
        Write-Host "Aucun fichier PHP trouvé, analyse de la racine par défaut..." -ForegroundColor Yellow
        $foundDirs = @('.')
    } else {
        Write-Host "Dossiers PHP détectés ($($foundDirs.Count)) : $($foundDirs -join ', ')" -ForegroundColor Cyan
    }

    $supported = $script:SupportedPhpVersions
    if ($PhpVersion -notin $supported) {
        Write-Host "Version PHP '$PhpVersion' non reconnue, utilisation de 84." -ForegroundColor Yellow
        $PhpVersion = "84"
    }

    $levelSet = "LevelSetList::UP_TO_PHP_$PhpVersion"

    # Liste des sets additionnels - on garde seulement ceux qui sont valides
    $validExtraSets = @()
    foreach ($s in $ExtraSets) {
        $upper = $s.ToUpper()
        if ($script:AvailableSets.Contains($upper)) {
            $validExtraSets += $upper
        }
    }
    $extraSetsPhp = if ($validExtraSets.Count -gt 0) {
        ($validExtraSets | ForEach-Object { "        SetList::$_," }) -join "`n"
    } else { "" }

    $pathsPhp = ($foundDirs | ForEach-Object { "        `$projectRoot . '/$_'" }) -join ",`n"
    $skipsPhp = ($excludeDirs | ForEach-Object { "        `$projectRoot . '/$_'" }) -join ",`n"

    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $configContent = @"
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector générée dynamiquement
 * Projet         : $ProjectPath
 * Version cible  : PHP $PhpVersion
 * Sets activés   : $($validExtraSets -join ', ')
 * Date           : $now
 */
return static function (RectorConfig `$rectorConfig): void {
    `$projectRoot = getcwd();

    `$rectorConfig->paths([
$pathsPhp
    ]);

    `$rectorConfig->sets([
        $levelSet,
$extraSetsPhp
    ]);

    `$rectorConfig->skip([
$skipsPhp
    ]);

    `$rectorConfig->parallel();
};
"@

    if (!(Test-Path $script:TempDir)) {
        New-Item -ItemType Directory -Path $script:TempDir -Force | Out-Null
    }
    $tempConfigFile = Join-Path $script:TempDir "rector-dynamic-php$PhpVersion.php"
    Write-Utf8File -Path $tempConfigFile -Content $configContent -WithBom $false

    Write-Host "Configuration dynamique générée: $tempConfigFile" -ForegroundColor Green
    Write-AnalysisLog "Configuration dynamique créée pour $($foundDirs.Count) dossier(s), sets : $($validExtraSets -join ', ')"
    return $tempConfigFile
}

# =============================================================================
# RÉSOLUTION DU BINAIRE RECTOR
# =============================================================================

function Find-RectorBinary {
    param([string]$WorkingPath)

    # 1. Dans le projet analysé
    if (Test-Path "vendor\bin\rector.bat") { return "vendor\bin\rector.bat" }
    if (Test-Path "vendor\bin\rector")     { return "vendor\bin\rector" }

    # 2. Dans phpmigrations
    $localBat = Join-Path $PSScriptRoot "vendor\bin\rector.bat"
    $local    = Join-Path $PSScriptRoot "vendor\bin\rector"
    if (Test-Path $localBat) { return $localBat }
    if (Test-Path $local)    { return $local }

    # 3. Dans le projet d'exemples bundlé
    $exampleProject = Join-Path $PSScriptRoot "examples\sample-php-project"
    $exBat = Join-Path $exampleProject "vendor\bin\rector.bat"
    $ex    = Join-Path $exampleProject "vendor\bin\rector"
    if (Test-Path $exBat) { return $exBat }
    if (Test-Path $ex)    { return $ex }

    # 4. Rector global
    $globalRector = Get-Command rector -ErrorAction SilentlyContinue
    if ($globalRector) { return "rector" }

    # 5. Tenter installation
    Write-Host "Rector non trouvé. Installation en cours..." -ForegroundColor Yellow
    Write-AnalysisLog "Rector non trouvé - Installation en cours" -Level "WARNING"
    $installScript = Join-Path $PSScriptRoot "scripts\install-rector.ps1"
    if (Test-Path $installScript) {
        & $installScript -ProjectPath $WorkingPath
        if (Test-Path "vendor\bin\rector.bat") { return "vendor\bin\rector.bat" }
        if (Test-Path "vendor\bin\rector")     { return "vendor\bin\rector" }
        if (Test-Path $exBat) { return $exBat }
        if (Test-Path $ex)    { return $ex }
    }
    return $null
}

# =============================================================================
# EXÉCUTION DE L'ANALYSE
# =============================================================================

function Invoke-RectorAnalysis {
    param(
        [string]$ProjectPath,
        [string]$ConfigFile,
        [bool]$DryRun,
        [string]$OutputFormat = "readable",
        [string]$PhpVersion = "84",
        [string[]]$ExtraSets = @(),
        [bool]$UseRawConfig = $false
    )

    Initialize-Logging
    $startTime = Get-Date

    Write-AnalysisStart -ProjectPath $ProjectPath -ConfigFile $ConfigFile -OutputFormat $OutputFormat -DryRun $DryRun -PhpVersion $PhpVersion

    $phpFiles = Get-PhpFilesInProject -ProjectPath $ProjectPath
    Write-FilesAnalyzedLog -ProjectPath $ProjectPath -PhpFiles $phpFiles

    Write-Host ""
    Write-Host "Exécution de l'analyse Rector..." -ForegroundColor Yellow
    Write-Host "Projet        : $ProjectPath" -ForegroundColor Cyan
    Write-Host "Version cible : PHP $PhpVersion" -ForegroundColor Cyan
    Write-Host "Sets actifs   : $(if ($ExtraSets) { $ExtraSets -join ', ' } else { '(aucun)' })" -ForegroundColor Cyan
    Write-Host "Fichiers PHP détectés : $($phpFiles.Count)" -ForegroundColor Cyan
    Write-Host "Mode          : $(if ($DryRun) { 'Dry-run (simulation)' } else { 'Application des changements' })" -ForegroundColor Cyan
    Write-Host ""

    $workingPath = Use-UNCPath -Path $ProjectPath
    if ($workingPath -ne $ProjectPath -and -not $script:TempDriveLetter) {
        throw "Chemin UNC détecté mais aucune lettre de lecteur disponible. Abandon."
    }

    Push-Location $workingPath
    try {
        $rectorBin = Find-RectorBinary -WorkingPath $workingPath
        if (-not $rectorBin) {
            Write-AnalysisLog "Rector n'a pas pu être installé" -Level "ERROR"
            Write-AnalysisEnd -Status "FAILED"
            throw "Rector n'a pas pu être installé ou trouvé. Veuillez l'installer manuellement."
        }
        Write-AnalysisLog "Rector trouvé: $rectorBin"

        $arguments = @("process", ".")
        if ($DryRun) { $arguments += "--dry-run" }

        # Mode "config brute" demandé par l'utilisateur : on utilise -ConfigFile tel quel
        if ($UseRawConfig -and $ConfigFile -and (Test-Path $ConfigFile -PathType Leaf)) {
            $configPath = (Resolve-Path $ConfigFile).Path
            Write-Host "Configuration brute (raw): $configPath" -ForegroundColor Yellow
            Write-AnalysisLog "Mode config brute demandé : $configPath"
        } else {
            $configPath = New-DynamicRectorConfig -ProjectPath $ProjectPath -PhpVersion $PhpVersion -ExtraSets $ExtraSets
        }

        $arguments += @("--output-format=json", "--config=$configPath")

        Write-Host "Commande      : $rectorBin $($arguments -join ' ')" -ForegroundColor Gray
        Write-Host "Configuration : $configPath" -ForegroundColor Gray
        Write-Host ""

        Write-AnalysisLog "Commande exécutée: $rectorBin $($arguments -join ' ')"

        $output = & $rectorBin $arguments 2>&1
        $exitCode = $LASTEXITCODE

        $duration = (Get-Date) - $startTime
        $results = Write-AnalysisResults -JsonOutput ($output -join "`n") -Duration $duration -TotalFiles $phpFiles.Count

        $phpVersionFmt = "$($PhpVersion.Substring(0,1)).$($PhpVersion.Substring(1))"
        if ($exitCode -eq 0) {
            Write-Host "Analyse terminée avec succès." -ForegroundColor Green
            Write-AnalysisEnd -Status "SUCCESS"
            Save-AnalysisHistory -ProjectPath $ProjectPath -ConfigFile $configPath -PhpVersionTarget $phpVersionFmt -Results $results -TotalFiles $phpFiles.Count -Status "SUCCESS" -ExtraSets $ExtraSets
            return $output -join "`n"
        } else {
            Write-Host "Analyse terminée avec des avertissements (code: $exitCode)." -ForegroundColor Yellow
            Write-AnalysisEnd -Status "WARNING"
            Save-AnalysisHistory -ProjectPath $ProjectPath -ConfigFile $configPath -PhpVersionTarget $phpVersionFmt -Results $results -TotalFiles $phpFiles.Count -Status "WARNING" -ExtraSets $ExtraSets
            return $output -join "`n"
        }
    } catch {
        Write-Host "Erreur lors de l'analyse: $($_.Exception.Message)" -ForegroundColor Red
        Write-AnalysisLog "Erreur: $($_.Exception.Message)" -Level "ERROR"
        Write-AnalysisEnd -Status "FAILED"
        $phpVersionFmt = "$($PhpVersion.Substring(0,1)).$($PhpVersion.Substring(1))"
        Save-AnalysisHistory -ProjectPath $ProjectPath -ConfigFile $ConfigFile -PhpVersionTarget $phpVersionFmt -Results $null -TotalFiles $phpFiles.Count -Status "FAILED" -ExtraSets $ExtraSets
        throw
    } finally {
        Pop-Location
        Remove-TempDrive
    }
}

# =============================================================================
# FORMATAGE DE LA SORTIE
# =============================================================================

function Format-Output {
    param([string]$JsonOutput, [string]$Format, [string]$ProjectPath)
    switch ($Format) {
        "simple"   { return Format-SimpleOutput   -JsonOutput $JsonOutput -ProjectPath $ProjectPath }
        "readable" { return Format-ReadableOutput -JsonOutput $JsonOutput -ProjectPath $ProjectPath }
        "detailed" { return Format-DetailedOutput -JsonOutput $JsonOutput -ProjectPath $ProjectPath }
        "json"     { return $JsonOutput }
        default    { return Format-ReadableOutput -JsonOutput $JsonOutput -ProjectPath $ProjectPath }
    }
}

function Get-CleanJson {
    param([string]$JsonOutput)
    $lines = $JsonOutput -split "`n"
    $jsonStart = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].TrimStart().StartsWith("{")) { $jsonStart = $i; break }
    }
    if ($jsonStart -lt 0) { return $null }
    return ($lines[$jsonStart..($lines.Count-1)] -join "`n").Trim()
}

function Format-SimpleOutput {
    param([string]$JsonOutput, [string]$ProjectPath)
    try {
        $cleanJson = Get-CleanJson $JsonOutput
        if (-not $cleanJson) { throw "Aucun JSON valide trouvé dans la sortie" }
        $data = $cleanJson | ConvertFrom-Json -ErrorAction Stop

        $output = @"
# Analyse Rector - $(Split-Path $ProjectPath -Leaf)

**Rapport généré le** : $(Get-Date -Format "dd/MM/yyyy HH:mm")
**Projet** : $ProjectPath

## Résultats

"@
        if ($data.totals) {
            $changedFiles = if ($data.totals.changed_files) { $data.totals.changed_files } else { 0 }
            $errors       = if ($data.totals.errors)        { $data.totals.errors }        else { 0 }
            $output += @"
- **Fichiers modifiés** : $changedFiles
- **Erreurs détectées** : $errors
- **Statut** : $(if ($changedFiles -gt 0) { 'Améliorations possibles' } else { 'Code déjà moderne' })

"@
        }

        if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
            $output += "## Fichiers impactés`n`n"
            foreach ($file in $data.file_diffs) {
                $fileName = Split-Path $file.file -Leaf
                $rectorsApplied = $file.applied_rectors.Count
                $output += "- ``$fileName`` ($rectorsApplied changement(s))`n"
            }
            $output += "`n"
        } else {
            $output += "## Aucun changement détecté`n`n**Votre code est déjà moderne !**`n"
        }
        return $output
    } catch {
        return @"
# Erreur d'analyse

Impossible de parser la sortie JSON. Voici la sortie brute :

``````
$JsonOutput
``````
"@
    }
}

function Format-ReadableOutput {
    param([string]$JsonOutput, [string]$ProjectPath)
    $scriptPath = Join-Path $PSScriptRoot "analyze-rector-readable.ps1"
    if (-not (Test-Path $scriptPath)) {
        $scriptPath = Join-Path $PSScriptRoot "scripts\analyze-rector-readable.ps1"
    }
    if (-not (Test-Path $scriptPath)) {
        return Format-SimpleOutput $JsonOutput $ProjectPath
    }
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value $JsonOutput -Encoding UTF8
        $result = & $scriptPath -JsonFile $tempFile -ProjectPath $ProjectPath
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        return ($result -join "`r`n")
    } catch {
        return "Erreur lors du formatage readable: $($_.Exception.Message)"
    }
}

function Format-DetailedOutput {
    param([string]$JsonOutput, [string]$ProjectPath)
    $scriptPath = Join-Path $PSScriptRoot "analyze-rector-detailed.ps1"
    if (-not (Test-Path $scriptPath)) {
        $scriptPath = Join-Path $PSScriptRoot "scripts\analyze-rector-detailed.ps1"
    }
    if (-not (Test-Path $scriptPath)) {
        return Format-ReadableOutput $JsonOutput $ProjectPath
    }
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        Set-Content -Path $tempFile -Value $JsonOutput -Encoding UTF8
        $result = & $scriptPath -JsonFile $tempFile -ProjectPath $ProjectPath
        Remove-Item $tempFile -ErrorAction SilentlyContinue
        return ($result -join "`r`n")
    } catch {
        return "Erreur lors du formatage detailed: $($_.Exception.Message)"
    }
}

function Save-Output {
    param([string]$Content, [string]$OutputFile, [string]$ProjectPath)
    if ($OutputFile -eq "") {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $outputDir = Join-Path $ProjectPath "rector-output"
        if (!(Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        $OutputFile = Join-Path $outputDir "rector-analysis_$timestamp.md"
    }
    Set-Content -Path $OutputFile -Value $Content -Encoding UTF8
    Write-Host "Rapport sauvegardé : $OutputFile" -ForegroundColor Green
    return $OutputFile
}

# =============================================================================
# MENU INTERACTIF
# =============================================================================

function Read-MenuChoice {
    <#
    .SYNOPSIS
        Lit un choix dans une liste de valeurs valides, en bouclant tant
        que la saisie n'est pas correcte.
    #>
    param(
        [string]$Prompt,
        [string[]]$ValidChoices,
        [string]$DefaultChoice = $null
    )
    while ($true) {
        $choice = Read-Host $Prompt
        if ([string]::IsNullOrEmpty($choice) -and $DefaultChoice) {
            return $DefaultChoice
        }
        if ($choice -in $ValidChoices) { return $choice }
        Write-Host "Choix invalide. Valeurs acceptées : $($ValidChoices -join ', ')" -ForegroundColor Red
    }
}

function Read-YesNo {
    param([string]$Prompt, [bool]$DefaultYes = $false)
    $hint = if ($DefaultYes) { "(O/n)" } else { "(o/N)" }
    while ($true) {
        $a = Read-Host "$Prompt $hint"
        if ([string]::IsNullOrEmpty($a)) { return $DefaultYes }
        $a = $a.ToLower()
        if ($a -in @("o","y","oui","yes")) { return $true }
        if ($a -in @("n","non","no"))      { return $false }
        Write-Host "Veuillez répondre par 'o' (oui) ou 'n' (non)." -ForegroundColor Red
    }
}

function Get-ProjectPathInteractive {
    param([string]$CurrentPath, [object]$Settings)

    if ($CurrentPath -ne "" -and (Test-Path $CurrentPath)) {
        return $CurrentPath
    }

    Write-Host "Sélection du projet PHP à analyser :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Projet courant ($(Get-Location))"
    Write-Host "  2. Saisir un chemin"
    Write-Host "  3. Utiliser le projet d'exemple bundlé"
    if ($Settings.lastProjectPath -and (Test-Path $Settings.lastProjectPath)) {
        Write-Host "  4. Dernier projet utilisé ($($Settings.lastProjectPath))"
    }
    Write-Host "  q. Annuler"
    Write-Host ""

    $valid = @("1","2","3","q")
    if ($Settings.lastProjectPath -and (Test-Path $Settings.lastProjectPath)) {
        $valid += "4"
    }

    while ($true) {
        $choice = Read-MenuChoice -Prompt "Votre choix" -ValidChoices $valid

        switch ($choice) {
            "1" { return (Get-Location).Path }
            "2" {
                $path = Read-Host "Entrez le chemin complet du projet"
                if (Test-Path $path) {
                    return (Resolve-Path $path).Path
                }
                Write-Host "Chemin invalide : $path" -ForegroundColor Red
                # boucle
            }
            "3" {
                $examplePath = Join-Path $PSScriptRoot "examples\sample-php-project"
                if (!(Test-Path $examplePath)) {
                    Write-Host "Création du projet d'exemple..." -ForegroundColor Yellow
                    Create-ExampleProject $examplePath
                }
                return (Resolve-Path $examplePath).Path
            }
            "4" {
                return $Settings.lastProjectPath
            }
            "q" {
                return ""
            }
        }
    }
}

function Get-PhpVersionInteractive {
    param([object]$Settings)
    Write-Host "Sélection de la version PHP cible :" -ForegroundColor Yellow
    Write-Host ""
    $versions = @(
        @{ Key="1"; Value="74"; Label="PHP 7.4 (LTS-friendly)" }
        @{ Key="2"; Value="80"; Label="PHP 8.0" }
        @{ Key="3"; Value="81"; Label="PHP 8.1" }
        @{ Key="4"; Value="82"; Label="PHP 8.2" }
        @{ Key="5"; Value="83"; Label="PHP 8.3" }
        @{ Key="6"; Value="84"; Label="PHP 8.4 (recommandé)" }
        @{ Key="7"; Value="73"; Label="PHP 7.3" }
        @{ Key="8"; Value="72"; Label="PHP 7.2" }
        @{ Key="9"; Value="71"; Label="PHP 7.1" }
        @{ Key="0"; Value="70"; Label="PHP 7.0" }
    )
    foreach ($v in $versions) {
        $marker = if ($Settings.lastPhpVersion -eq $v.Value) { " (dernier choix)" } else { "" }
        Write-Host "  $($v.Key). $($v.Label)$marker"
    }
    Write-Host ""
    $default = if ($Settings.lastPhpVersion) {
        ($versions | Where-Object { $_.Value -eq $Settings.lastPhpVersion } | Select-Object -First 1).Key
    } else { "6" }

    $valid = $versions | ForEach-Object { $_.Key }
    $choice = Read-MenuChoice -Prompt "Votre choix [$default]" -ValidChoices $valid -DefaultChoice $default
    return ($versions | Where-Object { $_.Key -eq $choice } | Select-Object -First 1).Value
}

function Get-ExtraSetsInteractive {
    param([object]$Settings)
    Write-Host ""
    Write-Host "Sets Rector additionnels (qualité, dead code, types, etc.) :" -ForegroundColor Yellow
    Write-Host "Tapez 'a' pour tout activer, 'd' pour les valeurs par défaut, ou les numéros séparés par des virgules (ex: 1,3,5). Entrée seule = défaut." -ForegroundColor Gray
    Write-Host ""

    $previous = if ($Settings.lastExtraSets) { @($Settings.lastExtraSets) } else { @() }
    $sets = @($script:AvailableSets.Keys)

    for ($i = 0; $i -lt $sets.Count; $i++) {
        $name = $sets[$i]
        $desc = $script:AvailableSets[$name]
        $marker = if ($name -in $previous) { " [dernier]" } elseif ($name -in $script:DefaultSets) { " [défaut]" } else { "" }
        Write-Host ("  {0}. {1} - {2}{3}" -f ($i+1), $name, $desc, $marker)
    }
    Write-Host ""

    while ($true) {
        $input = Read-Host "Votre sélection [d]"
        if ([string]::IsNullOrWhiteSpace($input)) { return @($script:DefaultSets) }
        $input = $input.Trim().ToLower()
        if ($input -eq "d") { return @($script:DefaultSets) }
        if ($input -eq "a") { return @($sets) }
        if ($input -eq "n" -or $input -eq "none" -or $input -eq "0") { return @() }

        $picked = New-Object System.Collections.ArrayList
        $bad = $false
        foreach ($token in $input -split '[,\s]+' | Where-Object { $_ -ne "" }) {
            if ($token -notmatch '^\d+$') { $bad = $true; break }
            $idx = [int]$token - 1
            if ($idx -lt 0 -or $idx -ge $sets.Count) { $bad = $true; break }
            [void]$picked.Add($sets[$idx])
        }
        if ($bad) {
            Write-Host "Saisie invalide. Réessayez." -ForegroundColor Red
            continue
        }
        return @($picked.ToArray() | Select-Object -Unique)
    }
}

function Get-OutputFormatInteractive {
    param([object]$Settings)
    Write-Host ""
    Write-Host "Sélection du format de rapport :" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Simple   - Résumé rapide"
    Write-Host "  2. Readable - Rapport détaillé groupé par catégorie (recommandé)"
    Write-Host "  3. Detailed - Rapport exhaustif avec explications par règle"
    Write-Host "  4. JSON     - Sortie JSON brute"
    Write-Host ""

    $map = @{ "1" = "simple"; "2" = "readable"; "3" = "detailed"; "4" = "json" }
    $reverseMap = @{ "simple" = "1"; "readable" = "2"; "detailed" = "3"; "json" = "4" }
    $default = if ($Settings.lastOutputFormat -and $reverseMap.ContainsKey($Settings.lastOutputFormat)) {
        $reverseMap[$Settings.lastOutputFormat]
    } else { "2" }

    $choice = Read-MenuChoice -Prompt "Votre choix [$default]" -ValidChoices @("1","2","3","4") -DefaultChoice $default
    return $map[$choice]
}

function Invoke-ReplayMenu {
    $analyses = Get-AnalysisHistory -Count 10
    if (-not $analyses -or $analyses.Count -eq 0) {
        Write-Host "Aucune analyse précédente à rejouer." -ForegroundColor Yellow
        return $null
    }
    Show-AnalysisHistory -Count 10
    while ($true) {
        $sel = Read-Host "Numéro de l'analyse à rejouer (1-$($analyses.Count)) ou 'q' pour annuler"
        if ($sel -eq "q") { return $null }
        if ($sel -match '^\d+$') {
            $idx = [int]$sel - 1
            if ($idx -ge 0 -and $idx -lt $analyses.Count) {
                $a = $analyses[$idx]
                if (-not (Test-Path $a.project)) {
                    Write-Host "Le chemin du projet n'existe plus : $($a.project)" -ForegroundColor Red
                    return $null
                }
                $version = Get-PhpVersionDigits -Source $a.phpVersionTarget
                $extraSets = if ($a.extraSets) { @($a.extraSets) } else { @($script:DefaultSets) }
                return [PSCustomObject]@{
                    ProjectPath = $a.project
                    PhpVersion  = $version
                    ExtraSets   = $extraSets
                }
            }
        }
        Write-Host "Numéro invalide." -ForegroundColor Red
    }
}

# =============================================================================
# CRÉATION PROJET D'EXEMPLE
# =============================================================================

function Create-ExampleProject {
    param([string]$ExamplePath)
    New-Item -ItemType Directory -Path $ExamplePath -Force | Out-Null
    New-Item -ItemType Directory -Path "$ExamplePath\src" -Force | Out-Null

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
    Write-Utf8File -Path (Join-Path $ExamplePath "src\UserManager.php") -Content $exampleCode -WithBom $false
    Write-Host "Projet d'exemple créé : $ExamplePath" -ForegroundColor Green
}

# =============================================================================
# SCRIPT PRINCIPAL
# =============================================================================

Initialize-Logging

if ($Help) {
    Show-Help
    exit 0
}

if ($ShowHistory) {
    Show-Header
    Show-AnalysisHistory -Count $HistoryCount
    exit 0
}

if ($ShowLogs) {
    if (Test-Path $script:LogFile) {
        Write-Host "Ouverture du fichier de logs : $script:LogFile" -ForegroundColor Green
        Start-Process $script:LogFile
    } else {
        Write-Host "Aucun fichier de log trouvé. Lancez d'abord une analyse." -ForegroundColor Yellow
    }
    exit 0
}

Show-Header

$settings = Get-UserSettings
$replay   = $null

if ($Interactive) {
    Write-Host "Mode interactif - Que souhaitez-vous faire ?" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. Lancer une nouvelle analyse"
    Write-Host "  2. Rejouer une analyse récente"
    Write-Host "  3. Consulter l'historique des analyses"
    Write-Host "  4. Ouvrir les fichiers de logs"
    Write-Host "  5. Quitter"
    Write-Host ""

    $mainChoice = Read-MenuChoice -Prompt "Votre choix" -ValidChoices @("1","2","3","4","5")

    switch ($mainChoice) {
        "2" {
            $replay = Invoke-ReplayMenu
            if (-not $replay) { exit 0 }
        }
        "3" {
            Show-AnalysisHistory -Count 20
            $continue = Read-YesNo -Prompt "Lancer une nouvelle analyse ?" -DefaultYes:$false
            if (-not $continue) { exit 0 }
        }
        "4" {
            Write-Host ""
            Write-Host "Fichiers de logs disponibles :" -ForegroundColor Cyan
            Write-Host "  1. Fichier de log principal : $script:LogFile"
            Write-Host "  2. Historique JSON          : $script:AnalysisHistoryFile"
            Write-Host ""
            $logChoice = Read-MenuChoice -Prompt "Ouvrir quel fichier ? (1-2, q pour annuler)" -ValidChoices @("1","2","q")
            if ($logChoice -eq "1" -and (Test-Path $script:LogFile)) {
                Start-Process $script:LogFile
            } elseif ($logChoice -eq "2" -and (Test-Path $script:AnalysisHistoryFile)) {
                Start-Process $script:AnalysisHistoryFile
            }
            exit 0
        }
        "5" {
            Write-Host "Au revoir !" -ForegroundColor Green
            exit 0
        }
    }

    # Wizard
    if ($replay) {
        $ProjectPath = $replay.ProjectPath
        $PhpVersion  = $replay.PhpVersion
        $ExtraSets   = $replay.ExtraSets
        Write-Host ""
        Write-Host "Rejeu de l'analyse : $ProjectPath / PHP $PhpVersion / Sets : $($ExtraSets -join ', ')" -ForegroundColor Cyan
    } else {
        $ProjectPath = Get-ProjectPathInteractive -CurrentPath $ProjectPath -Settings $settings
        if ($ProjectPath -eq "") {
            Write-Host "Aucun projet sélectionné. Arrêt." -ForegroundColor Red
            exit 1
        }
        if (-not $PhpVersion) {
            $PhpVersion = Get-PhpVersionInteractive -Settings $settings
        }
        if ($ExtraSets.Count -eq 0) {
            $ExtraSets = Get-ExtraSetsInteractive -Settings $settings
        }
    }

    Write-Host ""
    if ($OutputFormat -eq "readable") {
        $OutputFormat = Get-OutputFormatInteractive -Settings $settings
    }

    Write-Host ""
    $DryRun = Read-YesNo -Prompt "Mode dry-run (simulation uniquement) ?" -DefaultYes:$true
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "ATTENTION: les changements seront APPLIQUÉS au code." -ForegroundColor Red
        $confirm = Read-YesNo -Prompt "Confirmer ?" -DefaultYes:$false
        if (-not $confirm) { $DryRun = $true }
    }

    Write-Host ""
    if ($OutputFile -eq "") {
        $saveFile = Read-YesNo -Prompt "Sauvegarder le rapport dans un fichier ?" -DefaultYes:$false
        if ($saveFile) {
            $OutputFile = Read-Host "Nom du fichier (laissez vide pour auto-généré)"
        }
    }

    Write-Host ""
    Write-Host "Configuration terminée. Démarrage de l'analyse..." -ForegroundColor Green
    Write-Host ""
}

# =============================================================================
# Validation finale & exécution
# =============================================================================

if (!(Test-Path $ProjectPath)) {
    Write-Host "Erreur: Le projet '$ProjectPath' n'existe pas." -ForegroundColor Red
    exit 1
}

# Mode -UseRawConfig : on résout le ConfigFile classique
$resolvedConfigFile = ""
if ($UseRawConfig) {
    if (-not $ConfigFile) {
        Write-Host "Erreur: -UseRawConfig nécessite -ConfigFile." -ForegroundColor Red
        exit 1
    }
    $resolvedConfigFile = Resolve-ConfigFile -ConfigFile $ConfigFile -ProjectPath $ProjectPath
    if (!(Test-Path $resolvedConfigFile -PathType Leaf)) {
        Write-Host "Erreur: Le fichier de configuration '$ConfigFile' n'existe pas." -ForegroundColor Red
        exit 1
    }
    Write-Host "Configuration brute (raw) utilisée : $resolvedConfigFile" -ForegroundColor Cyan
} elseif ($ConfigFile) {
    # Pas de -UseRawConfig, mais -ConfigFile fourni : on utilise le nom seulement pour deviner la version
    $resolvedConfigFile = Resolve-ConfigFile -ConfigFile $ConfigFile -ProjectPath $ProjectPath
}

# Détermination de la version PHP si non fournie
if (-not $PhpVersion) {
    $PhpVersion = Get-PhpVersionDigits -Source $resolvedConfigFile
    if (-not $PhpVersion) { $PhpVersion = "84" }
}

# Sets par défaut si toujours vide
if ($ExtraSets.Count -eq 0) {
    $ExtraSets = $script:DefaultSets
}

# Sauvegarde des préférences pour la prochaine fois
Save-UserSettings -ProjectPath $ProjectPath -PhpVersion $PhpVersion -ExtraSets $ExtraSets -OutputFormat $OutputFormat

try {
    $jsonOutput = Invoke-RectorAnalysis `
        -ProjectPath $ProjectPath `
        -ConfigFile $resolvedConfigFile `
        -DryRun $DryRun `
        -OutputFormat $OutputFormat `
        -PhpVersion $PhpVersion `
        -ExtraSets $ExtraSets `
        -UseRawConfig:$UseRawConfig

    $formattedOutput = Format-Output $jsonOutput $OutputFormat $ProjectPath
    Write-Host $formattedOutput

    if ($OutputFile -ne "" -or ($Interactive -and $saveFile)) {
        $savedFile = Save-Output -Content $formattedOutput -OutputFile $OutputFile -ProjectPath $ProjectPath
        if ($Interactive) {
            Write-Host ""
            $openFile = Read-YesNo -Prompt "Ouvrir le fichier généré ?" -DefaultYes:$false
            if ($openFile) { Start-Process $savedFile }
        }
    }
} catch {
    Write-Host "Erreur lors de l'analyse : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($Interactive) {
    Write-Host ""
    Write-Host "Analyse terminée. Appuyez sur une touche pour continuer..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
