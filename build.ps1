pushd $PSScriptRoot
$ErrorActionPreference = "Stop"

dotnet build -c Release -f netcoreapp1.0 -o .\lib --no-dependencies --build-profile

$folder = Get-Metadata .\PowerLine.psd1
mkdir $folder -Force

Get-ChildItem -filter PowerLine.* | Copy-Item -Dest $folder 
Copy-Item lib -dest $folder -Recurse -Force

popd