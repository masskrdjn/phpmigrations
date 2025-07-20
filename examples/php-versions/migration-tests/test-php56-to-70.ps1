#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test PHP 5.6 to PHP 7.0 migration
.DESCRIPTION
    Tests the migration of PHP 5.6 code to PHP 7.0 syntax using Rector
#>

param(
    [switch]$DryRun,
    [string]$OutputFormat = "simple"
)

$ErrorActionPreference = "Stop"

Write-Host "🧪 Testing PHP 5.6 → PHP 7.0 Migration" -ForegroundColor Cyan
Write-Host "=" * 50

# Source and target directories
$SourceDir = "examples\php-versions\php56"
$ConfigFile = "config\rector-php70.php"

# Check if source files exist
if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory not found: $SourceDir"
    exit 1
}

if (-not (Test-Path $ConfigFile)) {
    Write-Error "Config file not found: $ConfigFile"
    exit 1
}

Write-Host "📁 Source: $SourceDir" -ForegroundColor Yellow
Write-Host "⚙️  Config: $ConfigFile" -ForegroundColor Yellow
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
    
    Write-Host "🚀 Running migration analysis..." -ForegroundColor Green
    & ".\rector-analyze.ps1" @params
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Migration test completed successfully!" -ForegroundColor Green
        
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
Write-Host "📊 Expected changes in PHP 5.6 → 7.0 migration:" -ForegroundColor Magenta
Write-Host "  • array() → []" -ForegroundColor White
Write-Host "  • func_get_args() → ...\$args" -ForegroundColor White  
Write-Host "  • Add scalar type hints" -ForegroundColor White
Write-Host "  • Add return type declarations" -ForegroundColor White
Write-Host "  • isset() checks → null coalescing operator (??)" -ForegroundColor White
Write-Host "  • Improve error handling" -ForegroundColor White
