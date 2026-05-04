# 🚀 Quick Start Guide - Multi-version Migration

> **Express setup to migrate your PHP code to a modern version**

## 🎯 First steps (5 minutes)

### 1. Identify your current PHP version

```powershell
# In your project folder
php -v
```

### 2. Choose your migration strategy

| Situation | Recommended Configuration | Estimated Time |
|-----------|---------------------------|----------------|
| **PHP 5.6-7.3 project** | `rector-old-code-to-php84.php` | 2-4 hours |
| **PHP 7.4 project** | `rector-php81.php` | 30 minutes |
| **PHP 8.0-8.2 project** | `rector-php84.php` | 15 minutes |
| **Progressive migration** | Step-by-step configurations | Variable |

### 3. Run your first analysis

```powershell
# Interactive mode (recommended for beginners)
.\rector-analyze.ps1

# Direct mode (if you know your configuration)
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php" -DryRun:$true
```

## 🎮 Usage in VS Code

### Via tasks (Ctrl+Shift+P → "Tasks: Run Task")

- **🚀 Rector: Interactive Menu** - Complete interface
- **🔄 Migration: Old PHP Code → PHP 8.4** - Complete migration
- **🎯 Migration: PHP 7.4 → 8.1** - Common migration
- **🚀 Migration: PHP 8.x → 8.4** - Latest version

### Via command line

```powershell
# Most common migration: PHP 7.4 → PHP 8.1
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php"

# Very old project → Modern PHP
.\rector-analyze.ps1 -ConfigFile "config\rector-old-code-to-php84.php"

# Latest PHP version
.\rector-analyze.ps1 -ConfigFile "config\rector-php84.php"
```

## 📊 Understanding reports

### Simple Format
```markdown
📊 Summary: 25 files analyzed, 67 possible improvements
🎯 Target: PHP 8.1
⚡ Impact: Migration recommended (performance gain expected)
```

### Detailed Format
- **By file**: List of specific modifications
- **By category**: Types of improvements (performance, security, readability)
- **Examples**: Before/after code transformations

## ⚡ Express migrations

### Scenario 1: Old WordPress site
```powershell
# Step 1: Analyze feasibility
.\rector-analyze.ps1 -ProjectPath "C:\wordpress" -ConfigFile "config\rector-php74.php" -DryRun:$true

# Step 2: If OK, apply (remove -DryRun)
.\rector-analyze.ps1 -ProjectPath "C:\wordpress" -ConfigFile "config\rector-php74.php" -DryRun:$false
```

### Scenario 2: Modern Laravel application
```powershell
# Direct migration to PHP 8.4
.\rector-analyze.ps1 -ProjectPath "C:\my-laravel" -ConfigFile "config\rector-php84.php"
```

### Scenario 3: Custom PHP script
```powershell
# Customizable starter configuration
.\rector-analyze.ps1 -ProjectPath "C:\my-script" -ConfigFile "config\rector-customizable.php"
```

## 🛡️ Safe mode (recommended)

```powershell
# ALWAYS start in dry-run mode (default)
.\rector-analyze.ps1 -DryRun:$true

# Apply ONLY after validation
.\rector-analyze.ps1 -DryRun:$false
```

## 🎯 Specialized configurations

### Progressive migration (complex projects)
```powershell
# Step 1: Old PHP → PHP 7.4
.\rector-analyze.ps1 -ConfigFile "config\rector-php74.php"

# Step 2: PHP 7.4 → PHP 8.1
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php"

# Step 3: PHP 8.1 → PHP 8.4
.\rector-analyze.ps1 -ConfigFile "config\rector-php84.php"
```

### Direct migration (simple projects)
```powershell
# All at once
.\rector-analyze.ps1 -ConfigFile "config\rector-old-code-to-php84.php"
```

## 🔧 Quick customization

### Modify an existing configuration

1. **Copy** a base configuration:
   ```powershell
   copy config\rector-php81.php config\rector-custom.php
   ```

2. **Edit** according to your needs:
   ```php
   // In rector-custom.php
   $rectorConfig->skip([
       __DIR__ . '/my-special-folder',  // Exclude folders
       \Rector\Php81\Rector\SomeRule::class,  // Exclude rules
   ]);
   ```

3. **Use** your configuration:
   ```powershell
   .\rector-analyze.ps1 -ConfigFile "config\rector-custom.php"
   ```

## 📋 Pre-migration checklist

- [ ] **Complete project backup**
- [ ] **Existing tests** are functional
- [ ] **Test environment** available
- [ ] **Target PHP version** installed on server
- [ ] **Composer dependencies** verified

## 📋 Post-migration checklist

- [ ] **Automated tests** pass
- [ ] **Manual application testing**
- [ ] **Performance** verified
- [ ] **Logs** without PHP errors
- [ ] **Documentation** updated

## 🆘 Quick troubleshooting

### "Class not found"
```powershell
composer install
composer update
```

### "Memory limit exceeded"
```powershell
php -d memory_limit=2G .\rector-analyze.ps1
```

### "Too many changes"
```powershell
# Step-by-step migration
.\rector-analyze.ps1 -ConfigFile "config\rector-php74.php"  # First 7.4
.\rector-analyze.ps1 -ConfigFile "config\rector-php81.php"  # Then 8.1
```

## 💡 Pro tips

1. **Start small**: Test on a subfolder first
2. **Dry-run mode**: Always analyze before applying
3. **Git**: Commit before any migration
4. **Tests**: Run your tests after each step
5. **Progressive**: Prefer step-by-step migrations for large projects

---

🎉 **Ready to modernize your PHP code!** 

For more details, see the [Complete Migration Guide](migration-guide-en.md).
