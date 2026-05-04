# ==============================================================================
# RECTOR ANALYSIS - Format Détaillé (groupé par catégorie + plan d'action)
# Génère un rapport Markdown exhaustif avec exemples, diffs, et plan de migration.
# ==============================================================================

param(
    [string]$JsonFile,
    [string]$ProjectPath
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# =============================================================================
# CATÉGORISATION
# =============================================================================

$script:CategoryLabels = @{
    "TypeDeclaration"      = "Déclarations de types"
    "DeadCode"             = "Suppression de code mort"
    "CodeQuality"          = "Qualité du code"
    "CodingStyle"          = "Style de code"
    "EarlyReturn"          = "Retours anticipés"
    "Privatization"        = "Encapsulation"
    "StrictBooleans"       = "Comparaisons booléennes strictes"
    "Strict"               = "Vérifications strictes"
    "Naming"               = "Nommage"
    "Instanceof"           = "Vérifications instanceof"
    "Visibility"           = "Visibilité"
    "Removing"             = "Refactoring (suppression)"
    "RemovingStatic"       = "Conversion statique → instance"
    "Carbon"               = "Carbon (dates)"
    "Renaming"             = "Renommages"
    "Transform"            = "Transformations"
    "Defluent"             = "Conversion fluent → chaînées"
    "Arguments"            = "Arguments de fonctions"
    "Restoration"          = "Restauration de code"
    "MysqlToMysqli"        = "MySQL vers MySQLi"
    "DependencyInjection"  = "Injection de dépendances"
}

$script:CategoryRisk = @{
    "TypeDeclaration" = "Faible — ajoute des annotations sans changer le comportement"
    "DeadCode"        = "Très faible — supprime du code inutilisé"
    "CodeQuality"     = "Faible — réécritures équivalentes"
    "CodingStyle"     = "Très faible — cosmétique"
    "EarlyReturn"     = "Faible — réordonnance de la logique"
    "Privatization"   = "Moyen — peut casser des héritages externes"
    "StrictBooleans"  = "Moyen — peut révéler des bugs latents (nul vs false)"
    "Strict"          = "Moyen"
    "Naming"          = "Élevé — change des noms publics, vérifier les call sites"
    "Instanceof"      = "Faible"
    "Visibility"      = "Élevé — change la signature publique"
    "Removing"        = "Moyen"
    "RemovingStatic"  = "Élevé — change la signature, casse les call sites externes"
    "Carbon"          = "Faible"
    "Renaming"        = "Élevé"
    "Transform"       = "Variable"
    "Defluent"        = "Faible"
    "Arguments"       = "Moyen"
    "Restoration"     = "Faible"
}

function Get-RectorCategory {
    param([string]$RectorClass)
    $segments = $RectorClass -split '\\'
    if ($segments.Count -lt 2) { return @{ Key = "Other"; Label = "Autres"; Risk = "Variable" } }
    $key = $segments[1]

    if ($key -match '^Php(\d{2})$') {
        $v = $matches[1]
        return @{
            Key   = $key
            Label = "Migration PHP $($v.Substring(0,1)).$($v.Substring(1))"
            Risk  = "Variable selon la règle (consulter le détail)"
        }
    }
    if ($script:CategoryLabels.ContainsKey($key)) {
        $risk = if ($script:CategoryRisk.ContainsKey($key)) { $script:CategoryRisk[$key] } else { "Variable" }
        return @{ Key = $key; Label = $script:CategoryLabels[$key]; Risk = $risk }
    }
    return @{ Key = $key; Label = $key; Risk = "Variable" }
}

# =============================================================================
# DESCRIPTIONS DÉTAILLÉES
# =============================================================================

$script:RectorDetails = @{
    "AddArrayDefaultToArrayProperty" = @{
        Description = "Ajoute une valeur par défaut [] aux propriétés de type array"
        Benefit     = "Évite les erreurs null pointer et clarifie l'intention du code"
        Example     = "private array `$items; → private array `$items = [];"
    }
    "CallUserFuncArrayToVariadic" = @{
        Description = "Remplace call_user_func_array() par la syntaxe variadic (...)"
        Benefit     = "Meilleure performance et lisibilité"
        Example     = "call_user_func_array(`$func, `$args); → `$func(...`$args);"
    }
    "CountOnNull" = @{
        Description = "Ajoute une vérification null avant count()"
        Benefit     = "Évite les erreurs PHP 7.2+ sur count(null)"
        Example     = "count(`$var); → count(`$var ?? []);"
    }
    "ExplicitBoolCompare" = @{
        Description = "Utilise des comparaisons explicites avec les booléens"
        Benefit     = "Code plus clair et prédictible"
        Example     = "if (`$var) → if (`$var === true)"
    }
    "StringClassNameToClassConstant" = @{
        Description = "Remplace les noms de classe en string par ::class"
        Benefit     = "Détection d'erreurs au compile-time, refactoring automatique"
        Example     = "'MyClass' → MyClass::class"
    }
    "PropertyPromotion" = @{
        Description = "Promotion des propriétés dans les constructeurs (PHP 8)"
        Benefit     = "Réduit drastiquement le code boilerplate"
        Example     = "public function __construct(`$name) { `$this->name = `$name; } → public function __construct(public string `$name) {}"
    }
    "TypedProperty" = @{
        Description = "Ajoute les types aux propriétés de classe"
        Benefit     = "Validation automatique et meilleure documentation"
        Example     = "private `$name; → private string `$name;"
    }
    "ParamTypeDeclaration" = @{
        Description = "Ajoute les types aux paramètres de fonction"
        Benefit     = "Validation automatique des paramètres"
        Example     = "function test(`$id) → function test(int `$id)"
    }
    "ReturnTypeDeclaration" = @{
        Description = "Ajoute les types de retour aux fonctions"
        Benefit     = "Garantit le type de retour et améliore la documentation"
        Example     = "function getName() → function getName(): string"
    }
    "ChangeSwitchToMatch" = @{
        Description = "Convertit switch en match (PHP 8.0)"
        Benefit     = "Syntaxe concise, expression typée, pas de fall-through implicite"
        Example     = "switch(`$x){ case 1: `$y=2;break; } → `$y = match(`$x){ 1 => 2 };"
    }
    "ClosureToArrowFunction" = @{
        Description = "Conversion des closures simples en fonctions fléchées"
        Benefit     = "Syntaxe plus courte, capture automatique des variables"
        Example     = "function(`$x) { return `$x*2; } → fn(`$x) => `$x*2"
    }
    "TernaryToNullCoalescing" = @{
        Description = "Remplace le ternaire par l'opérateur de coalescence nulle (??)"
        Benefit     = "Plus court, sémantiquement plus précis (vérifie null, pas falsy)"
        Example     = "isset(`$a) ? `$a : `$b → `$a ?? `$b"
    }
    "RemoveUnreachableStatement" = @{
        Description = "Supprime du code inaccessible (après return/throw)"
        Benefit     = "Élimine du code mort qui prête à confusion"
        Example     = "return 1; echo 'jamais'; → return 1;"
    }
    "RemoveAlwaysElse" = @{
        Description = "Supprime le 'else' inutile après un return/throw"
        Benefit     = "Réduit l'indentation et améliore la lisibilité"
        Example     = "if (`$x) return 1; else return 2; → if (`$x) return 1; return 2;"
    }
    "AddVoidReturnTypeWhereNoReturn" = @{
        Description = "Ajoute ': void' aux fonctions qui ne retournent rien"
        Benefit     = "Documentation explicite du contrat de la fonction"
        Example     = "function log(`$msg) { echo `$msg; } → function log(`$msg): void { echo `$msg; }"
    }
    "StrContains" = @{
        Description = "Utilisation de str_contains() (PHP 8.0)"
        Benefit     = "Plus expressif et plus lisible que strpos()"
        Example     = "strpos(`$s, 'x') !== false → str_contains(`$s, 'x')"
    }
    "StrStartsWith" = @{
        Description = "Utilisation de str_starts_with() (PHP 8.0)"
        Benefit     = "Plus expressif que strpos()"
        Example     = "strpos(`$s, 'x') === 0 → str_starts_with(`$s, 'x')"
    }
    "ChangeArrayPushToArrayAssign" = @{
        Description = "Remplace array_push(`$a, `$x) par `$a[] = `$x"
        Benefit     = "Plus rapide (pas d'appel de fonction) et plus idiomatique"
        Example     = "array_push(`$arr, `$item); → `$arr[] = `$item;"
    }
    "LongArrayToShortArray" = @{
        Description = "Syntaxe courte de tableau"
        Benefit     = "Standard depuis PHP 5.4, plus lisible"
        Example     = "array(1, 2, 3) → [1, 2, 3]"
    }
}

# =============================================================================
# DESCRIPTIONS COURTES (réutilisées si pas de fiche détaillée)
# =============================================================================

$script:RectorDescriptions = @{
    "UseIdenticalOverEqualWithSameType"           = "Préférer === à == lorsque les types sont identiques"
    "CompleteMissingIfElseBracket"                = "Ajout des accolades manquantes aux blocs if/else"
    "AbsolutizeRequireAndIncludePath"             = "Utilisation de chemins absolus pour require/include"
    "RemoveUnusedForeachKey"                      = "Suppression des variables de clé inutilisées dans les foreach"
    "TypedPropertyFromAssigns"                    = "Typage des propriétés basé sur les assignations"
    "IssetOnPropertyObjectToPropertyExists"       = "isset(`$obj->prop) → property_exists()"
    "RemoveUselessReturnTag"                      = "Suppression des @return redondantes"
    "ClassPropertyAssignToConstructorPromotion"   = "Promotion des propriétés dans le constructeur"
    "DirNameFileConstantToDirConstant"            = "dirname(__FILE__) → __DIR__"
    "RemoveUnusedVariableAssign"                  = "Suppression d'assignation de variable inutilisée"
    "RemoveDeadReturn"                            = "Suppression de return inutile"
    "RemoveAlwaysTrueIfCondition"                 = "Suppression de condition if toujours vraie"
    "PowToExp"                                    = "Utilisation de l'opérateur **"
    "TernaryToElvis"                              = "Ternaire → opérateur Elvis (?:)"
    "SimplifyUselessVariable"                     = "Suppression de variables intermédiaires inutiles"
    "ShortenElseIf"                               = "else { if } → elseif"
    "AddOverrideAttributeToOverriddenMethods"     = "Ajout de #[Override] (PHP 8.3)"
    "InlineConstructorDefaultToProperty"          = "Promotion des propriétés du constructeur"
    "ChangeIfElseValueAssignToEarlyReturn"        = "if/else assignant → retour anticipé"
    "ReturnEarlyIfVariable"                       = "Retour anticipé"
}

# =============================================================================
# UTILITAIRES
# =============================================================================

function Get-LineNumbersFromDiff {
    param([string]$DiffContent)
    if (-not $DiffContent) { return "" }
    $lines = @()
    $rxMatches = [regex]::Matches($DiffContent, '@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@')
    foreach ($m in $rxMatches) {
        $startLine = $m.Groups[1].Value
        $count = if ($m.Groups[2].Success) { $m.Groups[2].Value } else { 1 }
        if ($count -gt 1) {
            $endLine = [int]$startLine + [int]$count - 1
            $lines += "$startLine-$endLine"
        } else {
            $lines += "$startLine"
        }
    }
    return $lines -join ", "
}

function Get-RectorShortName {
    param([string]$RectorClass)
    $shortName = ($RectorClass -split '\\')[-1]
    return $shortName -replace 'Rector$', ''
}

function Get-RectorInfo {
    param([string]$RectorClass)
    $shortName = Get-RectorShortName $RectorClass
    if ($script:RectorDetails.ContainsKey($shortName)) {
        $d = $script:RectorDetails[$shortName]
        return @{
            ShortName   = $shortName
            Description = $d.Description
            Benefit     = $d.Benefit
            Example     = $d.Example
            HasExample  = $true
        }
    }
    $desc = if ($script:RectorDescriptions.ContainsKey($shortName)) {
        $script:RectorDescriptions[$shortName]
    } else {
        ($shortName -creplace '([A-Z])', ' $1').Trim()
    }
    return @{
        ShortName   = $shortName
        Description = $desc
        Benefit     = "Modernise et fiabilise le code"
        Example     = "Voir la documentation officielle Rector pour cette règle"
        HasExample  = $false
    }
}

function Get-RelativePath {
    param([string]$FullPath, [string]$ProjectPath)
    if (-not $ProjectPath) { return $FullPath }
    return $FullPath.Replace($ProjectPath, "") -replace "^[/\\]+", ""
}

function Get-EffortEstimate {
    param([int]$TotalChanges)
    if ($TotalChanges -lt 10)  { return @{ Complexity = "Faible";   Effort = "1 à 2 heures" } }
    if ($TotalChanges -lt 30)  { return @{ Complexity = "Modérée";  Effort = "Demi-journée" } }
    if ($TotalChanges -lt 100) { return @{ Complexity = "Élevée";   Effort = "1 à 2 jours" } }
    return @{ Complexity = "Très élevée"; Effort = "Plus de 2 jours, à fragmenter" }
}

# =============================================================================
# PIPELINE PRINCIPAL
# =============================================================================

try {
    if (-not (Test-Path $JsonFile)) {
        throw "Fichier JSON introuvable: $JsonFile"
    }

    $jsonContent = Get-Content -Path $JsonFile -Raw -Encoding UTF8
    $jsonStart = $jsonContent.IndexOf('{')
    $jsonEnd   = $jsonContent.LastIndexOf('}')
    if ($jsonStart -ge 0 -and $jsonEnd -gt $jsonStart) {
        $jsonContent = $jsonContent.Substring($jsonStart, $jsonEnd - $jsonStart + 1)
    }
    $data = $jsonContent | ConvertFrom-Json -ErrorAction Stop

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Rapport d'analyse Rector - Format détaillé")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Projet** : $ProjectPath")
    [void]$sb.AppendLine("**Date**   : $(Get-Date -Format 'dd/MM/yyyy HH:mm')")
    [void]$sb.AppendLine("**Outil**  : Rector PHP Analysis Tools v2.1")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("")

    # Résumé exécutif - on calcule totalChanges depuis file_diffs (Rector ne le fournit pas toujours)
    $changedFiles = 0; $errors = 0; $totalChanges = 0
    if ($data.totals) {
        $changedFiles = if ($data.totals.changed_files) { $data.totals.changed_files } else { 0 }
        $errors       = if ($data.totals.errors)        { $data.totals.errors }        else { 0 }
    }
    if ($data.file_diffs) {
        foreach ($f in $data.file_diffs) {
            if ($f.applied_rectors) { $totalChanges += $f.applied_rectors.Count }
        }
    }

    [void]$sb.AppendLine("## Résumé exécutif")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Métrique | Valeur |")
    [void]$sb.AppendLine("|----------|-------:|")
    [void]$sb.AppendLine("| Fichiers à modifier   | $changedFiles |")
    [void]$sb.AppendLine("| Modifications totales | $totalChanges |")
    [void]$sb.AppendLine("| Erreurs détectées     | $errors |")
    [void]$sb.AppendLine("")

    if (-not $data.file_diffs -or $data.file_diffs.Count -eq 0) {
        [void]$sb.AppendLine("**Excellent !** Votre code respecte déjà les pratiques modernes pour cette version PHP.")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("---")
        [void]$sb.AppendLine("*Rapport généré par Rector PHP Analysis Tools v2.1*")
        $sb.ToString()
        exit 0
    }

    $effort = Get-EffortEstimate -TotalChanges $totalChanges
    [void]$sb.AppendLine("### Estimation d'effort")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("- **Complexité** : $($effort.Complexity)")
    [void]$sb.AppendLine("- **Effort estimé** : $($effort.Effort)")
    [void]$sb.AppendLine("- **Risque global** : Faible si le dry-run a été validé")
    [void]$sb.AppendLine("")

    # ============================================================
    # AGRÉGATION
    # ============================================================
    $byCategory = [ordered]@{}

    foreach ($file in $data.file_diffs) {
        $relPath = Get-RelativePath -FullPath $file.file -ProjectPath $ProjectPath
        $impactedLines = Get-LineNumbersFromDiff -DiffContent $file.diff

        foreach ($rector in $file.applied_rectors) {
            $rectorClass = if ($rector -is [string]) { $rector } elseif ($rector.class) { $rector.class } else { "$rector" }
            $cat = Get-RectorCategory -RectorClass $rectorClass
            $catKey = $cat.Key

            if (-not $byCategory.Contains($catKey)) {
                $byCategory[$catKey] = @{
                    Label            = $cat.Label
                    Risk             = $cat.Risk
                    Rules            = [ordered]@{}
                    TotalOccurrences = 0
                    TouchedFiles     = New-Object System.Collections.Generic.HashSet[string]
                }
            }
            $byCategory[$catKey].TotalOccurrences++
            [void]$byCategory[$catKey].TouchedFiles.Add($relPath)

            if (-not $byCategory[$catKey].Rules.Contains($rectorClass)) {
                $info = Get-RectorInfo -RectorClass $rectorClass
                $byCategory[$catKey].Rules[$rectorClass] = @{
                    Info        = $info
                    Occurrences = 0
                    Files       = New-Object System.Collections.ArrayList
                    Diff        = $file.diff
                }
            }
            $byCategory[$catKey].Rules[$rectorClass].Occurrences++
            [void]$byCategory[$catKey].Rules[$rectorClass].Files.Add([PSCustomObject]@{
                Path  = $relPath
                Lines = $impactedLines
                Diff  = $file.diff
            })
        }
    }

    $orderedCategories = $byCategory.Keys | Sort-Object -Property @{ Expression = { -$byCategory[$_].TotalOccurrences } }

    # ============================================================
    # TABLEAU SYNTHÈSE
    # ============================================================
    [void]$sb.AppendLine("## Synthèse par catégorie")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Catégorie | Règles | Occurrences | Fichiers | Risque |")
    [void]$sb.AppendLine("|-----------|-------:|------------:|---------:|:-------|")
    foreach ($k in $orderedCategories) {
        $c = $byCategory[$k]
        [void]$sb.AppendLine("| $($c.Label) | $($c.Rules.Keys.Count) | $($c.TotalOccurrences) | $($c.TouchedFiles.Count) | $($c.Risk) |")
    }
    [void]$sb.AppendLine("")

    # ============================================================
    # DÉTAIL PAR CATÉGORIE
    # ============================================================
    [void]$sb.AppendLine("## Détail par catégorie")
    [void]$sb.AppendLine("")

    foreach ($k in $orderedCategories) {
        $c = $byCategory[$k]
        [void]$sb.AppendLine("### $($c.Label)")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("- **Occurrences** : $($c.TotalOccurrences)")
        [void]$sb.AppendLine("- **Fichiers touchés** : $($c.TouchedFiles.Count)")
        [void]$sb.AppendLine("- **Risque** : $($c.Risk)")
        [void]$sb.AppendLine("")

        $orderedRules = $c.Rules.Keys | Sort-Object -Property @{ Expression = { -$c.Rules[$_].Occurrences } }
        foreach ($r in $orderedRules) {
            $rule = $c.Rules[$r]
            $info = $rule.Info
            [void]$sb.AppendLine("#### $($info.ShortName) ($($rule.Occurrences) occurrence(s))")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**Description** : $($info.Description)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**Bénéfice** : $($info.Benefit)")
            [void]$sb.AppendLine("")
            [void]$sb.AppendLine("**Exemple** :")
            [void]$sb.AppendLine('```php')
            [void]$sb.AppendLine($info.Example)
            [void]$sb.AppendLine('```')
            [void]$sb.AppendLine("")

            [void]$sb.AppendLine("**Fichiers concernés** :")
            $filesGrouped = $rule.Files | Group-Object -Property Path
            foreach ($g in $filesGrouped) {
                $allLines = ($g.Group | ForEach-Object { $_.Lines } | Where-Object { $_ } | Sort-Object -Unique) -join ", "
                if ($allLines) {
                    [void]$sb.AppendLine("- ``$($g.Name)`` (lignes : $allLines)")
                } else {
                    [void]$sb.AppendLine("- ``$($g.Name)``")
                }
            }
            [void]$sb.AppendLine("")
        }
    }

    # ============================================================
    # DIFFS PAR FICHIER
    # ============================================================
    [void]$sb.AppendLine("## Diffs par fichier")
    [void]$sb.AppendLine("")
    foreach ($file in $data.file_diffs) {
        $relPath = Get-RelativePath -FullPath $file.file -ProjectPath $ProjectPath
        [void]$sb.AppendLine("### ``$relPath``")
        [void]$sb.AppendLine("")
        if ($file.applied_rectors) {
            [void]$sb.AppendLine("**Règles appliquées** : $($file.applied_rectors.Count)")
            [void]$sb.AppendLine("")
        }
        if ($file.diff) {
            $diffLines = $file.diff -split "`n"
            $relevantLines = $diffLines | Where-Object { $_ -match "^[\+\-@]" -and $_ -notmatch "^[\+\-]{3}" }
            if ($relevantLines.Count -gt 0) {
                [void]$sb.AppendLine('```diff')
                foreach ($l in $relevantLines) {
                    [void]$sb.AppendLine($l)
                }
                [void]$sb.AppendLine('```')
                [void]$sb.AppendLine("")
            }
        }
    }

    # ============================================================
    # PLAN D'ACTION
    # ============================================================
    [void]$sb.AppendLine("## Plan d'action recommandé")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("### Phase 1 — Préparation")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("1. Vérifier que le dépôt git est propre (``git status``)")
    [void]$sb.AppendLine("2. S'assurer que la suite de tests passe sur la branche actuelle")
    [void]$sb.AppendLine("3. Créer une branche dédiée : ``git checkout -b refactor/rector-modernization``")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("### Phase 2 — Application progressive")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Appliquer les changements **catégorie par catégorie**, en commençant par les moins risquées :")
    [void]$sb.AppendLine("")

    # Trier par risque croissant pour le plan
    $riskOrder = @{
        "Très faible — supprime du code inutilisé" = 1
        "Très faible — cosmétique" = 2
        "Faible — ajoute des annotations sans changer le comportement" = 3
        "Faible" = 4
        "Faible — réécritures équivalentes" = 5
        "Faible — réordonnance de la logique" = 6
        "Faible — cosmétique" = 7
        "Moyen" = 8
    }
    $orderedByRisk = $orderedCategories | Sort-Object -Property @{ Expression = {
        if ($riskOrder.ContainsKey($byCategory[$_].Risk)) { $riskOrder[$byCategory[$_].Risk] } else { 100 }
    } }

    $i = 1
    foreach ($k in $orderedByRisk) {
        $c = $byCategory[$k]
        [void]$sb.AppendLine("$i. **$($c.Label)** — $($c.TotalOccurrences) changement(s), risque : $($c.Risk)")
        $i++
    }
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("Pour chaque catégorie : commit séparé, exécuter les tests, vérifier le comportement.")
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("### Phase 3 — Validation")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("1. Tests unitaires complets")
    [void]$sb.AppendLine("2. Tests fonctionnels / E2E si disponibles")
    [void]$sb.AppendLine("3. Code review par un pair")
    [void]$sb.AppendLine("4. Déploiement en staging avant production")
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("## Commandes utiles")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine('```bash')
    [void]$sb.AppendLine("# Appliquer tous les changements")
    [void]$sb.AppendLine("rector process")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("# N'appliquer qu'une seule règle")
    [void]$sb.AppendLine("rector process --only=Rector\\TypeDeclaration\\...\\NomDeLaRegleRector")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("# Exclure une règle")
    [void]$sb.AppendLine("rector process --skip=Rector\\Privatization\\...\\NomDeLaRegleRector")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("# Analyser un seul fichier")
    [void]$sb.AppendLine("rector process src/path/to/file.php --dry-run")
    [void]$sb.AppendLine('```')
    [void]$sb.AppendLine("")

    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("*Rapport généré par Rector PHP Analysis Tools v2.1*")

    $sb.ToString()

} catch {
    @"
# Erreur de génération du rapport détaillé

Une erreur est survenue lors de la génération du rapport.

**Erreur** : $($_.Exception.Message)

**Trace** :
$($_.ScriptStackTrace)
"@
}
