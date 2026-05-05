# Rector PHP Analysis Tools

Outils PowerShell pour analyser et moderniser des projets PHP avec [Rector](https://github.com/rectorphp/rector).

Dans ce projet, **ancien** ou **legacy** désigne du code écrit pour PHP 5.x, PHP 7.0-7.3, ou des conventions qui n'ont pas été mises à jour depuis plusieurs années. **Moderne** désigne du code ciblant une version PHP maintenue et des pratiques récentes, généralement PHP 8.1 à PHP 8.4 selon vos contraintes de production.

Le point d'entrée principal est `rector-analyze.ps1`. Il peut tourner en mode interactif ou en ligne de commande, générer une configuration Rector temporaire selon la version PHP cible, transformer la sortie JSON de Rector en rapports lisibles, et conserver les logs/historiques d'analyse.

## Fonctionnalités

- Analyse Rector en dry-run par défaut.
- Versions PHP cibles de `7.0` à `8.4` via `-PhpVersion`.
- Génération dynamique de configuration Rector selon la structure du projet.
- Utilisation possible d'un fichier Rector existant avec `-UseRawConfig`.
- Ajout de sets Rector comme `CODE_QUALITY`, `DEAD_CODE`, `TYPE_DECLARATION`, etc.
- Rapports `simple`, `readable`, `detailed` ou `json`.
- Logs, historique et préférences utilisateur dans `logs/`.
- Gestion des chemins locaux et UNC/réseau sous Windows.
- Tests unitaires autour de la détection d'erreurs de `rector-analyze.ps1`.

## Prérequis

- Windows avec PowerShell 5.1 ou plus récent
- PHP 7.4+ recommandé
- Composer
- Git, pour cloner et contribuer

## Démarrage rapide

```powershell
git clone [URL_DU_REPO]
cd phpmigrations

# Installer Rector dans le projet à analyser, ou utiliser l'exemple fourni.
.\scripts\install-rector.ps1

# Lancer l'assistant interactif.
.\rector-analyze.ps1
```

Exécution non interactive :

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 84 -Interactive:$false -OutputFormat readable
```

Appliquer les changements au lieu de simuler :

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -PhpVersion 84 -DryRun:$false
```

À utiliser seulement après avoir relu le dry-run et vérifié que le projet cible est versionné.

## Commandes principales

| Commande | Rôle |
| --- | --- |
| `.\rector-analyze.ps1` | Assistant interactif |
| `.\rector-analyze.ps1 -Help` | Afficher toutes les options |
| `.\rector-analyze.ps1 -ShowHistory` | Voir les analyses récentes |
| `.\rector-analyze.ps1 -ShowLogs` | Ouvrir le fichier de log principal |
| `.\scripts\install-rector.ps1` | Installer Rector et copier des configs de départ |
| `.\run_unit_tests.bat` | Lancer les tests PHPUnit dans `unit_tests/` |

Options utiles :

| Option | Description |
| --- | --- |
| `-ProjectPath` | Projet PHP à analyser |
| `-PhpVersion` | Version cible : `70`, `71`, `72`, `73`, `74`, `80`, `81`, `82`, `83`, `84` |
| `-ExtraSets` | Sets Rector additionnels, par exemple `CODE_QUALITY,DEAD_CODE` |
| `-OutputFormat` | `simple`, `readable`, `detailed` ou `json` |
| `-OutputFile` | Fichier de sauvegarde du rapport |
| `-DryRun:$false` | Appliquer les changements Rector |
| `-ConfigFile` + `-UseRawConfig` | Utiliser une configuration Rector existante telle quelle |

## Menu interactif

L'assistant permet de :

1. Lancer une nouvelle analyse.
2. Rejouer une analyse récente.
3. Consulter l'historique des analyses.
4. Ouvrir les fichiers de logs/historique.
5. Quitter.

Il mémorise aussi le dernier projet, la version PHP cible, les sets sélectionnés et le format de sortie dans `logs/user-settings.json`.

## Structure du projet

```text
phpmigrations/
  rector-analyze.ps1              Analyseur principal et assistant interactif
  analyze-rector-readable.ps1     Formatteur Markdown lisible groupé
  analyze-rector-detailed.ps1     Formatteur détaillé par règle
  scripts/
    install-rector.ps1            Assistant d'installation de Rector
  config/                         Configurations Rector fournies
  docs/                           Guides complémentaires
  examples/                       Exemples de projets et migrations
  failing_tests/                  Fixtures manuelles d'échec
  unit_tests/                     Tests PHPUnit du comportement des scripts
  logs/                           Logs, historique, préférences
  temp/                           Configurations temporaires générées
```

## Versions PHP et configurations

Par défaut, `rector-analyze.ps1` génère une configuration temporaire depuis `-PhpVersion`. Les cibles dynamiques supportées sont :

```text
70, 71, 72, 73, 74, 80, 81, 82, 83, 84
```

Le dossier `config/` contient aussi des configurations Rector réutilisables, par exemple :

```text
rector-php70.php
rector-php74.php
rector-php80.php
rector-php81.php
rector-php82.php
rector-php83.php
rector-php84.php
rector-customizable.php
rector-old-code-to-php84.php
```

`rector-customizable.php` sert de configuration de départ à copier puis adapter. `rector-old-code-to-php84.php` est un profil de modernisation directe pour les bases de code anciennes, surtout PHP 5.x et début PHP 7.x, avec PHP 8.4 comme cible.

Pour utiliser un fichier de configuration exactement tel qu'il est écrit :

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\mon\projet" -ConfigFile "rector.php" -UseRawConfig
```

## Rapports, logs et historique

Quand un rapport est sauvegardé sans `-OutputFile`, il est écrit dans `rector-output/` côté projet analysé.

Les fichiers d'exécution côté dépôt sont :

```text
logs/
  rector-analysis.log       Log texte avec entrées INFO/WARNING/ERROR/DEBUG
  analysis-history.json     Historique structuré des analyses récentes
  user-settings.json        Derniers choix interactifs
```

Consulter l'historique :

```powershell
.\rector-analyze.ps1 -ShowHistory -HistoryCount 20
```

Ouvrir les logs :

```powershell
.\rector-analyze.ps1 -ShowLogs
```

## Tests

```powershell
.\run_unit_tests.bat
```

Ou :

```powershell
cd unit_tests
composer install
composer test
```

Les tests créent des projets PHP temporaires et vérifient que `rector-analyze.ps1` remonte les erreurs de syntaxe ou de compatibilité en dry-run.

## Documentation

- [Documentation anglaise](README.md)
- [Guide de démarrage](docs/getting-started.md)
- [Démarrage rapide](docs/quick-start.md)
- [Configuration avancée](docs/advanced-config.md)
- [Guide de migration](docs/migration-guide.md)
- [Index de documentation](docs/INDEX.md)
- [Guide de contribution](CONTRIBUTING.md)

## Licence

Licence MIT. Voir [LICENSE](LICENSE).
