Push-Location $PSScriptRoot
try {
    $ModuleName = Split-Path $PSScriptRoot -Leaf
    $ErrorActionPreference = "Stop"

    dotnet build -c Release # -f netstandard1.6 -o .\lib --no-dependencies

    $folder = Get-Metadata ".\Source\${ModuleName}.psd1"
    mkdir $folder -Force

    Get-ChildItem Source -filter "${ModuleName}.*" | Copy-Item -Dest $folder
    Get-ChildItem Source\Private, Source\Public -Filter *.ps1 -Recurse |
        Get-Content |
        Set-Content "$folder\${ModuleName}.psm1"
    Copy-Item lib -dest $folder -Recurse -Force
} catch {
    throw $_
} finally {
    Pop-Location
}