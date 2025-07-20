# Rector PHP Analysis Tools

> **PHP analysis and modernization tools with Rector - PowerShell scripts for readable reports**
> **✨ New: Support for migration from all major PHP versions!**

## 🎯 Overview

This project provides a suite of PowerShell tools to analyze and modernize your PHP code with [Rector](https://github.com/rectorphp/rector). It transforms Rector's raw JSON output into readable and actionable reports, and now supports migration from **all major PHP versions** (5.6 → 8.4).

## ✨ Features

- **Multi-version migration**: PHP 5.6, 7.x, 8.x → modern version
- **Automatic analysis**: Complete PHP code scanning
- **Readable reports**: JSON → Markdown/HTML conversion
- **Multiple formats**: Simple, detailed, or custom
- **Interactive interface**: Intuitive PowerShell menu
- **Pre-defined configurations**: 11 supported PHP versions
- **Progressive migration**: Step-by-step or direct
- **Windows compatible**: Optimized for PowerShell 5.1+

## 🚀 Quick installation

1. **Clone the project**
   ```powershell
   git clone [REPO_URL]
   cd phpmigrations
   ```

2. **Install Rector**
   ```powershell
   .\scripts\install-rector.ps1
   ```

3. **First scan**
   ```powershell
   .\rector-analyze.ps1
   ```

## 📁 Project structure

```
phpmigrations/
├── scripts/           # Main PowerShell scripts
├── config/           # Rector configurations
├── templates/        # Report templates
├── examples/         # Usage examples
├── docs/            # Detailed documentation
└── output/          # Generated reports
```

## 🔧 Available scripts

| Script | Description | Usage |
|--------|-------------|-------|
| `rector-analyze.ps1` | **Main menu** | Interactive interface |
| `analyze-rector-simple.ps1` | Basic report | Quick summary |
| `analyze-rector-readable.ps1` | Detailed report | Complete analysis |
| `analyze-rector-detailed.ps1` | Comprehensive report | With explanations |

## 🎯 Supported PHP versions

| Source Version | Target Version | Configuration | Complexity |
|----------------|---------------|---------------|------------|
| **PHP 5.6** | PHP 7.0+ | `rector-php70.php` | ⭐⭐⭐ |
| **PHP 7.0** | PHP 7.4+ | `rector-php74.php` | ⭐⭐ |
| **PHP 7.4** | PHP 8.0+ | `rector-php80.php` | ⭐⭐ |
| **PHP 8.0** | PHP 8.1+ | `rector-php81.php` | ⭐ |
| **PHP 8.1** | PHP 8.2+ | `rector-php82.php` | ⭐ |
| **PHP 8.2** | PHP 8.3+ | `rector-php83.php` | ⭐ |
| **PHP 8.3** | PHP 8.4 | `rector-php84.php` | ⭐ |
| **Legacy** | Modern | `rector-legacy-to-modern.php` | ⭐⭐⭐⭐ |

## 📖 Usage guide

### Interactive interface
```powershell
# Interactive menu - choose your configuration
.\rector-analyze.ps1
```

### Specific migration (simple projects)
```powershell
# PHP 7.4 → PHP 8.1
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -ConfigFile "rector-php81.php"

# Legacy → Modern (direct migration)
.\rector-analyze.ps1 -ProjectPath "C:\old\project" -ConfigFile "rector-legacy-to-modern.php"
```

### Step-by-step migration (recommended for complex projects)
```powershell
# Step 1: Old PHP → PHP 7.4
.\rector-analyze.ps1 -ProjectPath "C:\project" -ConfigFile "rector-php74.php"

# Step 2: PHP 7.4 → PHP 8.1  
.\rector-analyze.ps1 -ProjectPath "C:\project" -ConfigFile "rector-php81.php"

# Step 3: PHP 8.1 → PHP 8.4
.\rector-analyze.ps1 -ProjectPath "C:\project" -ConfigFile "rector-php84.php"
```

## ⚙️ Configuration

### Pre-defined configurations
The project includes 11 ready-to-use configurations:

```
config/
├── rector-php56.php      # Migration to PHP 5.6
├── rector-php70.php      # Migration to PHP 7.0  
├── rector-php71.php      # Migration to PHP 7.1
├── rector-php72.php      # Migration to PHP 7.2
├── rector-php73.php      # Migration to PHP 7.3
├── rector-php74.php      # Migration to PHP 7.4
├── rector-php80.php      # Migration to PHP 8.0
├── rector-php81.php      # Migration to PHP 8.1
├── rector-php82.php      # Migration to PHP 8.2
├── rector-php83.php      # Migration to PHP 8.3
├── rector-php84.php      # Migration to PHP 8.4
├── rector-flexible.php        # Customizable configuration
└── rector-legacy-to-modern.php # Complete old→modern migration
```

### Choosing the right configuration

**Progressive migration (recommended):**
- Complex or critical projects
- Step-by-step migration to minimize risks
- Testing after each step

**Direct migration:**
- Simple projects or small scripts
- `rector-legacy-to-modern.php` for complete migration
- Faster but riskier

### Customization
```php
// rector-custom.php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_82,  // Your target version
    SetList::CODE_QUALITY,       // Rules according to your needs
]);
```

## 🎨 Report examples

### Simple format
```markdown
# Rector Analysis - MyProject

📊 **Summary**: 15 files, 42 possible improvements
🎯 **Target**: PHP 8.4
⚡ **Impact**: Modernization recommended
```

### Detailed format
```markdown
## 📂 src/Models/User.php
- **Line 23**: `AddArrayDefaultToArrayPropertyRector`
- **Suggestion**: Add `= []` by default
- **Before**: `private array $roles;`
- **After**: `private array $roles = [];`
```

## 🛠️ Prerequisites

- **Windows**: PowerShell 5.1 or higher
- **PHP**: 7.4+ (recommended: 8.1+)
- **Composer**: For Rector installation
- **Git**: For cloning and updates

## 📚 Documentation

- [Getting started guide](docs/getting-started.md)
- [Advanced configuration](docs/advanced-config.md)
- [Customization](docs/customization.md)
- [Troubleshooting](docs/troubleshooting.md)
- [🇫🇷 Documentation française](README.md)

## 🤝 Contribution

Contributions are welcome! See [CONTRIBUTING-EN.md](CONTRIBUTING-EN.md) for details.

📖 **Contributing documentation**: [�� English](CONTRIBUTING-EN.md) | [�� Français](CONTRIBUTING.md)

## 📄 License

MIT License - see [LICENSE](LICENSE) for more details.

## 🙏 Acknowledgments

- [Rector](https://github.com/rectorphp/rector) - The PHP modernization tool
- PHP Community - For feedback and improvements

---

**Made with ❤️ for PHP developers**
