#requires -Module ModuleBuilder
[CmdletBinding(SupportsShouldProcess)]
param(
    # A specific folder to build into
    $OutputDirectory,

    # The version of the output module
    [Alias("ModuleVersion")]
    [string]$SemVer
)

# Sanitize parameters to pass to Build-Module
$ErrorActionPreference = "Stop"
Push-Location $PSScriptRoot -StackName BuildModuleScript

if (-not $Semver -and (Get-Command gitversion -ErrorAction Ignore)) {
    if ($semver = gitversion -showvariable SemVer) {
        $null = $PSBoundParameters.Add("SemVer", $SemVer)
    }
}

try {
    Build-Module @PSBoundParameters -Target CleanBuild
} finally {
    Pop-Location -StackName BuildModuleScript
}
