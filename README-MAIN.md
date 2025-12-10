# Rector PHP Analysis Tools

> **PHP analysis and modernization tools with Rector - PowerShell scripts for readable reports**
> **Outils d'analyse et de modernisation PHP avec Rector - Scripts PowerShell pour rapports lisibles**

## 🌐 Choose your language / Choisissez votre langue

### 🇺🇸 **English (Default)**
**[📖 English Documentation →](README-EN.md)**

Complete documentation in English including:
- Installation and setup
- Multi-version PHP migration (5.6 → 8.4)
- 11 pre-configured migration paths
- Step-by-step guides
- VS Code integration
- **📊 NEW: Analysis logging & history**

### 🇫🇷 **Français**
**[📖 Documentation Française →](README-FR.md)**

Documentation complète en français incluant :
- Installation et configuration
- Migration PHP multi-versions (5.6 → 8.4)
- 11 chemins de migration pré-configurés
- Guides étape par étape
- Intégration VS Code
- **📊 NOUVEAU : Logging et historique des analyses**

---

## 🚀 Quick Start

```powershell
# Install / Installation
.\scripts\install-rector.ps1

# Run interactive menu / Menu interactif
.\rector-analyze.ps1

# View analysis history / Consulter l'historique
.\rector-analyze.ps1 -ShowHistory

# Open logs / Ouvrir les logs
.\rector-analyze.ps1 -ShowLogs
```

## ✨ New Features / Nouvelles fonctionnalités

### 📊 Logging & History / Logging et Historique
- **Analysis tracking**: Every analysis is logged with details
- **Persistent history**: JSON history of last 100 analyses
- **Log levels**: INFO, WARNING, ERROR, DEBUG
- **Interactive menu**: New options to view history and logs

### 📁 Log Files / Fichiers de logs
```
logs/
├── rector-analysis.log      # Detailed text log
└── analysis-history.json    # Structured JSON history
```

## 📊 Supported PHP Versions / Versions PHP supportées

**Migration paths / Chemins de migration :**
- PHP 5.6 → 7.0 → 7.4 → 8.1 → 8.4
- Direct legacy → modern migration
- Progressive step-by-step approach

## 📚 Documentation Index

**[📖 Complete Documentation Index →](docs/INDEX.md)**

---

**Made with ❤️ for PHP developers** | **Fait avec ❤️ pour les développeurs PHP**
