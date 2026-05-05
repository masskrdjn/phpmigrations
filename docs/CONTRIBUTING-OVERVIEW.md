# Contributing Documentation Overview

Complete bilingual guide for project contributors.

## Available Languages

### English Documentation

**[CONTRIBUTING-EN.md](../CONTRIBUTING-EN.md)** - Complete contributing guide in English.

It covers:
- How to report bugs
- How to suggest improvements
- How to submit code
- PowerShell development guidelines
- Naming conventions
- Testing and validation
- Code style

### Documentation Francaise

**[CONTRIBUTING.md](../CONTRIBUTING.md)** - Guide complet de contribution en francais.

Il couvre :
- Comment signaler un bug
- Comment proposer une amelioration
- Comment soumettre du code
- Les regles de developpement PowerShell
- Les conventions de nommage
- Les tests et validations
- Le style de code

## Quick Access by Task

| Task | English | Francais |
|------|---------|----------|
| **Report a bug** | [Bug reporting](../CONTRIBUTING-EN.md#report-a-bug) | [Signaler un bug](../CONTRIBUTING.md#signaler-un-bug) |
| **Feature request** | [Suggest an improvement](../CONTRIBUTING-EN.md#suggest-an-improvement) | [Proposer une amelioration](../CONTRIBUTING.md#proposer-une-amelioration) |
| **Code contribution** | [Submit code](../CONTRIBUTING-EN.md#submit-code) | [Soumettre du code](../CONTRIBUTING.md#soumettre-du-code) |
| **Documentation** | [Guidelines](../CONTRIBUTING-EN.md#documentation) | [Documentation](../CONTRIBUTING.md#documentation) |
| **Testing** | [Testing](../CONTRIBUTING-EN.md#testing) | [Tests](../CONTRIBUTING.md#tests) |

## Developer Resources

Both contribution guides explain:
- PowerShell development environment setup
- Testing procedures
- Code style guidelines
- Project structure
- Multi-version PHP support
- Documentation maintenance

## Quick Start for Contributors

1. Choose your language: [English](../CONTRIBUTING-EN.md) or [francais](../CONTRIBUTING.md).
2. Read the development and testing guidelines.
3. Set up your environment.
4. Run the validation commands.
5. Submit a focused pull request.

## Project-Specific Guidelines

### PowerShell Development
- Keep Windows PowerShell 5.1 compatibility in mind.
- Preserve explicit UTF-8 handling.
- Avoid Bash-only assumptions.

### PHP Configuration Management
- New presets belong in `config/`.
- Keep the `rector-php<version>.php` naming convention.
- Test version-specific behavior with representative projects.

### Documentation Maintenance
- Keep English and French docs aligned where both exist.
- Update cross-references when files are renamed or removed.
- Validate example commands before publishing them.
