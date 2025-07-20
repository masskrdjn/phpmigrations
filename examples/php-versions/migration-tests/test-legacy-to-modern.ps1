#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test complete legacy to modern PHP migration
.DESCRIPTION
    Tests the migration from legacy PHP (5.6+) to modern PHP 8.4 using Rector
#>

param(
    [switch]$DryRun,
    [string]$OutputFormat = "detailed",
    [string]$SourceVersion = "php56"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Testing Legacy → Modern PHP Migration" -ForegroundColor Cyan
Write-Host "=" * 50

# Source and target directories
$SourceDir = "examples\php-versions\$SourceVersion"
$ConfigFile = "config\rector-legacy-to-modern.php"

# Check if source files exist
if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory not found: $SourceDir"
    exit 1
}

if (-not (Test-Path $ConfigFile)) {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}

Write-Host "📁 Source: $SourceDir ($SourceVersion)" -ForegroundColor Yellow
Write-Host "⚙️  Config: $ConfigFile" -ForegroundColor Yellow
Write-Host "🎯 Target: PHP 8.4 (Modern)" -ForegroundColor Yellow
Write-Host "🔍 Mode: $(if ($DryRun) { 'Dry Run (Safe)' } else { 'Live Migration' })" -ForegroundColor Yellow
Write-Host ""

# Run the migration test
try {
    $params = @{
        ProjectPath = $SourceDir
        ConfigFile = $ConfigFile
        DryRun = if ($DryRun) { $true } else { $false }
        OutputFormat = $OutputFormat
        Interactive = $false
    }
    
    Write-Host "🚀 Running complete modernization..." -ForegroundColor Green
    & ".\rector-analyze.ps1" @params
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Complete migration test completed successfully!" -ForegroundColor Green
        
        if (-not $DryRun) {
            Write-Host "💡 Run with -DryRun to preview changes safely" -ForegroundColor Cyan
        }
    } else {
        Write-Host "❌ Migration test failed with exit code: $LASTEXITCODE" -ForegroundColor Red
        exit $LASTEXITCODE
    }
    
} catch {
    Write-Host "❌ Error during migration test: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📊 Expected changes in Legacy → Modern migration:" -ForegroundColor Magenta
Write-Host "  🔧 Syntax Modernization:" -ForegroundColor Cyan
Write-Host "    • array() → []" -ForegroundColor White
Write-Host "    • isset() → null coalescing operator (??)" -ForegroundColor White
Write-Host "    • Anonymous functions → arrow functions" -ForegroundColor White
Write-Host ""
Write-Host "  🛡️  Type System:" -ForegroundColor Cyan
Write-Host "    • Add scalar type hints" -ForegroundColor White
Write-Host "    • Add return type declarations" -ForegroundColor White
Write-Host "    • Add property types" -ForegroundColor White
Write-Host "    • Union and intersection types" -ForegroundColor White
Write-Host ""
Write-Host "  ⚡ Modern Features:" -ForegroundColor Cyan
Write-Host "    • Constructor property promotion" -ForegroundColor White
Write-Host "    • Match expressions" -ForegroundColor White
Write-Host "    • Named arguments" -ForegroundColor White
Write-Host "    • Attributes instead of docblocks" -ForegroundColor White
Write-Host "    • Enums instead of class constants" -ForegroundColor White
Write-Host ""
Write-Host "  📚 Best Practices:" -ForegroundColor Cyan
Write-Host "    • Strict types declaration" -ForegroundColor White
Write-Host "    • Improved error handling" -ForegroundColor White
Write-Host "    • String function modernization" -ForegroundColor White
Write-Host "    • Array function improvements" -ForegroundColor White
