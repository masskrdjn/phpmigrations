# Guide de demarrage - Rector PHP Analysis Tools

Ce guide reste pertinent, mais il a ete mis a jour pour refleter le fonctionnement actuel du projet : la commande recommandee utilise maintenant `-PhpVersion`, qui genere une configuration Rector temporaire adaptee au projet analyse.

## Prerequis

- Windows avec PowerShell 5.1 ou plus recent
- PHP 7.4+ pour utiliser l'outil, PHP 8.0+ recommande pour les tests
- Composer
- Git

## Installation rapide

```powershell
git clone [URL_DU_REPO] phpmigrations
cd phpmigrations

.\scripts\install-rector.ps1
.\rector-analyze.ps1
```

`install-rector.ps1` installe Rector dans le projet cible ou dans l'exemple fourni. Le script principal sait aussi utiliser un Rector local au projet analyse, le Rector de l'exemple, ou un Rector global disponible dans le `PATH`.

## Premiere analyse

### Mode interactif

```powershell
.\rector-analyze.ps1
```

Le menu interactif permet de choisir :
- le projet PHP a analyser ;
- la version PHP cible ;
- les sets Rector additionnels ;
- le format de rapport ;
- le mode dry-run ou application reelle.

### Mode ligne de commande

```powershell
# Analyse d'un projet vers PHP 8.4, sans appliquer les changements
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 84 -DryRun:$true

# Rapport detaille sauvegarde dans un fichier
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 81 -OutputFormat detailed -OutputFile "rapport.md"

# Ajouter des sets Rector courants
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 84 -ExtraSets CODE_QUALITY,DEAD_CODE,TYPE_DECLARATION
```

## Choisir une cible PHP

| Situation | Cible conseillee | Pourquoi |
|-----------|------------------|----------|
| Projet ancien / legacy en PHP 5.x ou PHP 7.0-7.3 | `-PhpVersion 74`, puis `81`, puis `84` | Migration progressive plus facile a tester. |
| Projet PHP 7.4 | `-PhpVersion 81` ou `84` | Bon equilibre entre modernisation et compatibilite. |
| Projet PHP 8.0-8.2 | `-PhpVersion 84` | Mise a jour vers la cible la plus recente couverte par le projet. |
| Projet avec son propre `rector.php` | `-ConfigFile "rector.php" -UseRawConfig` | Respecte exactement la configuration existante. |

Dans cette documentation, **legacy** ou **ancien** designe une base de code ecrite pour PHP 5.x, PHP 7.0-7.3, ou des conventions qui n'ont pas ete mises a jour depuis plusieurs annees. **Moderne** designe une cible PHP actuellement maintenue et des idiomes recents ; dans ce projet, cela correspond surtout a PHP 8.1 a PHP 8.4.

## Formats de rapport

| Format | Usage |
|--------|-------|
| `simple` | Resume rapide. |
| `readable` | Rapport lisible recommande au quotidien. |
| `detailed` | Rapport plus complet pour preparer une migration. |
| `json` | Sortie brute Rector pour integration ou traitement automatise. |

Exemple :

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 84 -OutputFormat readable
```

## Workflow recommande

1. Verifier que le projet cible est versionne avec Git.
2. Lancer une analyse en dry-run.
3. Lire le rapport et choisir une cible raisonnable.
4. Appliquer sur une branche dediee.
5. Lancer les tests du projet cible.
6. Recommencer par etapes si le diff est trop grand.

```powershell
git status
git checkout -b feature/rector-modernization

.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 81 -DryRun:$true
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 81 -DryRun:$false
```

## Utiliser une configuration existante

Par defaut, `rector-analyze.ps1` genere une configuration dynamique a partir de `-PhpVersion`. Pour utiliser un fichier Rector existant sans le modifier :

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector.php" -UseRawConfig
```

Sans `-UseRawConfig`, `-ConfigFile` sert surtout a deduire une version cible depuis un nom comme `rector-php81.php`.

## Historique et logs

```powershell
.\rector-analyze.ps1 -ShowHistory -HistoryCount 20
.\rector-analyze.ps1 -ShowLogs
```

Les logs et l'historique se trouvent dans `logs/`.

## Depannage

### Rector introuvable

```powershell
.\scripts\install-rector.ps1 -ProjectPath "C:\mon\projet"
```

### Politique d'execution PowerShell

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Trop de changements

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 74 -DryRun:$true
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 81 -DryRun:$true
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 84 -DryRun:$true
```

### Tests de ce projet

```powershell
.\run_unit_tests.bat
.\test-installation.ps1 -Quick
```

## Ressources utiles

- [Documentation Rector](https://github.com/rectorphp/rector)
- [Migration PHP](https://www.php.net/migration84)
- [PHP The Right Way](https://phptherightway.com/)
- [PHPUnit](https://phpunit.de/)
