[CmdletBinding()]
param(
    [ValidateSet("Release","Debug")]
    $Configuration = "Release"
)

Push-Location $PSScriptRoot
try {
    $ModuleName = Split-Path $PSScriptRoot -Leaf
    $ErrorActionPreference = "Stop"
    $version = Get-Metadata ".\Source\${ModuleName}.psd1"
    $folder = mkdir $version -Force

    dotnet build -c $Configuration -f net452 -o "$($folder.FullName)\lib\net452"
    dotnet build -c $Configuration -f netstandard1.6 -o "$($folder.FullName)\lib\netstandard1.6"

    Get-ChildItem Source -filter "${ModuleName}.*" | Copy-Item -Dest $folder.FullName
    Get-ChildItem Source\Private, Source\Public -Filter *.ps1 -Recurse |
        Get-Content |
        Set-Content "$($folder.FullName)\${ModuleName}.psm1"
} catch {
    throw $_
} finally {
    Pop-Location
}