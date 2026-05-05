# Rector PHP Analysis Tools

PowerShell tooling to analyze and modernize PHP projects with [Rector](https://github.com/rectorphp/rector).

In this project, **legacy** means code written for PHP 5.x, PHP 7.0-7.3, or older conventions that have not been updated for several years. **Modern** means code targeting a currently maintained PHP runtime and syntax style, usually PHP 8.1 to PHP 8.4 depending on your production constraints.

The main entry point is `rector-analyze.ps1`. It can run interactively or from the command line, generate a temporary Rector configuration for the selected target PHP version, format Rector JSON output into readable reports, and keep logs/history for later review.

## What It Does

- Analyze PHP projects with Rector in dry-run mode by default.
- Target PHP versions from `7.0` to `8.4` with `-PhpVersion`.
- Generate dynamic Rector configs from the target project structure.
- Optionally use an existing Rector config with `-UseRawConfig`.
- Add Rector sets such as `CODE_QUALITY`, `DEAD_CODE`, `TYPE_DECLARATION`, and more.
- Export reports as `simple`, `readable`, `detailed`, or raw `json`.
- Store analysis logs, history, and user preferences in `logs/`.
- Handle local paths and UNC/network paths on Windows.
- Provide unit tests for failure/error detection around `rector-analyze.ps1`.

## Requirements

- Windows with PowerShell 5.1 or newer
- PHP 7.4+ recommended
- Composer
- Git, for cloning and contributing

## Installation Model

Install this repository as a standalone tool, outside the PHP projects you want to analyze. For example:

```text
C:\tools\phpmigrations
C:\laragon\www\my-php-project
```

Run `rector-analyze.ps1` from the `phpmigrations` directory and pass the target project with `-ProjectPath`:

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\laragon\www\my-php-project" -PhpVersion 84
```

Rector itself may be installed in the target project, and this is often the best option for real migrations because Rector then runs with the same Composer dependencies and autoloading context as the project being analyzed. If the target project does not have Rector installed, this tool can also use the bundled example installation, a global Rector executable, or the helper script `scripts\install-rector.ps1`.

## Quick Start

```powershell
git clone [REPO_URL]
cd phpmigrations

# Optional: install Rector for the target project, or use the bundled example fallback.
.\scripts\install-rector.ps1

# Launch the interactive wizard.
.\rector-analyze.ps1
```

For a non-interactive run:

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -PhpVersion 84 -Interactive:$false -OutputFormat readable
```

To apply changes instead of running a simulation:

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -PhpVersion 84 -DryRun:$false
```

Use this only after reviewing the dry-run output and making sure the target project is under version control.

## Main Commands

| Command | Purpose |
| --- | --- |
| `.\rector-analyze.ps1` | Interactive wizard |
| `.\rector-analyze.ps1 -Help` | Show all options |
| `.\rector-analyze.ps1 -ShowHistory` | Show recent analyses |
| `.\rector-analyze.ps1 -ShowLogs` | Open the main log file |
| `.\scripts\install-rector.ps1` | Install Rector and copy starter configs |
| `.\run_unit_tests.bat` | Run PHPUnit tests from `unit_tests/` |

Useful command-line options:

| Option | Description |
| --- | --- |
| `-ProjectPath` | PHP project to analyze |
| `-PhpVersion` | Target PHP version: `70`, `71`, `72`, `73`, `74`, `80`, `81`, `82`, `83`, `84` |
| `-ExtraSets` | Additional Rector sets, for example `CODE_QUALITY,DEAD_CODE` |
| `-OutputFormat` | `simple`, `readable`, `detailed`, or `json` |
| `-OutputFile` | Save the formatted report to a file |
| `-DryRun:$false` | Apply Rector changes |
| `-ConfigFile` + `-UseRawConfig` | Use an existing Rector config as-is |

## Interactive Menu

The wizard can:

1. Launch a new analysis.
2. Replay a recent analysis.
3. Display analysis history.
4. Open log/history files.
5. Quit.

It also remembers the last project, target PHP version, selected sets, and output format in `logs/user-settings.json`.

## Project Structure

```text
phpmigrations/
  rector-analyze.ps1              Main analyzer and interactive wizard
  analyze-rector-readable.ps1     Grouped readable report formatter
  analyze-rector-detailed.ps1     Detailed rule report formatter
  scripts/
    install-rector.ps1            Rector installation helper
  config/                         Bundled Rector configs
  docs/                           Extra guides
  examples/                       Sample projects and migration examples
  failing_tests/                  Manual failing fixtures
  unit_tests/                     PHPUnit tests for script behavior
  logs/                           Analysis logs, history, preferences
  temp/                           Generated temporary configs
```

## PHP Versions And Configs

The default mode generates a temporary config dynamically from `-PhpVersion`. Supported dynamic targets are:

```text
70, 71, 72, 73, 74, 80, 81, 82, 83, 84
```

The `config/` directory also contains reusable Rector configs such as:

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

`rector-customizable.php` is a copy-and-edit starter config. `rector-old-code-to-php84.php` is a direct modernization profile for older PHP codebases, especially PHP 5.x and early PHP 7.x projects, targeting PHP 8.4.

To use a config file exactly as written:

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -ConfigFile "rector.php" -UseRawConfig
```

## Reports, Logs, And History

When a report is saved without an explicit `-OutputFile`, it is written under the analyzed project's `rector-output/` directory.

Repository-level runtime files are stored in:

```text
logs/
  rector-analysis.log       Text log with INFO/WARNING/ERROR/DEBUG entries
  analysis-history.json     Structured history of recent analyses
  user-settings.json        Last interactive choices
```

Show history:

```powershell
.\rector-analyze.ps1 -ShowHistory -HistoryCount 20
```

Open logs:

```powershell
.\rector-analyze.ps1 -ShowLogs
```

## Running Tests

```powershell
.\run_unit_tests.bat
```

Or:

```powershell
cd unit_tests
composer install
composer test
```

The tests create temporary PHP projects and verify that `rector-analyze.ps1` surfaces syntax and compatibility problems in dry-run mode.

## Documentation

- [French README](README-FR.md)
- [Getting started](docs/getting-started.md)
- [Quick start](docs/quick-start.md)
- [Advanced configuration](docs/advanced-config.md)
- [Migration guide](docs/migration-guide.md)
- [Documentation index](docs/INDEX.md)
- [Contribution guide](CONTRIBUTING-EN.md)

## License

MIT License. See [LICENSE](LICENSE).
