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
    [switch]$Help = $false,
    [switch]$ShowHistory = $false,
    [int]$HistoryCount = 10,
    [switch]$ShowLogs = $false
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =============================================================================
# CONFIGURATION DU LOGGING
# =============================================================================

$script:LogDirectory = Join-Path $PSScriptRoot "logs"
$script:LogFile = Join-Path $script:LogDirectory "rector-analysis.log"
$script:AnalysisHistoryFile = Join-Path $script:LogDirectory "analysis-history.json"

# Variable globale pour le lecteur temporaire UNC
$script:TempDriveLetter = $null
$script:OriginalProjectPath = $null

# =============================================================================
# FONCTIONS DE GESTION UNC
# =============================================================================

function Use-UNCPath {
    <#
    .SYNOPSIS
        Gère les chemins UNC en créant un lecteur temporaire si nécessaire
    .DESCRIPTION
        CMD.EXE ne supporte pas les chemins UNC comme répertoire courant.
        Cette fonction crée un lecteur avec 'subst' pour contourner cette limitation.
        Note: On utilise 'subst' au lieu de 'New-PSDrive' car subst crée un vrai
        lecteur Windows visible par tous les processus (CMD, Composer, etc.)
    #>
    param([string]$Path)
    
    # Vérifier si c'est un chemin UNC (commence par \\ ou //)
    if ($Path -match '^\\\\' -or $Path -match '^//') {
        Write-Host "Chemin UNC détecté: $Path" -ForegroundColor Yellow
        Write-Host "Création d'un lecteur temporaire..." -ForegroundColor Yellow
        
        # Trouver une lettre de lecteur disponible (de Z: à M:)
        $availableLetters = @('Z', 'Y', 'X', 'W', 'V', 'U', 'T', 'S', 'R', 'Q', 'P', 'O', 'N', 'M')
        $usedLetters = (Get-PSDrive -PSProvider FileSystem).Name
        
        foreach ($letter in $availableLetters) {
            if ($letter -notin $usedLetters) {
                try {
                    # Utiliser 'subst' pour créer un vrai lecteur Windows
                    $driveLetter = "${letter}:"
                    $null = & subst $driveLetter $Path 2>&1
                    
                    if ($LASTEXITCODE -eq 0 -or (Test-Path $driveLetter)) {
                        $script:TempDriveLetter = $letter
                        $script:OriginalProjectPath = $Path
                        $newPath = "${letter}:\"
                        Write-Host "Lecteur temporaire: $newPath -> $Path" -ForegroundColor Green
                        return $newPath
                    }
                } catch {
                    continue
                }
            }
        }
        
        Write-Host "ATTENTION: Impossible de créer un lecteur temporaire." -ForegroundColor Red
        return $Path
    }
    
    return $Path
}

function Remove-TempDrive {
    <#
    .SYNOPSIS
        Supprime le lecteur temporaire créé pour les chemins UNC
    #>
    if ($script:TempDriveLetter) {
        try {
            $driveLetter = "$($script:TempDriveLetter):"
            $null = & subst /D $driveLetter 2>&1
            Write-Host "Lecteur temporaire $driveLetter supprimé." -ForegroundColor Gray
        } catch { }
        $script:TempDriveLetter = $null
    }
}

# =============================================================================
# FONCTIONS DE LOGGING
# =============================================================================

function Initialize-Logging {
    <#
    .SYNOPSIS
        Initialise le système de logging pour l'analyse Rector
    #>
    
    # Créer le dossier de logs s'il n'existe pas
    if (!(Test-Path $script:LogDirectory)) {
        New-Item -ItemType Directory -Path $script:LogDirectory -Force | Out-Null
    }
    
    # Initialiser le fichier d'historique s'il n'existe pas
    if (!(Test-Path $script:AnalysisHistoryFile)) {
        @{ analyses = @() } | ConvertTo-Json | Set-Content -Path $script:AnalysisHistoryFile -Encoding UTF8
    }
}

function Write-AnalysisLog {
    <#
    .SYNOPSIS
        Écrit une entrée dans le fichier de log
    .PARAMETER Message
        Message à logger
    .PARAMETER Level
        Niveau de log (INFO, WARNING, ERROR, DEBUG)
    #>
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Écrire dans le fichier de log
    Add-Content -Path $script:LogFile -Value $logEntry -Encoding UTF8
    
    # Afficher dans la console selon le niveau
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
    }
    
    if ($Level -ne "DEBUG" -or $env:RECTOR_DEBUG -eq "1") {
        Write-Host $logEntry -ForegroundColor $color
    }
}

function Get-PhpFilesInProject {
    <#
    .SYNOPSIS
        Récupère la liste de tous les fichiers PHP dans un projet
    .PARAMETER ProjectPath
        Chemin du projet à analyser
    .PARAMETER ExcludePaths
        Chemins à exclure (vendor, cache, etc.)
    #>
    param(
        [string]$ProjectPath,
        [string[]]$ExcludePaths = @("vendor", "cache", "tmp", "storage", "var", "node_modules")
    )
    
    $phpFiles = @()
    
    try {
        Get-ChildItem -Path $ProjectPath -Recurse -Filter "*.php" -File -ErrorAction SilentlyContinue | ForEach-Object {
            $relativePath = $_.FullName.Replace($ProjectPath, "").TrimStart("\", "/")
            $excluded = $false
            
            foreach ($excludePath in $ExcludePaths) {
                if ($relativePath.StartsWith($excludePath) -or $relativePath.Contains("\$excludePath\") -or $relativePath.Contains("/$excludePath/")) {
                    $excluded = $true
                    break
                }
            }
            
            if (-not $excluded) {
                $phpFiles += @{
                    FullPath = $_.FullName
                    RelativePath = $relativePath
                    Size = $_.Length
                    LastModified = $_.LastWriteTime
                }
            }
        }
    } catch {
        Write-AnalysisLog "Erreur lors de la récupération des fichiers PHP: $($_.Exception.Message)" -Level "ERROR"
    }
    
    return $phpFiles
}

function Write-AnalysisStart {
    <#
    .SYNOPSIS
        Log le début d'une analyse avec tous les détails
    #>
    param(
        [string]$ProjectPath,
        [string]$ConfigFile,
        [string]$OutputFormat,
        [bool]$DryRun
    )
    
    $separator = "=" * 80
    
    Write-AnalysisLog $separator
    Write-AnalysisLog "DÉBUT DE L'ANALYSE RECTOR"
    Write-AnalysisLog $separator
    Write-AnalysisLog "Projet: $ProjectPath"
    Write-AnalysisLog "Configuration: $ConfigFile"
    Write-AnalysisLog "Format de sortie: $OutputFormat"
    Write-AnalysisLog "Mode Dry-Run: $DryRun"
    Write-AnalysisLog "Utilisateur: $env:USERNAME"
    Write-AnalysisLog "Machine: $env:COMPUTERNAME"
    
    # Extraire la version PHP cible depuis le nom du fichier de config
    $phpVersion = Extract-PhpVersionFromConfig -ConfigFile $ConfigFile
    if ($phpVersion) {
        Write-AnalysisLog "Version PHP cible: $phpVersion"
    }
}

function Extract-PhpVersionFromConfig {
    <#
    .SYNOPSIS
        Extrait la version PHP cible depuis le nom du fichier de configuration
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

function Write-FilesAnalyzedLog {
    <#
    .SYNOPSIS
        Log la liste des fichiers PHP analysés
    #>
    param(
        [string]$ProjectPath,
        [array]$PhpFiles
    )
    
    $separator = "-" * 60
    Write-AnalysisLog $separator
    Write-AnalysisLog "FICHIERS PHP ANALYSÉS: $($PhpFiles.Count) fichiers"
    Write-AnalysisLog $separator
    
    foreach ($file in $PhpFiles) {
        $sizeKb = [math]::Round($file.Size / 1024, 2)
        Write-AnalysisLog "  [SCAN] $($file.RelativePath) ($sizeKb KB)" -Level "DEBUG"
    }
    
    # Résumé par dossier
    $byFolder = $PhpFiles | Group-Object { Split-Path $_.RelativePath -Parent }
    Write-AnalysisLog ""
    Write-AnalysisLog "Répartition par dossier:"
    foreach ($folder in $byFolder | Sort-Object Name) {
        $folderName = if ($folder.Name -eq "") { "(racine)" } else { $folder.Name }
        Write-AnalysisLog "  - $folderName : $($folder.Count) fichiers"
    }
}

function Write-AnalysisResults {
    <#
    .SYNOPSIS
        Log les résultats de l'analyse
    #>
    param(
        [string]$JsonOutput,
        [TimeSpan]$Duration,
        [int]$TotalFiles
    )
    
    try {
        # Nettoyer et parser le JSON
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
            
            $separator = "-" * 60
            Write-AnalysisLog $separator
            Write-AnalysisLog "RÉSULTATS DE L'ANALYSE"
            Write-AnalysisLog $separator
            
            $changedFiles = if ($data.totals.changed_files) { $data.totals.changed_files } else { 0 }
            $errors = if ($data.totals.errors) { $data.totals.errors } else { 0 }
            
            Write-AnalysisLog "Fichiers modifiés: $changedFiles / $TotalFiles"
            Write-AnalysisLog "Erreurs détectées: $errors"
            Write-AnalysisLog "Durée de l'analyse: $($Duration.TotalSeconds.ToString('F2')) secondes"
            
            # Log des règles appliquées
            if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
                Write-AnalysisLog ""
                Write-AnalysisLog "Fichiers avec modifications suggérées:"
                
                $allRectors = @{}
                
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
                
                # Résumé des règles appliquées
                Write-AnalysisLog ""
                Write-AnalysisLog "Règles Rector appliquées:"
                foreach ($rector in $allRectors.GetEnumerator() | Sort-Object Value -Descending) {
                    Write-AnalysisLog "  - $($rector.Key): $($rector.Value) occurrence(s)"
                }
            }
            
            return @{
                ChangedFiles = $changedFiles
                Errors = $errors
                Duration = $Duration.TotalSeconds
                RulesApplied = $allRectors.Keys.Count
            }
        }
    } catch {
        Write-AnalysisLog "Erreur lors du parsing des résultats: $($_.Exception.Message)" -Level "WARNING"
    }
    
    return $null
}

function Write-AnalysisEnd {
    <#
    .SYNOPSIS
        Log la fin de l'analyse
    #>
    param([string]$Status = "SUCCESS")
    
    $separator = "=" * 80
    Write-AnalysisLog $separator
    Write-AnalysisLog "FIN DE L'ANALYSE - Statut: $Status"
    Write-AnalysisLog $separator
    Write-AnalysisLog ""
}

function Save-AnalysisHistory {
    <#
    .SYNOPSIS
        Sauvegarde l'analyse dans l'historique JSON
    #>
    param(
        [string]$ProjectPath,
        [string]$ConfigFile,
        [hashtable]$Results,
        [int]$TotalFiles,
        [string]$Status
    )
    
    try {
        $history = Get-Content -Path $script:AnalysisHistoryFile -Raw | ConvertFrom-Json
        
        $phpVersion = Extract-PhpVersionFromConfig -ConfigFile $ConfigFile
        
        $entry = @{
            id = [guid]::NewGuid().ToString()
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
            project = $ProjectPath
            projectName = Split-Path $ProjectPath -Leaf
            configFile = $ConfigFile
            phpVersionTarget = $phpVersion
            totalFilesScanned = $TotalFiles
            changedFiles = if ($Results) { $Results.ChangedFiles } else { 0 }
            errors = if ($Results) { $Results.Errors } else { 0 }
            duration = if ($Results) { $Results.Duration } else { 0 }
            rulesApplied = if ($Results) { $Results.RulesApplied } else { 0 }
            status = $Status
            user = $env:USERNAME
            machine = $env:COMPUTERNAME
        }
        
        # Ajouter à l'historique (garder les 100 dernières analyses)
        $history.analyses = @($entry) + @($history.analyses) | Select-Object -First 100
        
        $history | ConvertTo-Json -Depth 10 | Set-Content -Path $script:AnalysisHistoryFile -Encoding UTF8
        
        Write-AnalysisLog "Analyse sauvegardée dans l'historique (ID: $($entry.id))"
        
    } catch {
        Write-AnalysisLog "Erreur lors de la sauvegarde de l'historique: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Show-AnalysisHistory {
    <#
    .SYNOPSIS
        Affiche l'historique des analyses
    .PARAMETER Count
        Nombre d'analyses à afficher
    #>
    param([int]$Count = 10)
    
    if (!(Test-Path $script:AnalysisHistoryFile)) {
        Write-Host "Aucun historique disponible." -ForegroundColor Yellow
        return
    }
    
    try {
        $history = Get-Content -Path $script:AnalysisHistoryFile -Raw | ConvertFrom-Json
        
        Write-Host ""
        Write-Host "=" * 80 -ForegroundColor Cyan
        Write-Host "  HISTORIQUE DES ANALYSES RECTOR (dernières $Count)" -ForegroundColor Cyan
        Write-Host "=" * 80 -ForegroundColor Cyan
        Write-Host ""
        
        $analyses = $history.analyses | Select-Object -First $Count
        
        foreach ($analysis in $analyses) {
            $statusColor = if ($analysis.status -eq "SUCCESS") { "Green" } else { "Red" }
            
            Write-Host "  [$($analysis.timestamp)]" -ForegroundColor Gray -NoNewline
            Write-Host " $($analysis.projectName)" -ForegroundColor White -NoNewline
            Write-Host " → PHP $($analysis.phpVersionTarget)" -ForegroundColor Cyan -NoNewline
            Write-Host " | $($analysis.totalFilesScanned) fichiers" -ForegroundColor Gray -NoNewline
            Write-Host " | $($analysis.changedFiles) modifiés" -ForegroundColor Yellow -NoNewline
            Write-Host " | $($analysis.status)" -ForegroundColor $statusColor
        }
        
        Write-Host ""
        Write-Host "  Fichier d'historique: $script:AnalysisHistoryFile" -ForegroundColor Gray
        Write-Host ""
        
    } catch {
        Write-Host "Erreur lors de la lecture de l'historique: $($_.Exception.Message)" -ForegroundColor Red
    }
}

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
    -ShowHistory            Affiche l'historique des analyses
    -HistoryCount <n>       Nombre d'analyses a afficher (defaut: 10)
    -ShowLogs               Ouvre le fichier de logs

EXEMPLES:
    .\rector-analyze.ps1
    .\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -OutputFormat detailed
    .\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -OutputFile "rapport.md" -DryRun:`$false
    .\rector-analyze.ps1 -ShowHistory -HistoryCount 20
    .\rector-analyze.ps1 -ShowLogs

FORMATS DE SORTIE:
    simple     - Resume basique
    readable   - Rapport detaille lisible
    detailed   - Rapport exhaustif avec explications
    json       - Sortie JSON brute

LOGS ET HISTORIQUE:
    Les logs sont sauvegardes dans: logs/rector-analysis.log
    L'historique JSON est dans: logs/analysis-history.json

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

function New-DynamicRectorConfig {
    <#
    .SYNOPSIS
        Génère une configuration Rector dynamique pour le projet analysé
    .DESCRIPTION
        Crée un fichier de configuration temporaire avec les chemins corrects
        du projet à analyser, au lieu d'utiliser __DIR__ qui pointe ailleurs.
    .PARAMETER ProjectPath
        Chemin du projet à analyser
    .PARAMETER BaseConfigFile
        Fichier de configuration de base pour extraire les règles
    .PARAMETER PhpVersion
        Version PHP cible (81, 82, 84)
    #>
    param(
        [string]$ProjectPath,
        [string]$BaseConfigFile,
        [string]$PhpVersion = "81"
    )
    
    # Dossiers à exclure
    $excludeDirs = @('vendor', 'cache', 'tmp', 'storage', 'node_modules', 'logs', 'sessions', 'var', '.git', '.gitlab', 'rector-output', 'rector-configs')
    
    # Détecter tous les dossiers contenant des fichiers .php
    Write-Host "Scan des dossiers contenant des fichiers PHP..." -ForegroundColor Gray
    $foundDirs = @()
    
    try {
        $allSubDirs = Get-ChildItem -Path $ProjectPath -Directory -ErrorAction SilentlyContinue | Where-Object {
            $_.Name -notin $excludeDirs -and -not $_.Name.StartsWith('.')
        }
        
        foreach ($subDir in $allSubDirs) {
            # Vérifier si ce dossier contient des fichiers PHP
            $phpFiles = Get-ChildItem -Path $subDir.FullName -Filter "*.php" -File -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($phpFiles) {
                $foundDirs += $subDir.Name
            }
        }
    } catch {
        Write-Host "Avertissement lors du scan: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Vérifier aussi les fichiers PHP à la racine
    $rootPhpFiles = Get-ChildItem -Path $ProjectPath -Filter "*.php" -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($rootPhpFiles) {
        $foundDirs += '.'
    }
    
    # Résumé
    if ($foundDirs.Count -eq 0) {
        Write-Host "Aucun fichier PHP trouvé, analyse de la racine par défaut..." -ForegroundColor Yellow
        $foundDirs = @('.')
    } else {
        Write-Host "Dossiers PHP détectés ($($foundDirs.Count)): $($foundDirs -join ', ')" -ForegroundColor Cyan
    }
    
    # Déterminer le LevelSetList selon la version PHP
    $levelSet = switch ($PhpVersion) {
        "74" { "LevelSetList::UP_TO_PHP_74" }
        "80" { "LevelSetList::UP_TO_PHP_80" }
        "81" { "LevelSetList::UP_TO_PHP_81" }
        "82" { "LevelSetList::UP_TO_PHP_82" }
        "83" { "LevelSetList::UP_TO_PHP_83" }
        "84" { "LevelSetList::UP_TO_PHP_84" }
        default { "LevelSetList::UP_TO_PHP_81" }
    }
    
    $phpVersionConst = switch ($PhpVersion) {
        "74" { "PHP_74" }
        "80" { "PHP_80" }
        "81" { "PHP_81" }
        "82" { "PHP_82" }
        "83" { "PHP_83" }
        "84" { "PHP_84" }
        default { "PHP_81" }
    }
    
    # Générer les chemins PHP
    $pathsPhp = ($foundDirs | ForEach-Object { "        `$projectRoot . '/$_'" }) -join ",`n"
    $skipsPhp = ($excludeDirs | ForEach-Object { "        `$projectRoot . '/$_'" }) -join ",`n"
    
    # Créer le contenu de la configuration
    $configContent = @"
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;

/**
 * Configuration Rector générée dynamiquement
 * Projet: $ProjectPath
 * Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
 */
return static function (RectorConfig `$rectorConfig): void {
    // Chemin racine du projet (passé via --working-dir ou getcwd)
    `$projectRoot = getcwd();
    
    `$rectorConfig->paths([
$pathsPhp
    ]);

    // Migration vers PHP $PhpVersion
    `$rectorConfig->sets([
        $levelSet,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::EARLY_RETURN,
        SetList::TYPE_DECLARATION,
    ]);

    // Exclusions
    `$rectorConfig->skip([
$skipsPhp
    ]);

    // Parallel processing
    `$rectorConfig->parallel();
};
"@

    # Créer le fichier temporaire
    $tempDir = Join-Path $PSScriptRoot "temp"
    if (!(Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    $tempConfigFile = Join-Path $tempDir "rector-dynamic-php$PhpVersion.php"
    # Écrire en UTF-8 SANS BOM (requis pour PHP strict_types)
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($tempConfigFile, $configContent, $utf8NoBom)
    
    Write-Host "Configuration dynamique générée: $tempConfigFile" -ForegroundColor Green
    Write-AnalysisLog "Configuration dynamique créée pour $($foundDirs.Count) dossiers"
    
    return $tempConfigFile
}

function Run-RectorAnalysis {
    param(
        [string]$ProjectPath,
        [string]$ConfigFile,
        [bool]$DryRun,
        [string]$OutputFormat = "readable"
    )
    
    # Initialiser le logging
    Initialize-Logging
    
    # Démarrer le chrono
    $startTime = Get-Date
    
    # Logger le début de l'analyse
    Write-AnalysisStart -ProjectPath $ProjectPath -ConfigFile $ConfigFile -OutputFormat $OutputFormat -DryRun $DryRun
    
    # Récupérer et logger les fichiers PHP à analyser
    $phpFiles = Get-PhpFilesInProject -ProjectPath $ProjectPath
    Write-FilesAnalyzedLog -ProjectPath $ProjectPath -PhpFiles $phpFiles
    
    Write-Host ""
    Write-Host "Execution de l'analyse Rector..." -ForegroundColor Yellow
    Write-Host "Projet: $ProjectPath" -ForegroundColor Cyan
    Write-Host "Configuration: $ConfigFile" -ForegroundColor Cyan
    Write-Host "Fichiers PHP détectés: $($phpFiles.Count)" -ForegroundColor Cyan
    Write-Host "Mode: $(if ($DryRun) { 'Dry-run (simulation)' } else { 'Application des changements' })" -ForegroundColor Cyan
    Write-Host ""
    
    # Gérer les chemins UNC (WSL, partages réseau)
    $workingPath = Use-UNCPath -Path $ProjectPath
    
    Push-Location $workingPath
    try {
        # Construction de la commande - Chercher Rector dans plusieurs emplacements
        $rectorBin = $null
        
        # 1. Dans le projet analysé
        if (Test-Path "vendor\bin\rector.bat") {
            $rectorBin = "vendor\bin\rector.bat"
        } elseif (Test-Path "vendor\bin\rector") {
            $rectorBin = "vendor\bin\rector"
        }
        
        # 2. Dans le dossier phpmigrations (où le script est installé)
        if (-not $rectorBin) {
            $localRector = Join-Path $PSScriptRoot "vendor\bin\rector"
            $localRectorBat = Join-Path $PSScriptRoot "vendor\bin\rector.bat"
            if (Test-Path $localRectorBat) {
                $rectorBin = $localRectorBat
                Write-Host "Rector trouvé dans phpmigrations" -ForegroundColor Green
            } elseif (Test-Path $localRector) {
                $rectorBin = $localRector
                Write-Host "Rector trouvé dans phpmigrations" -ForegroundColor Green
            }
        }
        
        # 3. Dans le projet d'exemples (fallback)
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
            Write-AnalysisLog "Rector non trouvé - Installation en cours" -Level "WARNING"
            $installScript = Join-Path $PSScriptRoot "scripts\install-rector.ps1"
            if (Test-Path $installScript) {
                & $installScript -ProjectPath $workingPath
                # Revérifier après l'installation
                if (Test-Path "vendor\bin\rector.bat") {
                    $rectorBin = "vendor\bin\rector.bat"
                } elseif (Test-Path "vendor\bin\rector") {
                    $rectorBin = "vendor\bin\rector"
                } else {
                    $exampleProject = Join-Path $PSScriptRoot "examples\sample-php-project"
                    if (Test-Path (Join-Path $exampleProject "vendor\bin\rector.bat")) {
                        $rectorBin = Join-Path $exampleProject "vendor\bin\rector.bat"
                    }
                }
            }
            
            if (-not $rectorBin) {
                Write-AnalysisLog "Rector n'a pas pu être installé" -Level "ERROR"
                Write-AnalysisEnd -Status "FAILED"
                throw "Rector n'a pas pu être installé ou trouvé. Veuillez l'installer manuellement."
            }
        }
        
        Write-AnalysisLog "Rector trouvé: $rectorBin"
        
        # Préparer les arguments et les chemins
        $arguments = @("process", ".")  # Analyser le dossier courant
        if ($DryRun) {
            $arguments += "--dry-run"
        }
        
        # Extraire la version PHP depuis le nom du fichier de config
        $phpVersion = "81"  # Par défaut
        if ($ConfigFile -match "php(\d+)") {
            $phpVersion = $matches[1]
        }
        
        # Générer une configuration dynamique avec les bons chemins
        $dynamicConfig = New-DynamicRectorConfig -ProjectPath $ProjectPath -BaseConfigFile $ConfigFile -PhpVersion $phpVersion
        $configPath = $dynamicConfig
        
        $arguments += @("--output-format=json", "--config=$configPath")
        
        Write-Host "Commande: $rectorBin $($arguments -join ' ')" -ForegroundColor Gray
        Write-Host "Configuration: $configPath" -ForegroundColor Gray
        Write-Host ""
        
        Write-AnalysisLog "Commande exécutée: $rectorBin $($arguments -join ' ')"
        
        # Execution
        $output = & $rectorBin $arguments 2>&1
        $exitCode = $LASTEXITCODE
        
        # Calculer la durée
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Logger les résultats
        $results = Write-AnalysisResults -JsonOutput ($output -join "`n") -Duration $duration -TotalFiles $phpFiles.Count
        
        if ($exitCode -eq 0) {
            Write-Host "Analyse terminee avec succes." -ForegroundColor Green
            Write-AnalysisEnd -Status "SUCCESS"
            Save-AnalysisHistory -ProjectPath $ProjectPath -ConfigFile $ConfigFile -Results $results -TotalFiles $phpFiles.Count -Status "SUCCESS"
            return $output -join "`n"
        } else {
            Write-Host "Analyse terminee avec des avertissements (code: $exitCode)." -ForegroundColor Yellow
            Write-AnalysisEnd -Status "WARNING"
            Save-AnalysisHistory -ProjectPath $ProjectPath -ConfigFile $ConfigFile -Results $results -TotalFiles $phpFiles.Count -Status "WARNING"
            return $output -join "`n"
        }
        
    } catch {
        Write-Host "Erreur lors de l'analyse: $($_.Exception.Message)" -ForegroundColor Red
        Write-AnalysisLog "Erreur: $($_.Exception.Message)" -Level "ERROR"
        Write-AnalysisEnd -Status "FAILED"
        Save-AnalysisHistory -ProjectPath $ProjectPath -ConfigFile $ConfigFile -Results $null -TotalFiles $phpFiles.Count -Status "FAILED"
        throw
    } finally {
        Pop-Location
        Remove-TempDrive
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

# Initialiser le logging dès le départ
Initialize-Logging

if ($Help) {
    Show-Help
    exit 0
}

# Afficher l'historique si demandé
if ($ShowHistory) {
    Show-Header
    Show-AnalysisHistory -Count $HistoryCount
    exit 0
}

# Ouvrir les logs si demandé
if ($ShowLogs) {
    if (Test-Path $script:LogFile) {
        Write-Host "Ouverture du fichier de logs: $script:LogFile" -ForegroundColor Green
        Start-Process $script:LogFile
    } else {
        Write-Host "Aucun fichier de log trouvé. Lancez d'abord une analyse." -ForegroundColor Yellow
    }
    exit 0
}

Show-Header

if ($Interactive) {
    Write-Host "Mode interactif - Configuration de l'analyse" -ForegroundColor Cyan
    Write-Host ""
    
    # Option pour consulter l'historique
    Write-Host "Que souhaitez-vous faire ?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Lancer une nouvelle analyse"
    Write-Host "2. Consulter l'historique des analyses"
    Write-Host "3. Ouvrir les fichiers de logs"
    Write-Host "4. Quitter"
    Write-Host ""
    
    $mainChoice = Read-Host "Votre choix (1-4)"
    
    switch ($mainChoice) {
        "2" {
            Show-AnalysisHistory -Count 15
            Write-Host ""
            $continue = Read-Host "Lancer une nouvelle analyse ? (o/N)"
            if ($continue -ne "o" -and $continue -ne "O") {
                exit 0
            }
            Write-Host ""
        }
        "3" {
            Write-Host ""
            Write-Host "Fichiers de logs disponibles:" -ForegroundColor Cyan
            Write-Host "  1. Fichier de log principal: $script:LogFile"
            Write-Host "  2. Historique JSON: $script:AnalysisHistoryFile"
            Write-Host ""
            $logChoice = Read-Host "Ouvrir quel fichier ? (1-2)"
            
            if ($logChoice -eq "1" -and (Test-Path $script:LogFile)) {
                Start-Process $script:LogFile
            } elseif ($logChoice -eq "2" -and (Test-Path $script:AnalysisHistoryFile)) {
                Start-Process $script:AnalysisHistoryFile
            } else {
                Write-Host "Fichier non trouvé ou choix invalide." -ForegroundColor Red
            }
            exit 0
        }
        "4" {
            Write-Host "Au revoir !" -ForegroundColor Green
            exit 0
        }
        default {
            # Continuer avec l'analyse (choix 1 ou autre)
        }
    }
    
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
