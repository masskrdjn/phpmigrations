# ==============================================================================
# RECTOR ANALYSIS - Format Lisible
# Genere un rapport detaille et lisible de l'analyse Rector
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
RECTOR ANALYSIS - Format Lisible

SYNOPSIS:
    .\analyze-rector-readable.ps1 [-ProjectPath <chemin>] [-JsonFile <fichier>] [-OutputFile <fichier>]

DESCRIPTION:
    Genere un rapport detaille et lisible de l'analyse Rector.

PARAMETRES:
    -ProjectPath <chemin>   Chemin du projet PHP analyse
    -JsonFile <fichier>     Fichier JSON de sortie Rector (optionnel)
    -OutputFile <fichier>   Fichier de sauvegarde du rapport
    -Help                   Affiche cette aide

EXEMPLES:
    .\analyze-rector-readable.ps1 -ProjectPath "C:\mon\projet"
    .\analyze-rector-readable.ps1 -JsonFile "rector-output.json" -OutputFile "rapport.md"

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

function Get-RectorDescription {
    param([string]$RectorName)
    
    $descriptions = @{
        "AddArrayDefaultToArrayPropertyRector" = "Ajoute une valeur par defaut [] aux proprietes de type array"
        "CallUserFuncArrayToVariadicRector" = "Remplace call_user_func_array() par la syntaxe variadic (...)"
        "CountOnNullRector" = "Ajoute une verification null avant count()"
        "ExplicitBoolCompareRector" = "Utilise des comparaisons explicites avec les booleens"
        "StringClassNameToClassConstantRector" = "Remplace les noms de classe en string par ::class"
        "MixedTypeRector" = "Ajoute le type 'mixed' aux proprietes et parametres"
        "PropertyPromotionRector" = "Utilise la promotion des proprietes dans les constructeurs PHP 8"
        "MatchToSwitchRector" = "Convertit match() en switch pour la compatibilite"
        "NewInInitializerRector" = "Utilise 'new' dans les initialiseurs de proprietes PHP 8.1"
        "CombinedAssignRector" = "Utilise les operateurs d'assignation combines (+=, -=, etc.)"
        "SimplifyRegexPatternRector" = "Simplifie les patterns regex complexes"
        "RemoveUnusedVariableAssignRector" = "Supprime les assignations de variables inutilisees"
        "CompactToVariablesRector" = "Remplace compact() par un tableau explicite"
        "ArrayKeyExistsOnPropertyRector" = "Utilise property_exists() au lieu de array_key_exists() sur les objets"
        "UnwrapSprintfOneArgumentRector" = "Supprime sprintf() inutile avec un seul argument"
        "InlineConstructorDefaultToPropertyRector" = "Inline les valeurs par defaut dans les proprietes"
        "FlipTypeControlToUseExclusiveTypeRector" = "Optimise les verifications de type"
        "CompleteDynamicPropertiesRector" = "Ajoute #[AllowDynamicProperties] pour PHP 8.2"
        "TypedPropertyRector" = "Ajoute les types aux proprietes de classe"
        "ParamTypeDeclarationRector" = "Ajoute les types aux parametres de fonction"
        "ReturnTypeDeclarationRector" = "Ajoute les types de retour aux fonctions"
    }
    
    if ($descriptions.ContainsKey($RectorName)) {
        return $descriptions[$RectorName]
    } else {
        return "Modernisation du code PHP"
    }
}

function Format-ReadableReport {
    param([string]$JsonContent, [string]$ProjectPath)
    
    try {
        $data = $JsonContent | ConvertFrom-Json -ErrorAction Stop
        
        $projectName = if ($ProjectPath) { Split-Path $ProjectPath -Leaf } else { "Projet PHP" }
        
        $report = @"
# Rapport d'analyse Rector - $projectName

**Date**: $(Get-Date -Format "dd/MM/yyyy HH:mm")  
**Projet**: $ProjectPath  
**Outil**: Rector PHP Analysis Tools

## Resume executif

"@
        
        if ($data.totals) {
            $totalFiles = $data.totals.changed_files + $data.totals.unchanged_files
            $changedFiles = $data.totals.changed_files
            $totalChanges = $data.totals.applied_rectors
            
            $report += @"
- **Total de fichiers analyses**: $totalFiles
- **Fichiers necessitant des modifications**: $changedFiles
- **Nombre total d'ameliorations proposees**: $totalChanges

"@
            
            if ($changedFiles -gt 0) {
                $percentage = [math]::Round(($changedFiles / $totalFiles) * 100, 1)
                $report += "**Impact**: $percentage% de votre code peut etre modernise.`n`n"
                
                $report += "## Recommandations`n`n"
                if ($percentage -lt 20) {
                    $report += "Votre code est globalement moderne. Les changements proposes sont des optimisations mineures.`n"
                } elseif ($percentage -lt 50) {
                    $report += "Votre code beneficierait de quelques modernisations pour optimiser les performances et la lisibilite.`n"
                } else {
                    $report += "Une modernisation significative est recommandee pour tirer parti des dernieres fonctionnalites PHP.`n"
                }
                $report += "`n"
            } else {
                $report += "**Excellent !** Votre code est deja parfaitement modernise.`n`n"
            }
        }
        
        if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
            $report += "## Analyse detaillee par fichier`n`n"
            
            foreach ($file in $data.file_diffs) {
                $relativePath = if ($ProjectPath) {
                    $file.file -replace [regex]::Escape($ProjectPath), ""
                } else {
                    Split-Path $file.file -Leaf
                }
                
                $report += "### $relativePath`n`n"
                $report += "**Modifications proposees**: $($file.applied_rectors.Count)`n`n"
                
                foreach ($rector in $file.applied_rectors) {
                    $description = Get-RectorDescription $rector.class
                    $report += "#### $($rector.class)`n"
                    $report += "*$description*`n`n"
                    
                    if ($rector.line) {
                        $report += "**Ligne**: $($rector.line)`n`n"
                    }
                    
                    if ($rector.message) {
                        $report += "**Explication**: $($rector.message)`n`n"
                    }
                    
                    # Affichage du diff si disponible
                    if ($file.diff) {
                        $diffLines = $file.diff -split "`n"
                        $relevantLines = $diffLines | Where-Object { $_ -match "^[\+\-]" -and $_ -notmatch "^[\+\-]{3}" }
                        
                        if ($relevantLines.Count -gt 0) {
                            $report += "**Changement propose**:`n"
                            $report += "``````diff`n"
                            foreach ($line in $relevantLines) {
                                $report += "$line`n"
                            }
                            $report += "``````n`n"
                        }
                    }
                    
                    $report += "---`n`n"
                }
            }
            
            $report += "## Actions recommandees`n`n"
            $report += "1. **Examinez chaque changement** - Verifiez que les modifications correspondent a vos attentes`n"
            $report += "2. **Testez en isolation** - Appliquez les changements par petits groupes`n"
            $report += "3. **Executez vos tests** - Assurez-vous que tout fonctionne apres les modifications`n"
            $report += "4. **Commitez progressivement** - Divisez les changements en plusieurs commits logiques`n`n"
            
            $report += "## Commandes utiles`n`n"
            $report += "``````bash`n"
            $report += "# Appliquer tous les changements`n"
            $report += "rector process`n`n"
            $report += "# Appliquer uniquement un type de rector`n"
            $report += "rector process --only=AddArrayDefaultToArrayPropertyRector`n`n"
            $report += "# Exclure certains rectors`n"
            $report += "rector process --except=PropertyPromotionRector`n"
            $report += "``````n`n"
        }
        
        $report += "---`n"
        $report += "*Rapport genere par Rector PHP Analysis Tools v2.0*`n"
        $report += "*Pour plus d'informations: https://github.com/rectorphp/rector*"
        
        return $report
        
    } catch {
        return @"
# Erreur d'analyse Rector

Une erreur s'est produite lors du traitement de la sortie JSON.

## Details de l'erreur:
$($_.Exception.Message)

## Sortie brute de Rector:
``````
$JsonContent
``````

## Suggestions:
1. Verifiez que Rector est correctement installe
2. Assurez-vous que le projet contient du code PHP valide
3. Consultez les logs Rector pour plus de details
"@
    }
}

# ==============================================================================
# SCRIPT PRINCIPAL
# ==============================================================================

Write-Host "RECTOR ANALYSIS - Format Lisible" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
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
Write-Host "Generation du rapport lisible..." -ForegroundColor Yellow
$report = Format-ReadableReport $jsonContent $ProjectPath

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
