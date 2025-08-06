# validate-scoop-integrity.ps1 - Scoop repository integrity validation
# Prevents contamination from main rxiv-maker project or other package managers

param(
    [switch]$CI = $false
)

# Colors for output (if not CI)
if (-not $CI) {
    $Global:Red = "`e[31m"
    $Global:Green = "`e[32m"
    $Global:Yellow = "`e[33m"
    $Global:Blue = "`e[34m"
    $Global:Reset = "`e[0m"
} else {
    $Global:Red = ""
    $Global:Green = ""
    $Global:Yellow = ""
    $Global:Blue = ""
    $Global:Reset = ""
}

$ErrorCount = 0
$RepoRoot = Split-Path -Parent $PSScriptRoot

function Write-Info {
    param([string]$Message)
    Write-Host "${Global:Blue}[INFO]${Global:Reset} $Message"
}

function Write-Warning {
    param([string]$Message)
    Write-Host "${Global:Yellow}[WARNING]${Global:Reset} $Message"
}

function Write-Error {
    param([string]$Message)
    Write-Host "${Global:Red}[ERROR]${Global:Reset} $Message"
    $Script:ErrorCount++
}

function Write-Success {
    param([string]$Message)
    Write-Host "${Global:Green}[SUCCESS]${Global:Reset} $Message"
}

function Test-ScoopStructure {
    Write-Info "Validating Scoop repository structure..."
    
    # Required files for Scoop bucket
    $RequiredFiles = @(
        "bucket/rxiv-maker.json"
    )
    
    foreach ($File in $RequiredFiles) {
        $FilePath = Join-Path $RepoRoot $File
        if (Test-Path $FilePath) {
            Write-Success "Found required file: $File"
        } else {
            Write-Error "Missing required Scoop file: $File"
        }
    }
    
    # Validate manifest JSON structure
    $ManifestPath = Join-Path $RepoRoot "bucket/rxiv-maker.json"
    if (Test-Path $ManifestPath) {
        try {
            $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
            
            # Check required fields
            $RequiredFields = @("version", "url", "hash", "depends", "bin", "post_install")
            foreach ($Field in $RequiredFields) {
                if ($Manifest.PSObject.Properties.Name -contains $Field) {
                    Write-Success "Manifest contains required field: $Field"
                } else {
                    Write-Error "Manifest missing required field: $Field"
                }
            }
            
            # Validate Python dependency
            if ($Manifest.depends -contains "python") {
                Write-Success "Manifest has Python dependency"
            } else {
                Write-Error "Manifest missing Python dependency"
            }
            
            # Check for PyPI URL
            if ($Manifest.url -match "pypi.org") {
                Write-Success "Manifest uses PyPI URL"
            } else {
                Write-Warning "Manifest not using PyPI URL"
            }
            
        } catch {
            Write-Error "Invalid JSON in manifest: $_"
        }
    }
}

function Test-NoMainProjectContamination {
    Write-Info "Checking for main project contamination..."
    
    # Files that should NOT exist in Scoop repo
    $ForbiddenFiles = @(
        "pyproject.toml",
        "Makefile", 
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "requirements-dev.txt",
        "src/rxiv_maker",
        "noxfile.py"
    )
    
    foreach ($File in $ForbiddenFiles) {
        $FilePath = Join-Path $RepoRoot $File
        if (Test-Path $FilePath) {
            Write-Error "Found forbidden main project file: $File"
        }
    }
    
    # Check for Python files (except in scripts directory)
    $PythonFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter "*.py" | Where-Object {
        $_.FullName -notmatch [regex]::Escape((Join-Path $RepoRoot "scripts"))
    }
    
    if ($PythonFiles.Count -gt 0) {
        Write-Error "Found Python files outside scripts directory:"
        foreach ($File in $PythonFiles) {
            Write-Host "  $($File.FullName)"
        }
    }
    
    # Check for YAML files from main project
    $ForbiddenYamlFiles = @(
        ".github/workflows/test.yml",
        ".github/workflows/build-pdf.yml",
        ".github/workflows/repository-integrity.yml"
    )
    
    foreach ($File in $ForbiddenYamlFiles) {
        $FilePath = Join-Path $RepoRoot $File
        if (Test-Path $FilePath) {
            Write-Error "Found main project YAML file: $File"
        }
    }
}

function Test-NoCrossContamination {
    Write-Info "Checking for cross-contamination from other package managers..."
    
    # Homebrew-specific files
    $HomebrewPatterns = @("Formula", "*.rb")
    foreach ($Pattern in $HomebrewPatterns) {
        $Files = Get-ChildItem -Path $RepoRoot -Recurse -Filter $Pattern -ErrorAction SilentlyContinue
        if ($Files.Count -gt 0) {
            Write-Error "Found Homebrew package manager files: $Pattern"
        }
    }
    
    # VSCode extension files
    $VSCodePatterns = @("package.json", "src/extension.ts", "*.tmLanguage.json", ".vscodeignore", "tsconfig.json")
    foreach ($Pattern in $VSCodePatterns) {
        $Files = Get-ChildItem -Path $RepoRoot -Recurse -Filter $Pattern -ErrorAction SilentlyContinue
        if ($Files.Count -gt 0) {
            Write-Error "Found VSCode extension files: $Pattern"
        }
    }
}

function Test-ManifestContent {
    Write-Info "Validating manifest content..."
    
    $ManifestPath = Join-Path $RepoRoot "bucket/rxiv-maker.json"
    
    if (Test-Path $ManifestPath) {
        try {
            $Manifest = Get-Content $ManifestPath | ConvertFrom-Json
            
            # Check bin configuration
            if ($Manifest.bin -is [array] -and $Manifest.bin.Count -gt 0) {
                Write-Success "Manifest has bin configuration"
            } else {
                Write-Error "Manifest missing or invalid bin configuration"
            }
            
            # Check post_install script
            if ($Manifest.post_install -is [array] -and $Manifest.post_install.Count -gt 0) {
                Write-Success "Manifest has post_install script"
                
                # Check for pip install command
                $HasPipInstall = $false
                foreach ($Command in $Manifest.post_install) {
                    if ($Command -match "pip.*install") {
                        $HasPipInstall = $true
                        break
                    }
                }
                
                if ($HasPipInstall) {
                    Write-Success "Manifest includes pip install command"
                } else {
                    Write-Warning "Manifest missing pip install command"
                }
            } else {
                Write-Error "Manifest missing post_install script"
            }
            
            # Check autoupdate configuration
            if ($Manifest.PSObject.Properties.Name -contains "autoupdate") {
                Write-Success "Manifest has autoupdate configuration"
            } else {
                Write-Warning "Manifest missing autoupdate configuration"
            }
            
        } catch {
            Write-Error "Error validating manifest content: $_"
        }
    }
}

# Main execution
Write-Info "Starting Scoop repository integrity validation..."
Write-Info "Repository root: $RepoRoot"

Test-ScoopStructure
Test-NoMainProjectContamination
Test-NoCrossContamination 
Test-ManifestContent

Write-Host ""
if ($ErrorCount -eq 0) {
    Write-Success "✅ All Scoop repository validations passed successfully!"
    exit 0
} else {
    Write-Error "❌ Found $ErrorCount validation error(s). Repository integrity may be compromised."
    Write-Error "Please review the errors above and fix any issues before proceeding."
    exit 1
}