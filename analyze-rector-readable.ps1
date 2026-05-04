# ==============================================================================
# RECTOR ANALYSIS - Format Lisible (groupé par catégorie)
# Génère un rapport Markdown détaillé, organisé par catégorie de règle Rector.
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

function Get-RectorCategory {
    param([string]$RectorClass)
    $segments = $RectorClass -split '\\'
    if ($segments.Count -lt 2) { return @{ Key = "Other"; Label = "Autres" } }
    $key = $segments[1]

    if ($key -match '^Php(\d{2})$') {
        $v = $matches[1]
        return @{ Key = $key; Label = "Migration PHP $($v.Substring(0,1)).$($v.Substring(1))" }
    }
    if ($script:CategoryLabels.ContainsKey($key)) {
        return @{ Key = $key; Label = $script:CategoryLabels[$key] }
    }
    return @{ Key = $key; Label = $key }
}

# =============================================================================
# DESCRIPTIONS FR (par nom court de rector, sans le suffixe "Rector")
# =============================================================================

$script:RectorDescriptions = @{
    "UseIdenticalOverEqualWithSameType"           = "Préférer === à == lorsque les types sont identiques"
    "CompleteMissingIfElseBracket"                = "Ajout des accolades manquantes aux blocs if/else"
    "ExplicitBoolCompare"                         = "Rendre la comparaison de booléens explicite"
    "AbsolutizeRequireAndIncludePath"             = "Utilisation de chemins absolus (avec __DIR__) pour require/include"
    "SwitchNegatedTernary"                        = "Simplification des conditions ternaires inversées"
    "RemoveUnusedForeachKey"                      = "Suppression des variables de clé (`$key) inutilisées dans les foreach"
    "RemoveUnreachableStatement"                  = "Suppression de code inaccessible (dead code)"
    "RemoveAlwaysElse"                            = "Suppression du 'else' inutile après un return ou throw"
    "TernaryToElvis"                              = "Remplacement du ternaire par l'opérateur Elvis (?:)"
    "LongArrayToShortArray"                       = "Utilisation de la syntaxe courte de tableau [] au lieu de array()"
    "ClosureToArrowFunction"                      = "Conversion des fonctions anonymes en fonctions fléchées (fn =>)"
    "NullToStrictStringFuncCallArg"               = "Cast explicite en string pour les arguments pouvant être null"
    "NewMethodCallWithoutParentheses"             = "Ajout des parenthèses manquantes lors de l'instanciation"
    "RenameFunction"                              = "Mise à jour des noms de fonctions (dépréciées ou renommées)"
    "AddArrowFunctionReturnType"                  = "Ajout du type de retour aux fonctions fléchées"
    "BoolReturnTypeFromBooleanStrictReturns"      = "Ajout du type de retour 'bool' déduit strictement"
    "TypedPropertyFromAssigns"                    = "Typage des propriétés de classe basé sur les assignations"
    "IssetOnPropertyObjectToPropertyExists"       = "Remplacement de isset(`$obj->prop) par property_exists()"
    "RemoveUselessReturnTag"                      = "Suppression des annotations @return redondantes avec le type natif"
    "ClassPropertyAssignToConstructorPromotion"   = "Promotion des propriétés directement dans le constructeur (PHP 8)"
    "AddVoidReturnTypeWhereNoReturn"              = "Ajout du type de retour ': void' si la fonction ne retourne rien"
    "ParamTypeByMethodCallType"                   = "Typage des paramètres déduit des appels de méthode"
    "StrictStringParamConcat"                     = "Typage string strict lors de concaténation"
    "StringReturnTypeFromStrictStringReturns"     = "Ajout du type de retour 'string' déduit strictement"
    "RemoveUnusedConstructorParam"                = "Suppression de paramètres de constructeur inutilisés"
    "TypedPropertyFromStrictConstructor"          = "Typage strict des propriétés initialisées dans le constructeur"
    "ShortenElseIf"                               = "Transformation de else { if } en elseif"
    "ReturnTypeFromStrictFluentReturn"            = "Type de retour strict pour les interfaces fluides (`$this)"
    "SimplifyUselessVariable"                     = "Suppression de variables intermédiaires inutiles"
    "ClosureDelegatingCallToFirstClassCallable"   = "Simplification en Callable de première classe"
    "AddOverrideAttributeToOverriddenMethods"     = "Ajout de l'attribut #[Override] (PHP 8.3)"
    "ReturnTypeFromStrictNativeCall"              = "Type de retour déduit des fonctions natives PHP"
    "StringReturnTypeFromStrictScalarReturns"     = "Type de retour 'string' déduit de valeurs scalaires"
    "ReturnTypeFromReturnNew"                     = "Type de retour déduit d'une instanciation (new Class)"
    "DisallowedEmptyRuleFixer"                    = "Remplacement de empty() par une vérification explicite"
    "RemoveUselessParamTag"                       = "Suppression des annotations @param redondantes"
    "ChangeIfElseValueAssignToEarlyReturn"        = "Remplacement d'assignations if/else par des retours anticipés"
    "SimplifyIfElseToTernary"                     = "Simplification de if/else simples en opérateur ternaire"
    "RemoveUnusedVariableInCatch"                 = "Suppression de la variable d'exception si non utilisée dans le catch"
    "CombinedAssign"                              = "Utilisation des opérateurs d'assignation combinée (+=, .=, etc.)"
    "SingleInArrayToCompare"                      = "Remplacement de in_array avec une seule valeur par une comparaison simple"
    "RemoveDuplicatedArrayKey"                    = "Suppression des clés dupliquées dans la définition d'un tableau"
    "ReturnTypeFromReturnDirectArray"             = "Ajout du type de retour 'array' déduit"
    "StrictArrayParamDimFetch"                    = "Typage strict des dimensions de tableau"
    "ChangeArrayPushToArrayAssign"                = "Remplacement de array_push() par `$array[] ="
    "ArrayToFirstClassCallable"                   = "Remplacement de [`$obj, 'method'] par syntaxe First Class Callable"
    "ReturnUnionType"                             = "Ajout de types d'union (ex: string|int)"
    "MultiDirname"                                = "Remplacement de dirname(dirname(...)) par dirname(..., level)"
    "ReturnNullableType"                          = "Ajout de types nullables (?string)"
    "ReturnTypeFromStrictNewArray"                = "Type de retour 'array' déduit d'une nouvelle instance de tableau"
    "StrStartsWith"                               = "Utilisation de la fonction str_starts_with()"
    "AddEscapeArgument"                           = "Ajout du paramètre d'échappement manquant"
    "NumericReturnTypeFromStrictReturns"          = "Type de retour numérique (int/float) déduit strictement"
    "TernaryToNullCoalescing"                     = "Remplacement du ternaire par l'opérateur de coalescence nulle (??)"
    "FinalPrivateToPrivateVisibility"             = "Suppression de 'final' sur les méthodes 'private' (redondant)"
    "PreparedValueToEarlyReturn"                  = "Retour immédiat d'une valeur au lieu de l'assigner avant"
    "ClassOnObject"                               = "Utilisation de ::class sur un objet"
    "RemoveReflectionSetAccessibleCalls"          = "Suppression de setAccessible() (inutile depuis PHP 8.1)"
    "AddMethodCallBasedStrictParamType"           = "Typage strict des paramètres ajouté"
    "ReplaceMultipleBooleanNot"                   = "Simplification des doubles négations (!!)"
    "ChangeSwitchToMatch"                         = "Conversion de switch vers match (PHP 8.0)"
    "ReturnEarlyIfVariable"                       = "Retour anticipé si la condition est remplie"
    "StrContains"                                 = "Utilisation de la fonction str_contains()"
    "RepeatedAndNotEqualToNotInArray"             = "Remplacement de répétitions != par !in_array"
    "StaticCallOnNonStaticToInstanceCall"         = "Correction: Appel statique sur une méthode non-statique"
    "UnnecessaryTernaryExpression"                = "Simplification de ternaire inutile"
    "ConsistentImplode"                           = "Correction de l'ordre des paramètres de implode"
    "ExplicitReturnNull"                          = "Ajout de return null explicite"
    "JoinStringConcat"                            = "Fusion de chaînes concaténées"
    "RemoveUnusedVariableAssign"                  = "Suppression d'assignation de variable inutilisée"
    "DirNameFileConstantToDirConstant"            = "Remplacement de dirname(__FILE__) par __DIR__"
    "Utf8DecodeEncodeToMbConvertEncoding"         = "Modernisation UTF8 (mb_convert_encoding)"
    "RemoveDeadReturn"                            = "Suppression de return inutile (code mort)"
    "VarToPublicProperty"                         = "Remplacement de 'var' par 'public'"
    "SensitiveConstantName"                       = "Correction de la casse des constantes"
    "SingularSwitchToIf"                          = "Conversion de switch à cas unique en if"
    "ChangeOrIfContinueToMultiContinue"           = "Optimisation de conditions de boucle"
    "RemoveConcatAutocast"                        = "Suppression de cast automatique dans concaténation"
    "RemoveAlwaysTrueIfCondition"                 = "Suppression de condition if toujours vraie"
    "RemoveDuplicatedCaseInSwitch"                = "Suppression de 'case' dupliqué"
    "FunctionFirstClassCallable"                  = "Syntaxe First Class Callable pour fonction"
    "RandomFunction"                              = "Utilisation de random_int() (plus sûr)"
    "SimplifyEmptyCheckOnEmptyArray"              = "Simplification de vérification de tableau vide"
    "LocallyCalledStaticMethodToNonStatic"        = "Conversion méthode statique locale en non-statique"
    "CompleteDynamicProperties"                   = "Ajout de déclaration de propriété dynamique (déprécié en 8.2)"
    "RemoveUnusedPrivateProperty"                 = "Suppression propriété privée inutilisée"
    "RemoveDeadTryCatch"                          = "Suppression de bloc try/catch inutile"
    "ForRepeatedCountToOwnVariable"               = "Extraction du count() hors de la boucle for"
    "ChangeNestedForeachIfsToEarlyContinue"       = "Aplatissement de foreach imbriqués"
    "RemoveExtraParameters"                       = "Suppression de paramètres superflus"
    "PowToExp"                                    = "Utilisation de l'opérateur exposant **"
    "ArrayKeyFirstLast"                           = "Utilisation de array_key_first/last"
    "RemoveDeadIfForeachFor"                      = "Suppression de blocs de contrôle vides"
    "ConvertStaticToSelf"                         = "Préférence pour 'self::' au lieu de 'static::'"
    "RemoveUnusedPrivateMethodParameter"          = "Suppression de paramètre non utilisé dans méthode privée"
    "SimplifyDeMorganBinary"                      = "Simplification logique (loi de De Morgan)"
    "SimplifyRegexPattern"                        = "Simplification de motif regex"
    "AddFunctionVoidReturnTypeWhereNoReturn"      = "Ajout du type de retour ': void'"
    "RemoveNullTagValueNode"                      = "Suppression de tag vide"
    "RemoveUselessReturnExprInConstruct"          = "Suppression de return inutile dans le constructeur"
    "InlineConstructorDefaultToProperty"          = "Promotion des propriétés du constructeur"
    "StringableForToString"                       = "Ajout de l'interface Stringable si __toString existe"
    "AddParamFromDimFetchKeyUse"                  = "Déduction de paramètre depuis usage de clé"
    "BoolReturnTypeFromBooleanConstReturns"       = "Type de retour bool déduit de retour constant"
    "CallUserFuncArrayToVariadic"                 = "Remplace call_user_func_array() par la syntaxe variadic (...)"
    "CountOnNull"                                 = "Ajoute une vérification null avant count()"
    "AddArrayDefaultToArrayProperty"              = "Ajoute une valeur par défaut [] aux propriétés de type array"
    "StringClassNameToClassConstant"              = "Remplace les noms de classe en string par ::class"
    "MixedType"                                   = "Ajoute le type 'mixed' aux propriétés et paramètres"
    "PropertyPromotion"                           = "Utilise la promotion des propriétés dans les constructeurs PHP 8"
    "TypedProperty"                               = "Ajoute les types aux propriétés de classe"
    "ParamTypeDeclaration"                        = "Ajoute les types aux paramètres de fonction"
    "ReturnTypeDeclaration"                       = "Ajoute les types de retour aux fonctions"
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

function Get-RectorDescription {
    param([string]$RectorClass)
    $shortName = Get-RectorShortName $RectorClass
    if ($script:RectorDescriptions.ContainsKey($shortName)) {
        return $script:RectorDescriptions[$shortName]
    }
    # Fallback : insère un espace devant chaque majuscule pour faire une phrase
    $spaced = $shortName -creplace '([A-Z])', ' $1'
    return $spaced.Trim()
}

function Get-RelativePath {
    param([string]$FullPath, [string]$ProjectPath)
    if (-not $ProjectPath) { return $FullPath }
    return $FullPath.Replace($ProjectPath, "") -replace "^[/\\]+", ""
}

# =============================================================================
# PIPELINE PRINCIPAL
# =============================================================================

try {
    if (-not (Test-Path $JsonFile)) {
        throw "Fichier JSON introuvable: $JsonFile"
    }

    $jsonContent = Get-Content -Path $JsonFile -Raw -Encoding UTF8

    # Parsing JSON robuste : Rector peut polluer la sortie avec des warnings PHP
    $jsonStart = $jsonContent.IndexOf('{')
    $jsonEnd   = $jsonContent.LastIndexOf('}')
    if ($jsonStart -ge 0 -and $jsonEnd -gt $jsonStart) {
        $jsonContent = $jsonContent.Substring($jsonStart, $jsonEnd - $jsonStart + 1)
    }

    $data = $jsonContent | ConvertFrom-Json -ErrorAction Stop

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("# Analyse Rector - Rapport lisible")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("**Projet** : $ProjectPath")
    [void]$sb.AppendLine("**Date**   : $(Get-Date -Format 'dd/MM/yyyy HH:mm')")
    [void]$sb.AppendLine("")

    # Résumé
    if ($data.totals) {
        $changedFiles = if ($data.totals.changed_files) { $data.totals.changed_files } else { 0 }
        $errors       = if ($data.totals.errors)        { $data.totals.errors }        else { 0 }
        [void]$sb.AppendLine("## Résumé")
        [void]$sb.AppendLine("")
        [void]$sb.AppendLine("- **Fichiers modifiés** : $changedFiles")
        [void]$sb.AppendLine("- **Erreurs détectées** : $errors")
        [void]$sb.AppendLine("")
    }

    if (-not $data.file_diffs -or $data.file_diffs.Count -eq 0) {
        [void]$sb.AppendLine("[OK] Aucun problème détecté. Votre code est déjà optimisé pour la version PHP cible.")
        $sb.ToString()
        exit 0
    }

    # ============================================================
    # AGRÉGATION : par catégorie -> par règle -> liste fichiers/lignes
    # ============================================================

    # Structure :
    # $byCategory[<catKey>] = @{
    #   Label = "Déclarations de types"
    #   Rules = @{
    #     <rectorClass> = @{
    #       ShortName = ...
    #       Description = ...
    #       Occurrences = N
    #       Files = @( @{ Path=..., Lines="12,45-50" }, ... )
    #     }
    #   }
    #   TotalOccurrences = N
    #   TouchedFiles = HashSet
    # }
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
                    Rules            = [ordered]@{}
                    TotalOccurrences = 0
                    TouchedFiles     = New-Object System.Collections.Generic.HashSet[string]
                }
            }

            $byCategory[$catKey].TotalOccurrences++
            [void]$byCategory[$catKey].TouchedFiles.Add($relPath)

            if (-not $byCategory[$catKey].Rules.Contains($rectorClass)) {
                $byCategory[$catKey].Rules[$rectorClass] = @{
                    ShortName   = (Get-RectorShortName $rectorClass)
                    Description = (Get-RectorDescription $rectorClass)
                    Occurrences = 0
                    Files       = New-Object System.Collections.ArrayList
                }
            }
            $byCategory[$catKey].Rules[$rectorClass].Occurrences++
            [void]$byCategory[$catKey].Rules[$rectorClass].Files.Add([PSCustomObject]@{
                Path  = $relPath
                Lines = $impactedLines
            })
        }
    }

    # Trier les catégories par nombre d'occurrences décroissant
    $orderedCategories = $byCategory.Keys | Sort-Object -Property @{ Expression = { -$byCategory[$_].TotalOccurrences } }

    # ============================================================
    # SYNTHÈSE PAR CATÉGORIE
    # ============================================================
    [void]$sb.AppendLine("## Synthèse par catégorie")
    [void]$sb.AppendLine("")
    [void]$sb.AppendLine("| Catégorie | Règles | Occurrences | Fichiers touchés |")
    [void]$sb.AppendLine("|-----------|-------:|------------:|-----------------:|")
    foreach ($k in $orderedCategories) {
        $c = $byCategory[$k]
        $rulesCount = $c.Rules.Keys.Count
        $filesCount = $c.TouchedFiles.Count
        [void]$sb.AppendLine("| $($c.Label) | $rulesCount | $($c.TotalOccurrences) | $filesCount |")
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
        [void]$sb.AppendLine("$($c.TotalOccurrences) occurrence(s) sur $($c.TouchedFiles.Count) fichier(s).")
        [void]$sb.AppendLine("")

        # Règles triées par occurrences
        $orderedRules = $c.Rules.Keys | Sort-Object -Property @{ Expression = { -$c.Rules[$_].Occurrences } }
        foreach ($r in $orderedRules) {
            $rule = $c.Rules[$r]
            [void]$sb.AppendLine("- **$($rule.ShortName)** ($($rule.Occurrences) occurrence(s)) — $($rule.Description)")
            # Regrouper les lignes par fichier
            $filesGrouped = $rule.Files | Group-Object -Property Path
            foreach ($g in $filesGrouped) {
                $allLines = ($g.Group | ForEach-Object { $_.Lines } | Where-Object { $_ } | Sort-Object -Unique) -join ", "
                if ($allLines) {
                    [void]$sb.AppendLine("  - ``$($g.Name)`` (lignes : $allLines)")
                } else {
                    [void]$sb.AppendLine("  - ``$($g.Name)``")
                }
            }
        }
        [void]$sb.AppendLine("")
    }

    # ============================================================
    # ANNEXE : analyse par fichier
    # ============================================================
    [void]$sb.AppendLine("## Annexe : analyse par fichier")
    [void]$sb.AppendLine("")

    foreach ($file in $data.file_diffs) {
        $relPath = Get-RelativePath -FullPath $file.file -ProjectPath $ProjectPath
        [void]$sb.AppendLine("### ``$relPath``")
        $impactedLines = Get-LineNumbersFromDiff -DiffContent $file.diff
        if ($impactedLines) {
            [void]$sb.AppendLine("**Lignes impactées** : $impactedLines")
        }
        [void]$sb.AppendLine("")
        foreach ($rector in $file.applied_rectors) {
            $rectorClass = if ($rector -is [string]) { $rector } elseif ($rector.class) { $rector.class } else { "$rector" }
            $shortName  = Get-RectorShortName $rectorClass
            $description = Get-RectorDescription $rectorClass
            $cat = Get-RectorCategory -RectorClass $rectorClass
            [void]$sb.AppendLine("- **[$($cat.Label)]** $shortName — $description")
        }
        [void]$sb.AppendLine("")
    }

    [void]$sb.AppendLine("---")
    [void]$sb.AppendLine("*Rapport généré par Rector PHP Analysis Tools v2.1*")

    $sb.ToString()

} catch {
    @"
# Erreur de génération du rapport

Une erreur est survenue lors de la génération du rapport lisible.

**Erreur** : $($_.Exception.Message)

**Trace** :
$($_.ScriptStackTrace)
"@
}
