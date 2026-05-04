#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Run all PHP version migration tests
.DESCRIPTION
    Executes all migration test scenarios and provides a comprehensive report
#>

param(
    [switch]$DryRun,
    [switch]$Verbose,
    [string]$OutputDir = "output\test-results"
)

$ErrorActionPreference = "Stop"

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "🧪 PHP Migration Tests Suite" -ForegroundColor Cyan
Write-Host "=" * 50
Write-Host "📊 Running comprehensive migration tests..." -ForegroundColor Green
Write-Host ""

$TestResults = @()
$StartTime = Get-Date

# Test scenarios to run
$TestScenarios = @(
    @{
        Name = "PHP 5.6 → 7.0"
        Script = "test-php56-to-70.ps1"
        Description = "Basic modernization"
    },
    @{
        Name = "Old Code → PHP 8.4 (PHP 5.6)"
        Script = "test-old-code-to-php84.ps1"
        Description = "Complete modernization from PHP 5.6"
        Params = @{ SourceVersion = "php56" }
    },
    @{
        Name = "Old Code → PHP 8.4 (PHP 7.0)"
        Script = "test-old-code-to-php84.ps1"
        Description = "Complete modernization from PHP 7.0"
        Params = @{ SourceVersion = "php70" }
    },
    @{
        Name = "Old Code → PHP 8.4 (PHP 7.4)"
        Script = "test-old-code-to-php84.ps1"
        Description = "Complete modernization from PHP 7.4"
        Params = @{ SourceVersion = "php74" }
    }
)

foreach ($scenario in $TestScenarios) {
    Write-Host "🔍 Testing: $($scenario.Name)" -ForegroundColor Yellow
    Write-Host "   $($scenario.Description)" -ForegroundColor Gray
    
    $testStart = Get-Date
    $scriptPath = "examples\php-versions\migration-tests\$($scenario.Script)"
    
    try {
        # Prepare parameters
        $params = @{
            DryRun = if ($DryRun) { $true } else { $false }
            OutputFormat = if ($Verbose) { "detailed" } else { "simple" }
        }
        
        # Add scenario-specific parameters
        if ($scenario.Params) {
            foreach ($key in $scenario.Params.Keys) {
                $params[$key] = $scenario.Params[$key]
            }
        }
        
        # Run the test
        $output = & $scriptPath @params 2>&1
        $exitCode = $LASTEXITCODE
        $testEnd = Get-Date
        $duration = $testEnd - $testStart
        
        $result = @{
            Name = $scenario.Name
            Status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
            ExitCode = $exitCode
            Duration = $duration.TotalSeconds
            Output = $output -join "`n"
        }
        
        if ($exitCode -eq 0) {
            Write-Host "   ✅ PASSED" -ForegroundColor Green
        } else {
            Write-Host "   ❌ FAILED (Exit code: $exitCode)" -ForegroundColor Red
        }
        
        Write-Host "   ⏱️  Duration: $([math]::Round($duration.TotalSeconds, 2))s" -ForegroundColor Cyan
        
    } catch {
        $testEnd = Get-Date
        $duration = $testEnd - $testStart
        
        $result = @{
            Name = $scenario.Name
            Status = "ERROR"
            ExitCode = -1
            Duration = $duration.TotalSeconds
            Output = $_.Exception.Message
        }
        
        Write-Host "   ❌ ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    $TestResults += $result
    Write-Host ""
}

# Generate summary report
$EndTime = Get-Date
$TotalDuration = $EndTime - $StartTime

$PassCount = ($TestResults | Where-Object { $_.Status -eq "PASS" }).Count
$FailCount = ($TestResults | Where-Object { $_.Status -eq "FAIL" }).Count
$ErrorCount = ($TestResults | Where-Object { $_.Status -eq "ERROR" }).Count
$TotalCount = $TestResults.Count

Write-Host "📋 Test Summary Report" -ForegroundColor Cyan
Write-Host "=" * 50
Write-Host "📊 Results:" -ForegroundColor Yellow
Write-Host "   ✅ Passed: $PassCount" -ForegroundColor Green
Write-Host "   ❌ Failed: $FailCount" -ForegroundColor Red
Write-Host "   🚫 Errors: $ErrorCount" -ForegroundColor Magenta
Write-Host "   📈 Total:  $TotalCount" -ForegroundColor Cyan
Write-Host ""
Write-Host "⏱️  Total Duration: $([math]::Round($TotalDuration.TotalSeconds, 2))s" -ForegroundColor Cyan
Write-Host ""

# Detailed results
if ($Verbose -or $FailCount -gt 0 -or $ErrorCount -gt 0) {
    Write-Host "📋 Detailed Results:" -ForegroundColor Yellow
    Write-Host ""
    
    foreach ($result in $TestResults) {
        $statusColor = switch ($result.Status) {
            "PASS" { "Green" }
            "FAIL" { "Red" }
            "ERROR" { "Magenta" }
        }
        
        Write-Host "🔍 $($result.Name)" -ForegroundColor White
        Write-Host "   Status: $($result.Status)" -ForegroundColor $statusColor
        Write-Host "   Duration: $([math]::Round($result.Duration, 2))s" -ForegroundColor Cyan
        
        if ($result.Status -ne "PASS" -or $Verbose) {
            Write-Host "   Output:" -ForegroundColor Gray
            $result.Output -split "`n" | ForEach-Object {
                Write-Host "     $_" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
}

# Save detailed report to file
$reportPath = "$OutputDir\migration-test-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$report = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalDuration = $TotalDuration.TotalSeconds
    Summary = @{
        Total = $TotalCount
        Passed = $PassCount
        Failed = $FailCount
        Errors = $ErrorCount
    }
    Results = $TestResults
}

$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "📄 Detailed report saved to: $reportPath" -ForegroundColor Cyan

# Exit with appropriate code
if ($FailCount -gt 0 -or $ErrorCount -gt 0) {
    Write-Host ""
    Write-Host "❌ Some tests failed. Check the detailed report for more information." -ForegroundColor Red
    exit 1
} else {
    Write-Host ""
    Write-Host "✅ All migration tests passed successfully!" -ForegroundColor Green
    exit 0
}
