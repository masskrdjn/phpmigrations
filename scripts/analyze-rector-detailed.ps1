# ==============================================================================
# RECTOR ANALYSIS - Format Detaille
# Genere un rapport exhaustif avec explications de l'analyse Rector
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
RECTOR ANALYSIS - Format Detaille

SYNOPSIS:
    .\analyze-rector-detailed.ps1 [-ProjectPath <chemin>] [-JsonFile <fichier>] [-OutputFile <fichier>]

DESCRIPTION:
    Genere un rapport exhaustif avec explications detaillees de l'analyse Rector.

PARAMETRES:
    -ProjectPath <chemin>   Chemin du projet PHP analyse
    -JsonFile <fichier>     Fichier JSON de sortie Rector (optionnel)
    -OutputFile <fichier>   Fichier de sauvegarde du rapport
    -Help                   Affiche cette aide

EXEMPLES:
    .\analyze-rector-detailed.ps1 -ProjectPath "C:\mon\projet"
    .\analyze-rector-detailed.ps1 -JsonFile "rector-output.json" -OutputFile "rapport-complet.md"

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

function Get-RectorDetailedInfo {
    param([string]$RectorName)
    
    $rectorInfo = @{
        "AddArrayDefaultToArrayPropertyRector" = @{
            Description = "Ajoute une valeur par defaut [] aux proprietes de type array"
            Benefits = "Evite les erreurs null pointer et clarifie l'intention du code"
            Example = "private array `$items; → private array `$items = [];"
            PHPVersion = "7.4+"
            Category = "Type Safety"
        }
        "CallUserFuncArrayToVariadicRector" = @{
            Description = "Remplace call_user_func_array() par la syntaxe variadic (...)"
            Benefits = "Meilleure performance et lisibilite du code"
            Example = "call_user_func_array(\$func, \$args); → \$func(...\$args);"
            PHPVersion = "5.6+"
            Category = "Modernisation"
        }
        "CountOnNullRector" = @{
            Description = "Ajoute une verification null avant count()"
            Benefits = "Evite les erreurs PHP 7.2+ sur count(null)"
            Example = "count(\$var); → count(\$var ?? []);"
            PHPVersion = "7.2+"
            Category = "Compatibility"
        }
        "ExplicitBoolCompareRector" = @{
            Description = "Utilise des comparaisons explicites avec les booleens"
            Benefits = "Code plus clair et predictible"
            Example = "if (\$var) → if (\$var === true)"
            PHPVersion = "All"
            Category = "Code Quality"
        }
        "StringClassNameToClassConstantRector" = @{
            Description = "Remplace les noms de classe en string par ::class"
            Benefits = "Detection d'erreurs au compile-time et refactoring automatique"
            Example = "'MyClass' → MyClass::class"
            PHPVersion = "5.5+"
            Category = "Type Safety"
        }
        "MixedTypeRector" = @{
            Description = "Ajoute le type 'mixed' aux proprietes et parametres"
            Benefits = "Meilleure documentation du code et aide IDE"
            Example = "function test(\$param) → function test(mixed \$param)"
            PHPVersion = "8.0+"
            Category = "Type Declarations"
        }
        "PropertyPromotionRector" = @{
            Description = "Utilise la promotion des proprietes dans les constructeurs PHP 8"
            Benefits = "Reduit le code boilerplate significativement"
            Example = "public function __construct(\$name) { \$this->name = \$name; } → public function __construct(public string \$name) {}"
            PHPVersion = "8.0+"
            Category = "Modernisation"
        }
        "TypedPropertyRector" = @{
            Description = "Ajoute les types aux proprietes de classe"
            Benefits = "Meilleure validation des donnees et aide au developpement"
            Example = "private \$name; → private string \$name;"
            PHPVersion = "7.4+"
            Category = "Type Declarations"
        }
        "ParamTypeDeclarationRector" = @{
            Description = "Ajoute les types aux parametres de fonction"
            Benefits = "Validation automatique des parametres et meilleure documentation"
            Example = "function test(\$id) → function test(int \$id)"
            PHPVersion = "7.0+"
            Category = "Type Declarations"
        }
        "ReturnTypeDeclarationRector" = @{
            Description = "Ajoute les types de retour aux fonctions"
            Benefits = "Garantit le type de retour et ameliore la documentation"
            Example = "function getName() → function getName(): string"
            PHPVersion = "7.0+"
            Category = "Type Declarations"
        }
    }
    
    if ($rectorInfo.ContainsKey($RectorName)) {
        return $rectorInfo[$RectorName]
    } else {
        return @{
            Description = "Modernisation du code PHP"
            Benefits = "Ameliore la qualite et la performance du code"
            Example = "Voir la documentation Rector"
            PHPVersion = "Variable"
            Category = "General"
        }
    }
}

function Get-CategoryIcon {
    param([string]$Category)
    
    $icons = @{
        "Type Safety" = "🛡️"
        "Modernisation" = "⚡"
        "Compatibility" = "🔄"
        "Code Quality" = "✨"
        "Type Declarations" = "📝"
        "Performance" = "🚀"
        "General" = "🔧"
    }
    
    if ($icons.ContainsKey($Category)) {
        return $icons[$Category]
    } else {
        return "🔧"
    }
}

function Format-DetailedReport {
    param([string]$JsonContent, [string]$ProjectPath)
    
    try {
        $data = $JsonContent | ConvertFrom-Json -ErrorAction Stop
        
        $projectName = if ($ProjectPath) { Split-Path $ProjectPath -Leaf } else { "Projet PHP" }
        
        $report = @"
# 📊 Rapport d'analyse Rector complet - $projectName

**📅 Date**: $(Get-Date -Format "dd/MM/yyyy HH:mm")  
**📁 Projet**: $ProjectPath  
**🔧 Outil**: Rector PHP Analysis Tools v2.0  
**📋 Type**: Analyse complete avec explications

---

## 📈 Resume executif

"@
        
        if ($data.totals) {
            $totalFiles = $data.totals.changed_files + $data.totals.unchanged_files
            $changedFiles = $data.totals.changed_files
            $totalChanges = $data.totals.applied_rectors
            
            $report += @"
| Metrique | Valeur |
|----------|--------|
| **📁 Total fichiers analyses** | $totalFiles |
| **🔄 Fichiers a modifier** | $changedFiles |
| **⚡ Ameliorations proposees** | $totalChanges |
| **📊 Taux d'impact** | $(if($totalFiles -gt 0) { [math]::Round(($changedFiles / $totalFiles) * 100, 1) } else { 0 })% |

"@
            
            if ($changedFiles -gt 0) {
                $complexity = if ($totalChanges -lt 10) { "Faible" } elseif ($totalChanges -lt 30) { "Moderee" } else { "Elevee" }
                $effort = if ($totalChanges -lt 10) { "1-2 heures" } elseif ($totalChanges -lt 30) { "Demi-journee" } else { "1-2 jours" }
                
                $report += @"
### 🎯 Evaluation de l'impact

- **Complexite de migration**: $complexity
- **Effort estime**: $effort
- **Risque**: Faible (dry-run valide)
- **Benefices**: Modernisation et optimisation

"@
            } else {
                $report += @"
### ✅ Statut du projet

**Excellent !** Votre code respecte deja les meilleures pratiques modernes PHP.

"@
            }
        }
        
        if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
            # Statistiques par categories
            $categoriesStats = @{}
            foreach ($file in $data.file_diffs) {
                foreach ($rector in $file.applied_rectors) {
                    $info = Get-RectorDetailedInfo $rector.class
                    $category = $info.Category
                    if (!$categoriesStats.ContainsKey($category)) {
                        $categoriesStats[$category] = 0
                    }
                    $categoriesStats[$category]++
                }
            }
            
            $report += "## 📊 Repartition par categorie`n`n"
            foreach ($category in $categoriesStats.Keys | Sort-Object) {
                $icon = Get-CategoryIcon $category
                $count = $categoriesStats[$category]
                $report += "- $icon **$category**: $count changement$(if($count -gt 1){'s'})`n"
            }
            $report += "`n"
            
            $report += "## 📋 Analyse detaillee par fichier`n`n"
            
            $fileIndex = 1
            foreach ($file in $data.file_diffs) {
                $relativePath = if ($ProjectPath) {
                    $file.file -replace [regex]::Escape($ProjectPath), ""
                } else {
                    Split-Path $file.file -Leaf
                }
                
                $report += "### 📄 Fichier $fileIndex : ``$relativePath```n`n"
                $report += "**📍 Chemin complet**: ``$($file.file)```n"
                $report += "**🔄 Modifications proposees**: $($file.applied_rectors.Count)`n`n"
                
                if ($file.applied_rectors.Count -gt 0) {
                    $report += "#### 🔍 Details des modifications`n`n"
                    
                    $rectorIndex = 1
                    foreach ($rector in $file.applied_rectors) {
                        $info = Get-RectorDetailedInfo $rector.class
                        $icon = Get-CategoryIcon $info.Category
                        
                        $report += "##### $icon Modification $rectorIndex : $($rector.class)`n`n"
                        $report += "| Propriete | Valeur |`n"
                        $report += "|-----------|--------|`n"
                        $report += "| **Description** | $($info.Description) |`n"
                        $report += "| **Benefices** | $($info.Benefits) |`n"
                        $report += "| **PHP Version** | $($info.PHPVersion) |`n"
                        $report += "| **Categorie** | $($info.Category) |`n"
                        
                        if ($rector.line) {
                            $report += "| **Ligne** | $($rector.line) |`n"
                        }
                        
                        $report += "`n"
                        
                        if ($rector.message) {
                            $report += "**💡 Explication technique**:`n"
                            $report += "> $($rector.message)`n`n"
                        }
                        
                        $report += "**📖 Exemple de transformation**:`n"
                        $report += "``````php`n"
                        $report += "$($info.Example)`n"
                        $report += "``````n`n"
                        
                        # Diff specifique si disponible
                        if ($file.diff) {
                            $diffLines = $file.diff -split "`n"
                            $relevantLines = $diffLines | Where-Object { $_ -match "^[\+\-]" -and $_ -notmatch "^[\+\-]{3}" }
                            
                            if ($relevantLines.Count -gt 0) {
                                $report += "**🔄 Changement propose dans ce fichier**:`n"
                                $report += "``````diff`n"
                                foreach ($line in $relevantLines) {
                                    $report += "$line`n"
                                }
                                $report += "``````n`n"
                            }
                        }
                        
                        $rectorIndex++
                        if ($rectorIndex -le $file.applied_rectors.Count) {
                            $report += "---`n`n"
                        }
                    }
                }
                
                $fileIndex++
                $report += "`n"
            }
            
            $report += "## 🎯 Plan d'action recommande`n`n"
            $report += "### Phase 1: Preparation`n"
            $report += "1. **Sauvegarde**: Commitez votre code actuel`n"
            $report += "2. **Tests**: Assurez-vous que vos tests passent`n"
            $report += "3. **Branche**: Creez une branche dediee (ex: `feature/rector-modernization`)`n`n"
            
            $report += "### Phase 2: Application progressive`n"
            foreach ($category in $categoriesStats.Keys | Sort-Object) {
                $icon = Get-CategoryIcon $category
                $report += "1. $icon **$category** ($($categoriesStats[$category]) changements)`n"
                $report += "   ``````bash`n"
                $report += "   # Appliquer uniquement cette categorie`n"
                $report += "   rector process --dry-run | grep '$category'`n"
                $report += "   ``````n"
            }
            $report += "`n"
            
            $report += "### Phase 3: Validation`n"
            $report += "1. **Tests unitaires**: Executez toute la suite de tests`n"
            $report += "2. **Tests fonctionnels**: Verifiez le comportement applicatif`n"
            $report += "3. **Code review**: Faites relire les changements`n"
            $report += "4. **Deployment**: Deployez en staging puis production`n`n"
            
            $report += "## 🛠️ Commandes utiles`n`n"
            $report += "``````bash`n"
            $report += "# Appliquer tous les changements`n"
            $report += "rector process`n`n"
            $report += "# Appliquer par etapes`n"
            foreach ($category in ($categoriesStats.Keys | Sort-Object | Select-Object -First 3)) {
                $report += "rector process --only=Type # Pour $category`n"
            }
            $report += "`n# Exclure certains rectors si necessaire`n"
            $report += "rector process --skip=PropertyPromotionRector`n`n"
            $report += "# Analyser un seul fichier`n"
            $report += "rector process src/specific/file.php --dry-run`n"
            $report += "``````n`n"
            
            $report += "## 📚 Ressources complementaires`n`n"
            $report += "- [Documentation Rector](https://github.com/rectorphp/rector)`n"
            $report += "- [Guide de migration PHP](https://www.php.net/migration74)`n"
            $report += "- [Meilleures pratiques modernes](https://phptherightway.com/)`n"
            $report += "- [Tests de regression](https://phpunit.de/)`n`n"
        }
        
        $report += "---`n`n"
        $report += "📋 **Rapport genere par Rector PHP Analysis Tools v2.0**`n"
        $report += "🕒 **Duree d'analyse**: Quelques secondes`n"
        $report += "🎯 **Objectif**: Modernisation et optimisation du code PHP`n"
        $report += "💡 **Conseil**: Appliquez les changements progressivement et testez regulierement"
        
        return $report
        
    } catch {
        return @"
# ❌ Erreur d'analyse Rector

Une erreur s'est produite lors du traitement de la sortie JSON.

## 🔍 Details de l'erreur:
``````
$($_.Exception.Message)
``````

## 📄 Sortie brute de Rector:
``````json
$JsonContent
``````

## 🛠️ Solutions possibles:
1. **Verifiez l'installation**: `rector --version`
2. **Validez le code PHP**: Recherchez les erreurs de syntaxe
3. **Consultez les logs**: Rector peut avoir des messages specifiques
4. **Testez sur un fichier**: `rector process fichier.php --dry-run`

## 📞 Support:
- Documentation Rector: https://github.com/rectorphp/rector
- Issues GitHub: https://github.com/rectorphp/rector/issues
"@
    }
}

# ==============================================================================
# SCRIPT PRINCIPAL
# ==============================================================================

Write-Host "RECTOR ANALYSIS - Format Detaille" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
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
Write-Host "Generation du rapport detaille..." -ForegroundColor Yellow
Write-Host "Cela peut prendre quelques instants..." -ForegroundColor Yellow
$report = Format-DetailedReport $jsonContent $ProjectPath

# Affichage du rapport
Write-Host ""
Write-Host $report

# Sauvegarde si demandee
if ($OutputFile -ne "") {
    try {
        Set-Content -Path $OutputFile -Value $report -Encoding UTF8
        Write-Host ""
        Write-Host "Rapport detaille sauvegarde: $OutputFile" -ForegroundColor Green
        Write-Host "Taille du rapport: $([math]::Round((Get-Item $OutputFile).Length / 1KB, 1)) KB" -ForegroundColor Cyan
    } catch {
        Write-Host "Erreur lors de la sauvegarde: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Analyse detaillee terminee." -ForegroundColor Green
