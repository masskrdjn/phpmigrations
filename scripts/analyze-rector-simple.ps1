# ==============================================================================
# RECTOR ANALYSIS - Format Simple
# Genere un rapport resume de l'analyse Rector
# ==============================================================================

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectPath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$JsonFile = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile = "",
    
    [switch]$Help = $false
)

if ($Help) {
    Write-Host @"
RECTOR ANALYSIS - Format Simple

SYNOPSIS:
    .\analyze-rector-simple.ps1 [-ProjectPath <chemin>] [-JsonFile <fichier>] [-OutputFile <fichier>]

DESCRIPTION:
    Genere un rapport resume de l'analyse Rector en format lisible.

PARAMETRES:
    -ProjectPath <chemin>   Chemin du projet PHP analyse
    -JsonFile <fichier>     Fichier JSON de sortie Rector (optionnel)
    -OutputFile <fichier>   Fichier de sauvegarde du rapport
    -Help                   Affiche cette aide

EXEMPLES:
    .\analyze-rector-simple.ps1 -ProjectPath "C:\mon\projet"
    .\analyze-rector-simple.ps1 -JsonFile "rector-output.json"

"@ -ForegroundColor Cyan
    exit 0
}

# ==============================================================================
# FONCTIONS
# ==============================================================================

function Get-RectorAnalysis {
    param([string]$ProjectPath)
    
    Write-Host "Execution de l'analyse Rector..." -ForegroundColor Yellow
    
    Push-Location $ProjectPath
    try {
        $rectorBin = if (Test-Path "vendor\bin\rector.bat") {
            "vendor\bin\rector.bat"
        } else {
            "rector"
        }
        
        $output = & $rectorBin process --dry-run --output-format=json 2>&1
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 2) {
            return $output -join "`n"
        } else {
            throw "Erreur Rector (code: $LASTEXITCODE): $($output -join "`n")"
        }
        
    } finally {
        Pop-Location
    }
}

function Format-SimpleReport {
    param([string]$JsonContent, [string]$ProjectPath)
    
    try {
        $data = $JsonContent | ConvertFrom-Json -ErrorAction Stop
        
        $projectName = if ($ProjectPath) { Split-Path $ProjectPath -Leaf } else { "Projet PHP" }
        
        $report = @"
# Analyse Rector - $projectName

**Rapport genere le**: $(Get-Date -Format "dd/MM/yyyy HH:mm")

## Resume

"@
        
        if ($data.totals) {
            $totalFiles = $data.totals.changed_files + $data.totals.unchanged_files
            $changedFiles = $data.totals.changed_files
            $totalChanges = $data.totals.applied_rectors
            
            $report += @"
- **Fichiers analyses**: $totalFiles
- **Fichiers impactes**: $changedFiles
- **Changements detectes**: $totalChanges

"@
            
            if ($changedFiles -gt 0) {
                $report += "## Status: Modernisation recommandee`n"
                $report += "Votre code peut beneficier de $totalChanges ameliorations.`n`n"
            } else {
                $report += "## Status: Code optimise`n"
                $report += "Aucune amelioration detectee - Excellent travail !`n`n"
            }
        }
        
        if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
            $report += "## Fichiers impactes`n`n"
            
            foreach ($file in $data.file_diffs) {
                $relativePath = if ($ProjectPath) {
                    $file.file -replace [regex]::Escape($ProjectPath), ""
                } else {
                    Split-Path $file.file -Leaf
                }
                
                $changeCount = $file.applied_rectors.Count
                $report += "- ``$relativePath`` - $changeCount changement$(if($changeCount -gt 1){'s'}))`n"
            }
            
            $report += "`n## Prochaines etapes`n`n"
            $report += "1. Examinez les changements proposes avec le rapport detaille`n"
            $report += "2. Executez Rector sans --dry-run pour appliquer les changements`n"
            $report += "3. Testez votre application apres les modifications`n"
        }
        
        $report += "`n---`n"
        $report += "*Rapport genere par Rector PHP Analysis Tools*"
        
        return $report
        
    } catch {
        return @"
# Erreur d'analyse

Impossible de parser la sortie JSON de Rector.

## Sortie brute:
``````
$JsonContent
``````

## Erreur:
$($_.Exception.Message)
"@
    }
}

# ==============================================================================
# SCRIPT PRINCIPAL
# ==============================================================================

Write-Host "RECTOR ANALYSIS - Format Simple" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green
Write-Host ""

# Determination de la source des donnees
if ($JsonFile -ne "") {
    if (!(Test-Path $JsonFile)) {
        Write-Host "Erreur: Fichier JSON introuvable: $JsonFile" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Lecture du fichier JSON: $JsonFile" -ForegroundColor Cyan
    $jsonContent = Get-Content $JsonFile -Raw -Encoding UTF8
    
} elseif ($ProjectPath -ne "") {
    if (!(Test-Path $ProjectPath)) {
        Write-Host "Erreur: Projet introuvable: $ProjectPath" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Analyse du projet: $ProjectPath" -ForegroundColor Cyan
    $jsonContent = Get-RectorAnalysis $ProjectPath
    
} else {
    # Utiliser le repertoire actuel
    $ProjectPath = Get-Location
    Write-Host "Analyse du repertoire actuel: $ProjectPath" -ForegroundColor Cyan
    $jsonContent = Get-RectorAnalysis $ProjectPath
}

# Generation du rapport
Write-Host "Generation du rapport..." -ForegroundColor Yellow
$report = Format-SimpleReport $jsonContent $ProjectPath

# Affichage du rapport
Write-Host ""
Write-Host $report

# Sauvegarde si demandee
if ($OutputFile -ne "") {
    try {
        Set-Content -Path $OutputFile -Value $report -Encoding UTF8
        Write-Host ""
        Write-Host "Rapport sauvegarde: $OutputFile" -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de la sauvegarde: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Analyse terminee." -ForegroundColor Green
