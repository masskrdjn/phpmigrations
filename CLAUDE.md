# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

A Windows-focused **PowerShell wrapper around Rector** (the PHP code-modernization tool). The repo is *not* a PHP application — it is a toolkit that:

1. Runs Rector against an external PHP project (path supplied by the user).
2. Transforms Rector's raw JSON output into readable Markdown reports.
3. Logs every analysis to a persistent text log + JSON history.

The PHP code under [examples/](examples/), [failing_tests/](failing_tests/), and [unit_tests/](unit_tests/) is **test data / fixtures**, not production code being migrated. Don't refactor it.

## Common commands

All commands assume PowerShell 5.1+ on Windows, run from the repo root unless noted.

### Run an analysis
```powershell
# Interactive menu (default)
.\rector-analyze.ps1

# Non-interactive run against a specific project + config
.\rector-analyze.ps1 -ProjectPath "C:\some\php\project" -ConfigFile "rector-php81.php" -Interactive:$false

# View history / open logs
.\rector-analyze.ps1 -ShowHistory -HistoryCount 20
.\rector-analyze.ps1 -ShowLogs
.\rector-analyze.ps1 -Help
```

`-ConfigFile` accepts either an absolute path or just a basename like `rector-php84.php` — [rector-analyze.ps1](rector-analyze.ps1)'s `Resolve-ConfigFile` searches `config/`, the project's `rector-configs/`, and the cwd.

### Install/bootstrap Rector
```powershell
.\scripts\install-rector.ps1                          # installs into examples/sample-php-project by default
.\scripts\install-rector.ps1 -ProjectPath "C:\proj"   # install into a target project
.\scripts\install-rector.ps1 -Global -Force           # global install, force reinstall
```
The main script auto-falls-back to running this if no `vendor\bin\rector` is found.

### Unit tests (PHPUnit)
```powershell
# From repo root (Windows convenience wrapper)
.\run_unit_tests.bat

# Or directly
cd unit_tests
composer install        # first time only
composer test           # runs phpunit
.\vendor\bin\phpunit --filter testMigrationFailsOnSyntaxError   # single test
```
Tests live in [unit_tests/tests/](unit_tests/tests/) and **shell out to `rector-analyze.ps1`** to verify it surfaces parse errors and deprecated-feature warnings — they exercise the wrapper end-to-end, not the underlying PHP.

### Self-test the toolkit installation
```powershell
.\test-installation.ps1            # full validation
.\test-installation.ps1 -Quick     # smoke test only
```

## Architecture

### Pipeline (the only flow that matters)

```
rector-analyze.ps1  ──►  vendor\bin\rector process . --dry-run --output-format=json --config=<resolved>
       │
       ├── Initialize-Logging          (logs/rector-analysis.log + analysis-history.json)
       ├── Get-PhpFilesInProject       (excludes vendor/cache/tmp/storage/var/node_modules)
       ├── Resolve-ConfigFile          (multi-location lookup, accepts basenames)
       ├── Run-RectorAnalysis          (Push-Location $ProjectPath; runs rector)
       ├── Format-Output               (dispatches by -OutputFormat)
       │     ├── simple    → inline Format-SimpleOutput
       │     ├── readable  → delegates to scripts\analyze-rector-readable.ps1
       │     ├── detailed  → delegates to scripts\analyze-rector-detailed.ps1
       │     └── json      → raw passthrough
       └── Save-AnalysisHistory        (prepends entry, keeps last 100)
```

[rector-analyze.ps1](rector-analyze.ps1) is a single ~1200-line script holding the entire orchestration: logging, file discovery, Rector invocation, history persistence, and the interactive menu. The scripts under [scripts/](scripts/) are *only* output formatters — they consume a JSON file and emit Markdown. They don't run Rector themselves (the older copies in scripts/ have a `Get-RectorAnalysis` function but the main script always supplies pre-collected JSON via `-JsonFile`).

### Rector binary resolution order (in `Run-RectorAnalysis`)
1. `<ProjectPath>\vendor\bin\rector(.bat)`
2. `examples\sample-php-project\vendor\bin\rector(.bat)` (fallback bundled install)
3. Global `rector` on `PATH`
4. Auto-run `scripts\install-rector.ps1` and retry

When editing this logic, preserve the fallback chain — users frequently analyze projects that don't have Rector installed locally and rely on the bundled example install.

### Config files

[config/](config/) holds `rector-php{56,70,71,72,73,74,80,81,82,83,84}.php`, plus `rector-customizable.php` and `rector-old-code-to-php84.php`. Each sets a `LevelSetList::UP_TO_PHP_XX` plus a curated `SetList::*` mix. The naming convention `rector-php<NN>.php` is **load-bearing**: `Extract-PhpVersionFromConfig` parses the version out of the filename (`php(\d+)` regex) for the history JSON's `phpVersionTarget` field.

### Logs & history

- `logs/rector-analysis.log` — append-only INFO/WARNING/ERROR/DEBUG text log. DEBUG lines only print to console when `$env:RECTOR_DEBUG -eq "1"`.
- `logs/analysis-history.json` — `{ analyses: [...] }` array, **prepended** newest-first, capped at 100 entries.
- The repo's `.gitignore` excludes `output/`, `rector-output/`, `*.log`, `vendor/`, and `composer.lock`. `logs/analysis-history.json` is intentionally tracked.

### PowerShell encoding gotcha

[rector-analyze.ps1:19](rector-analyze.ps1#L19) sets `[Console]::OutputEncoding = UTF8` and every `Set-Content` / `Add-Content` uses `-Encoding UTF8`. Preserve this — French accented strings (the script is bilingual) and Rector's JSON output both break under the default Windows codepage.

## Conventions when editing

- **Don't translate the French.** Comments, log messages, and `Read-Host` prompts mix French and English by design — the project is bilingual (see [README-FR.md](README-FR.md), [CONTRIBUTING.md](CONTRIBUTING.md)). Match the surrounding language of any block you edit.
- **Don't introduce Bash/POSIX assumptions.** Target is PowerShell 5.1 on Windows; pathsep is `\`, line-continuation is backtick, env vars are `$env:NAME`.
- New config presets go in [config/](config/) following the `rector-php<NN>.php` naming. Don't break the regex.
- Output formatters in [scripts/](scripts/) must accept `-JsonFile` and `-ProjectPath`; the main script writes JSON to a temp file and invokes them with those params (see [rector-analyze.ps1:937-940](rector-analyze.ps1#L937-L940)).
