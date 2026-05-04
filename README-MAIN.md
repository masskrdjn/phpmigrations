# Rector PHP Analysis Tools

Choose your language:

- [English documentation](README-EN.md)
- [Documentation française](README-FR.md)

## Quick Start

```powershell
.\scripts\install-rector.ps1
.\rector-analyze.ps1
```

Non-interactive example:

```powershell
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -PhpVersion 84 -Interactive:$false -OutputFormat readable
```

## Current Highlights

- Interactive wizard and command-line mode.
- Dynamic target PHP version selection with `-PhpVersion`.
- Supported dynamic targets: `70`, `71`, `72`, `73`, `74`, `80`, `81`, `82`, `83`, `84`.
- Optional raw config mode with `-ConfigFile` and `-UseRawConfig`.
- Clear config names: `rector-customizable.php` for a template, `rector-old-code-to-php84.php` for older PHP codebases targeting PHP 8.4.
- Extra Rector sets via `-ExtraSets`.
- Output formats: `simple`, `readable`, `detailed`, `json`.
- Analysis logs, history, and preferences in `logs/`.
- Recent analysis replay from the interactive menu.
- PHPUnit tests in `unit_tests/`.

## Useful Commands

```powershell
.\rector-analyze.ps1 -Help
.\rector-analyze.ps1 -ShowHistory -HistoryCount 20
.\rector-analyze.ps1 -ShowLogs
.\run_unit_tests.bat
```

## Documentation Index

- [Docs index](docs/INDEX.md)
- [Getting started](docs/getting-started.md)
- [Quick start FR](docs/quick-start.md)
- [Quick start EN](docs/quick-start-en.md)
- [Advanced configuration](docs/advanced-config.md)
- [Migration guide FR](docs/migration-guide.md)
- [Migration guide EN](docs/migration-guide-en.md)
