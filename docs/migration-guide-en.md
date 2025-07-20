# Multi-version PHP Migration Guide

> **Complete guide to migrate your PHP code from any version to a newer one**

## 📋 Supported PHP versions

Our tool now supports migration from and to all major PHP versions:

### Supported versions as source AND target:
- **PHP 5.6** - Latest stable PHP 5.x version
- **PHP 7.0** - First PHP 7.x version with scalar types
- **PHP 7.1** - Nullable types, void return type
- **PHP 7.2** - Object type hint, parameter type widening
- **PHP 7.3** - Flexible heredoc/nowdoc, trailing commas
- **PHP 7.4** - Typed properties, arrow functions
- **PHP 8.0** - Union types, constructor property promotion, match
- **PHP 8.1** - Enums, fibers, intersection types
- **PHP 8.2** - Readonly classes, DNF types
- **PHP 8.3** - Typed class constants, json_validate()
- **PHP 8.4** - Property hooks, asymmetric visibility

## 🎯 Available configurations

### Target version configurations

| Configuration | Description | Recommended for |
|---------------|-------------|-----------------|
| `rector-php56.php` | Migration to PHP 5.6 | Very old legacy projects |
| `rector-php70.php` | Migration to PHP 7.0 | First step to modern PHP |
| `rector-php71.php` | Migration to PHP 7.1 | Adding nullable types |
| `rector-php72.php` | Migration to PHP 7.2 | Type improvements |
| `rector-php73.php` | Migration to PHP 7.3 | Modern syntax |
| `rector-php74.php` | Migration to PHP 7.4 | Typed properties |
| `rector-php80.php` | Migration to PHP 8.0 | Major PHP 8 features |
| `rector-php81.php` | Migration to PHP 8.1 | Enums and improvements |
| `rector-php82.php` | Migration to PHP 8.2 | Readonly classes |
| `rector-php83.php` | Migration to PHP 8.3 | Typed constants |
| `rector-php84.php` | Migration to PHP 8.4 | Latest innovations |

### Specialized configurations

| Configuration | Description | Usage |
|---------------|-------------|-------|
| `rector-flexible.php` | Adaptable configuration | Advanced customization |
| `rector-legacy-to-modern.php` | Complete migration | Very old projects → Modern PHP |

## 🚀 Common migration scenarios

### 1. Progressive migration (recommended)

For a PHP 5.6 project, migrate step by step:

```powershell
# Step 1: PHP 5.6 → PHP 7.0
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -ConfigFile "rector-php70.php"

# Step 2: PHP 7.0 → PHP 7.4
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -ConfigFile "rector-php74.php"

# Step 3: PHP 7.4 → PHP 8.1
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -ConfigFile "rector-php81.php"
```

### 2. Direct migration (simple projects)

To migrate directly to a recent version:

```powershell
# Old PHP → PHP 8.4 (latest version)
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -ConfigFile "rector-legacy-to-modern.php"
```

### 3. Targeted migration

To migrate to a specific version:

```powershell
# To PHP 8.0 for server compatibility
.\rector-analyze.ps1 -ProjectPath "C:\my\project" -ConfigFile "rector-php80.php"
```

## 📊 Compatibility matrix

### From PHP 5.6
- ✅ **PHP 7.0** - Safe migration, major changes
- ✅ **PHP 7.4** - Recommended progressive migration
- ⚠️ **PHP 8.0** - Watch for breaking changes
- ⚠️ **PHP 8.4** - Use `rector-legacy-to-modern.php`

### From PHP 7.x
- ✅ **PHP 8.1** - Natural migration
- ✅ **PHP 8.2** - Few breaking changes
- ✅ **PHP 8.3** - Safe migration
- ✅ **PHP 8.4** - Recommended

### From PHP 8.x
- ✅ **Higher versions** - Very safe migration
- ✅ **Modern features** - Progressive adoption

## ⚙️ Usage with interactive interface

1. **Launch the main script:**
   ```powershell
   .\rector-analyze.ps1
   ```

2. **Select your project** (option 1-4)

3. **Choose the appropriate configuration** according to your migration

4. **Select report format** according to your needs

## 🎛️ Custom configurations

### Adapt an existing configuration

Copy a configuration and modify it:

```php
// In rector-custom.php
$rectorConfig->sets([
    LevelSetList::UP_TO_PHP_82,  // Your target version
    SetList::CODE_QUALITY,       // Rules according to your needs
]);

$rectorConfig->phpVersion(\Rector\Core\ValueObject\PhpVersion::PHP_82);
```

### Exclude certain rules

```php
$rectorConfig->skip([
    // Exclude folders
    __DIR__ . '/legacy',
    
    // Exclude specific rules
    \Rector\Php74\Rector\Property\TypedPropertyRector::class,
]);
```

## 🔍 Pre-migration analysis

### Check current PHP version

```powershell
# In your project
php -v

# Search for potential incompatibilities
.\rector-analyze.ps1 -OutputFormat "detailed" -DryRun:$true
```

### Estimate migration complexity

| Project size | PHP 5.x → 7.x | PHP 7.x → 8.x | PHP 8.x → 8.y |
|--------------|---------------|---------------|---------------|
| < 10 files   | 1-2 hours     | 30 minutes    | 15 minutes    |
| 10-100 files | 1-2 days      | 2-4 hours     | 1 hour        |
| 100+ files   | 1-2 weeks     | 1-2 days      | 2-4 hours     |

## ⚠️ Important precautions

### Before migration

1. **Complete backup** of your project
2. **Existing tests** functional
3. **Dependencies documentation**
4. **Test environment** prepared

### During migration

1. **Dry-run mode** enabled by default
2. **Progressive migration** recommended
3. **Frequent testing** after each step
4. **Validation** on test environment

### After migration

1. **Complete testing** of the application
2. **Performance** verified
3. **Dependencies** updated
4. **Documentation** updated

## 🏗️ Practical examples

### Old WordPress project

```powershell
# WordPress PHP 5.6 → PHP 7.4
.\rector-analyze.ps1 -ProjectPath "C:\wordpress" -ConfigFile "rector-php74.php"
```

### Laravel application

```powershell
# Laravel → PHP 8.2
.\rector-analyze.ps1 -ProjectPath "C:\my-laravel" -ConfigFile "rector-php82.php"
```

### Custom script

```powershell
# Custom script → Modern PHP
.\rector-analyze.ps1 -ProjectPath "C:\my-script" -ConfigFile "rector-legacy-to-modern.php"
```

## 📈 Benefits by version

### Migration to PHP 7.x
- **Performance**: 2x faster than PHP 5.6
- **Scalar types**: Better reliability
- **Return types**: More robust code
- **Null coalescing**: Simplified syntax

### Migration to PHP 8.x
- **JIT Compiler**: Increased performance
- **Union types**: Type flexibility
- **Match expressions**: Switch alternative
- **Constructor promotion**: More concise code

### Migration to PHP 8.4
- **Property hooks**: Modern encapsulation
- **Asymmetric visibility**: Granular control
- **Performance**: Continuous optimizations
- **Security**: Bug fixes

## 🆘 Troubleshooting

### Common errors

**Error:** "Class not found"
```powershell
# Solution: Install/update Composer
composer install
composer update
```

**Error:** "Memory limit exceeded"
```powershell
# Solution: Increase PHP limit
php -d memory_limit=2G vendor/bin/rector
```

**Error:** "Syntax error"
```powershell
# Solution: Progressive migration
# Use an intermediate version
```

---

💡 **Tip**: Always start with a `dry-run` migration to assess the scope of changes before applying them!
