# Migration Test Scripts

This directory contains test scenarios for different migration paths.

## Test Scenarios

### 1. Progressive Migration
Test gradual updates from one version to the next:
- `test-php56-to-70.ps1` - PHP 5.6 to 7.0
- `test-php70-to-74.ps1` - PHP 7.0 to 7.4  
- `test-php74-to-81.ps1` - PHP 7.4 to 8.1
- `test-php81-to-84.ps1` - PHP 8.1 to 8.4

### 2. Direct Migration
Test direct jumps to modern versions:
- `test-legacy-to-modern.ps1` - Complete modernization
- `test-php56-to-84.ps1` - Direct to latest

### 3. Feature-Specific Tests
Test specific language features:
- `test-array-syntax.ps1` - Array syntax modernization
- `test-type-declarations.ps1` - Type hint additions
- `test-null-coalescing.ps1` - Null coalescing operators

## Usage

Run individual test scripts:
```powershell
.\migration-tests\test-php56-to-70.ps1
```

Or use the main analyzer:
```powershell
.\rector-analyze.ps1 -ProjectPath "examples\php-versions\php56" -ConfigFile "config\rector-php70.php"
```
