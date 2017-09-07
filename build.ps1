[CmdletBinding()]
param(
    [ValidateSet("Release","Debug")]
    $Configuration = "Release"
)

Push-Location $PSScriptRoot
try {
    $BuildTimer = New-Object System.Diagnostics.Stopwatch
    $BuildTimer.Start()

    $ModuleName = Split-Path $PSScriptRoot -Leaf
    $ErrorActionPreference = "Stop"
    $version = Get-Metadata ".\Source\${ModuleName}.psd1"
    $folder = mkdir $version -Force

    Get-ChildItem Source -filter "${ModuleName}.*" |
        Copy-Item -Dest $folder.FullName -PassThru |
        ForEach {
            Write-Host "  $($_.Name) -> $($_.FullName)"
        }

    Get-ChildItem Source\Private, Source\Public -Filter *.ps1 -Recurse |
        Sort-Object Directory, Name |
        Get-Content |
        Set-Content "$($folder.FullName)\${ModuleName}.psm1"
    Write-Host "  PowerLine -> $($folder.FullName)\${ModuleName}.psm1"

    Write-Host
    Write-Host "Module build finished." -ForegroundColor Green
    $BuildTimer.Stop()
    Write-Host "Total Elapsed $($BuildTimer.Elapsed.ToString("hh\:mm\:ss\.ff"))"
} catch {
    throw $_
} finally {
    Pop-Location
}