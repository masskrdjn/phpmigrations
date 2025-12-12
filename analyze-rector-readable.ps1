param(
    [string]$JsonFile,
    [string]$ProjectPath
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Helper pour les accents (pour eviter les problemes d'encodage du fichier script)
$e_acute = [char]0xE9 # é
$e_grave = [char]0xE8 # è
$a_grave = [char]0xE0 # à
$u_circ = [char]0xFB  # û

# Mapping des règles vers des descriptions lisibles (sans accents dans les clés, avec accents construits dans les valeurs ou ASCII simple)
$RectorDescriptions = @{
    "UseIdenticalOverEqualWithSameType" = "Preferer === a == lorsque les types sont identiques"
    "CompleteMissingIfElseBracket" = "Ajout des accolades manquantes aux blocs if/else"
    "ExplicitBoolCompare" = "Rendre la comparaison de booleens explicite"
    "AbsolutizeRequireAndIncludePath" = "Utilisation de chemins absolus (avec __DIR__) pour require/include"
    "SwitchNegatedTernary" = "Simplification des conditions ternaires inversees"
    "RemoveUnusedForeachKey" = "Suppression des variables de cle ($key) inutilisees dans les foreach"
    "RemoveUnreachableStatement" = "Suppression de code inaccessible (dead code)"
    "RemoveAlwaysElse" = "Suppression du 'else' inutile apres un return ou throw"
    "TernaryToElvis" = "Remplacement du ternaire par l'operateur Elvis (?:)"
    "LongArrayToShortArray" = "Utilisation de la syntaxe courte de tableau [] au lieu de array()"
    "ClosureToArrowFunction" = "Conversion des fonctions anonymes en fonctions flechees (fn =>)"
    "NullToStrictStringFuncCallArg" = "Casting explicite en string pour les arguments pouvant etre null"
    "NewMethodCallWithoutParentheses" = "Ajout des parentheses manquantes lors de l'instanciation (new Class())"
    "RenameFunction" = "Mise a jour des noms de fonctions (depreciees ou renommees)"
    "AddArrowFunctionReturnType" = "Ajout du type de retour aux fonctions flechees"
    "BoolReturnTypeFromBooleanStrictReturns" = "Ajout du type de retour 'bool' deduit strictement"
    "TypedPropertyFromAssigns" = "Typage des proprietes de classe base sur les assignations"
    "IssetOnPropertyObjectToPropertyExists" = "Remplacement de isset(\$obj->prop) par property_exists()"
    "RemoveUselessReturnTag" = "Suppression des annotations @return redondantes avec le type natif"
    "ClassPropertyAssignToConstructorPromotion" = "Promotion des proprietes directement dans le constructeur (PHP 8)"
    "AddVoidReturnTypeWhereNoReturn" = "Ajout du type de retour ': void' si la fonction ne retourne rien"
    "ParamTypeByMethodCallType" = "Typage des parametres deduit des appels de methode"
    "StrictStringParamConcat" = "Typage string strict lors de concatenation"
    "StringReturnTypeFromStrictStringReturns" = "Ajout du type de retour 'string' deduit strictement"
    "RemoveUnusedConstructorParam" = "Suppression de parametres de constructeur inutilises"
    "TypedPropertyFromStrictConstructor" = "Typage strict des proprietes initialisees dans le constructeur"
    "ShortenElseIf" = "Transformation de else { if } en elseif"
    "ReturnTypeFromStrictFluentReturn" = "Type de retour strict pour les interfaces fluides (\$this)"
    "SimplifyUselessVariable" = "Suppression de variables intermediaires inutiles"
    "ClosureDelegatingCallToFirstClassCallable" = "Simplification en Callable de premiere classe (MyClass::method(...))"
    "AddOverrideAttributeToOverriddenMethods" = "Ajout de l'attribut #[Override] (PHP 8.3)"
    "ReturnTypeFromStrictNativeCall" = "Type de retour deduit des fonctions natives PHP"
    "StringReturnTypeFromStrictScalarReturns" = "Type de retour 'string' deduit de valeurs scalaires"
    "ReturnTypeFromReturnNew" = "Type de retour deduit d'une instanciation (new Class)"
    "DisallowedEmptyRuleFixer" = "Remplacement de empty() par une verification explicite (empty() peut masquer des bugs)"
    "RemoveUselessParamTag" = "Suppression des annotations @param redondantes"
    "ChangeIfElseValueAssignToEarlyReturn" = "Remplacement d'assignations if/else par des retours precoces (early return)"
    "SimplifyIfElseToTernary" = "Simplification de if/else simples en operateur ternaire"
    "RemoveUnusedVariableInCatch" = "Suppression de la variable d'exception si non utilisee dans le catch"
    "CombinedAssign" = "Utilisation des operateurs d'assignation combinee (+=, .=, etc.)"
    "SingleInArrayToCompare" = "Remplacement de in_array avec une seule valeur par une comparaison simple"
    "RemoveDuplicatedArrayKey" = "Suppression des cles dupliquees dans la definition d'un tableau"
    "ReturnTypeFromReturnDirectArray" = "Ajout du type de retour 'array' deduit"
    "StrictArrayParamDimFetch" = "Typage strict des dimensions de tableau"
    "ChangeArrayPushToArrayAssign" = "Remplacement de array_push() par \$array[] ="
    "ArrayToFirstClassCallable" = "Remplacement de [\$obj, 'method'] par syntaxe First Class Callable"
    "ReturnUnionType" = "Ajout de types d'union (ex: string|int)"
    "MultiDirname" = "Remplacement de dirname(dirname(...)) par dirname(..., level)"
    "ReturnNullableType" = "Ajout de types nullables (?string)"
    "ReturnTypeFromStrictNewArray" = "Type de retour 'array' deduit d'une nouvelle instance de tableau"
    "StrStartsWith" = "Utilisation de la fonction str_starts_with()"
    "AddEscapeArgument" = "Ajout du parametre d'echappement manquant"
    "NumericReturnTypeFromStrictReturns" = "Type de retour numerique (int/float) deduit strictement"
    "TernaryToNullCoalescing" = "Remplacement du ternaire par l'operateur de coalescence nulle (??)"
    "FinalPrivateToPrivateVisibility" = "Suppression de 'final' sur les methodes 'private' (redondant)"
    "PreparedValueToEarlyReturn" = "Retour immediat d'une valeur au lieu de l'assigner avant"
    "ClassOnObject" = "Utilisation de ::class sur un objet"
    "RemoveReflectionSetAccessibleCalls" = "Suppression de setAccessible() (inutile depuis PHP 8.1)"
    "AddMethodCallBasedStrictParamType" = "Typage strict des parametres ajoute"
    "ReplaceMultipleBooleanNot" = "Simplification des doubles negations (!!)"
    "ChangeSwitchToMatch" = "Conversion de switch vers match (PHP 8.0)"
    "ReturnEarlyIfVariable" = "Retour precoce si la condition est remplie"
    "StrContains" = "Utilisation de la fonction str_contains()"
    "RepeatedAndNotEqualToNotInArray" = "Remplacement de repetitions != par !in_array"
    "StaticCallOnNonStaticToInstanceCall" = "Correction: Appel statique sur une methode non-statique"
    "UnnecessaryTernaryExpression" = "Simplification de ternaire inutile"
    "ConsistentImplode" = "Correction de l'ordre des parametres de implode"
    "ExplicitReturnNull" = "Ajout de return null explicite"
    "JoinStringConcat" = "Fusion de chaines concatenees"
    "RemoveUnusedVariableAssign" = "Suppression d'assignation de variable inutilisee"
    "DirNameFileConstantToDirConstant" = "Remplacement de dirname(__FILE__) par __DIR__"
    "Utf8DecodeEncodeToMbConvertEncoding" = "Modernisation UTF8 (mb_convert_encoding)"
    "RemoveDeadReturn" = "Suppression de return inutile (code mort)"
    "VarToPublicProperty" = "Remplacement de 'var' par 'public'"
    "SensitiveConstantName" = "Correction de la casse des constantes"
    "SingularSwitchToIf" = "Conversion de switch a cas unique en if"
    "ChangeOrIfContinueToMultiContinue" = "Optimisation de conditions de boucle"
    "RemoveConcatAutocast" = "Suppression de cast automatique dans concatenation"
    "RemoveAlwaysTrueIfCondition" = "Suppression de condition if toujours vraie"
    "RemoveDuplicatedCaseInSwitch" = "Suppression de 'case' duplique"
    "FunctionFirstClassCallable" = "Syntaxe First Class Callable pour fonction"
    "RandomFunction" = "Utilisation de random_int() (plus sur)"
    "SimplifyEmptyCheckOnEmptyArray" = "Simplification de verification de tableau vide"
    "LocallyCalledStaticMethodToNonStatic" = "Conversion methode statique locale en non-statique"
    "CompleteDynamicProperties" = "Ajout de declaration de propriete dynamique (deprecie en 8.2)"
    "RemoveUnusedPrivateProperty" = "Suppression propriete privee inutilisee"
    "RemoveDeadTryCatch" = "Suppression de bloc try/catch inutile"
    "ForRepeatedCountToOwnVariable" = "Extraction du count() hors de la boucle for"
    "ChangeNestedForeachIfsToEarlyContinue" = "Aplatissement de foreach imbriques"
    "RemoveExtraParameters" = "Suppression de parametres superflus"
    "PowToExp" = "Utilisation de l'operateur exposant **"
    "ArrayKeyFirstLast" = "Utilisation de array_key_first/last"
    "RemoveDeadIfForeachFor" = "Suppression de blocs de controle vides"
    "ConvertStaticToSelf" = "Preference pour 'self::' au lieu de 'static::' pour les constantes/methodes privees"
    "RemoveUnusedPrivateMethodParameter" = "Suppression de parametre non utilise dans methode privee"
    "SimplifyDeMorganBinary" = "Simplification logique (Loi de De Morgan)"
    "SimplifyRegexPattern" = "Simplification de motif Regex"
    "AddFunctionVoidReturnTypeWhereNoReturn" = "Ajout du type de retour ': void' si la fonction ne retourne rien"
    "RemoveNullTagValueNode" = "Suppression de tag vide"
    "RemoveUselessReturnExprInConstruct" = "Suppression de return inutile dans le constructeur"
    "InlineConstructorDefaultToProperty" = "Promotion des proprietes du constructeur"
    "StringableForToString" = "Ajout de l'interface Stringable si __toString existe"
    "AddParamFromDimFetchKeyUse" = "Deduction de parametre depuis usage de cle"
    "BoolReturnTypeFromBooleanConstReturns" = "Type de retour bool deduit de retour constant (return true/false)"
}

function Get-LineNumbersFromDiff {
    param([string]$DiffContent)
    
    $lines = @()
    # Regex pour capturer @@ -15,7 +15,7 @@
    $matches = [regex]::Matches($DiffContent, '@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@')
    
    foreach ($match in $matches) {
        $startLine = $match.Groups[1].Value
        $count = if ($match.Groups[2].Success) { $match.Groups[2].Value } else { 1 }
        
        if ($count -gt 1) {
            $endLine = [int]$startLine + [int]$count - 1
            $lines += "$startLine-$endLine"
        } else {
            $lines += "$startLine"
        }
    }
    
    return $lines -join ", "
}

try {
    if (-not (Test-Path $JsonFile)) {
        throw "Fichier JSON introuvable: $JsonFile"
    }

    $jsonContent = Get-Content -Path $JsonFile -Raw -Encoding UTF8
    
    # Parsing du JSON robuste
    $jsonStart = $jsonContent.IndexOf('{')
    $jsonEnd = $jsonContent.LastIndexOf('}')
    
    if ($jsonStart -ge 0 -and $jsonEnd -gt $jsonStart) {
        $jsonContent = $jsonContent.Substring($jsonStart, $jsonEnd - $jsonStart + 1)
    }
    
    $data = $jsonContent | ConvertFrom-Json
    
    # En-tête du rapport
    $output = @"
# Analyse Rector - Rapport Detaille
**Projet**: $ProjectPath
**Date**: $(Get-Date -Format "dd/MM/yyyy HH:mm")

"@

    if ($data.totals) {
        $changedFiles = if ($data.totals.changed_files) { $data.totals.changed_files } else { 0 }
        $errors = if ($data.totals.errors) { $data.totals.errors } else { 0 }
        
        $output += @"
## Resume
- **Fichiers modifies**: $changedFiles
- **Erreurs detectees**: $errors

"@
    }

    if ($data.file_diffs -and $data.file_diffs.Count -gt 0) {
        $output += "## Details par fichier`n"
        
        foreach ($file in $data.file_diffs) {
            $fileName = Split-Path $file.file -Leaf
            $relativePath = $file.file.Replace($ProjectPath, "") -replace "^[/\\]+", ""
            
            # Titre du fichier
            $output += "`n### [File] $relativePath`n"
            
            # Lignes impactées
            $impactedLines = Get-LineNumbersFromDiff -DiffContent $file.diff
            if ($impactedLines) {
                $output += "**Lignes impactees**: $impactedLines`n`n"
            }
            
            # Modifications
            foreach ($rector in $file.applied_rectors) {
                $rectorShortName = ($rector -split '\\')[-1]
                $rectorName = $rectorShortName -replace 'Rector$', ''
                
                $description = if ($RectorDescriptions.ContainsKey($rectorName)) { 
                    $RectorDescriptions[$rectorName] 
                } else { 
                    # Essayer de formater le nom CamelCase en phrase
                    # Utilisation de -creplace (case-sensitive) pour le découpage camelCase
                    $rectorName -creplace '([A-Z])', ' $1' | ForEach-Object { $_.Trim() }
                }
                
                $output += "- $description`n"
            }
        }
    } else {
        $output += "`n[OK] Excellent ! Aucun probleme detecte. Votre code est deja optimise.`n"
    }

    # IMPORTANT: Retourner la chaine pour qu'elle soit capturée par le script parent
    $output

} catch {
    # En cas d'erreur, retourner un message d'erreur formaté markdown
    @"
# Erreur de Generation du Rapport

Une erreur est survenue lors de la generation du rapport lisible.

**Erreur**: $($_.Exception.Message)

**Trace**:
$($_.ScriptStackTrace)
"@
}
