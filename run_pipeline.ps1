param(
    [switch]$FullRawRebuild
)

$ErrorActionPreference = "Stop"
$Python = if ($env:PYTHON) { $env:PYTHON } else { "python" }
$Rscript = if ($env:RSCRIPT) { $env:RSCRIPT } else { "Rscript" }

function Invoke-Step {
    param([string]$Name, [scriptblock]$Command)
    Write-Host "==> $Name" -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit code $LASTEXITCODE"
    }
}

if ($FullRawRebuild) {
    Invoke-Step "Build data inventory" { & $Python code/python/00_build_data_inventory.py }
    Invoke-Step "Build harmonized panel" { & $Python code/python/01_build_panel.py }
} else {
    Write-Host "==> Skipping raw-source rebuild; using included processed panel." -ForegroundColor Yellow
    Write-Host "    Run ./run_pipeline.ps1 -FullRawRebuild to rebuild from configured local source archives." -ForegroundColor Yellow
}

Invoke-Step "Generate descriptive tables and figures" { & $Python code/python/02_descriptive_analysis.py }
Invoke-Step "Build dashboard" { & $Python code/python/03_build_dashboard.py }
Invoke-Step "Estimate econometric models" { & $Rscript code/r/03_econometric_models.R }
Invoke-Step "Generate documents" { & $Python code/python/04_generate_documents.py }
Invoke-Step "Run panel integrity tests" { & $Python tests/test_panel_integrity.py }
Invoke-Step "Run output tests" { & $Python tests/test_repository_outputs.py }
Invoke-Step "Run publication readiness tests" { & $Python tests/test_publication_readiness.py }
