#requires -Module Configuration
[CmdletBinding()]
param(
    $OutputModulePath,
    $NestedModulePath
)
$OutputModule = Get-Module $OutputModulePath -ListAvailable
$NestedModule = Get-Module $NestedModulePath -ListAvailable

# Copy and then remove the extra output
Copy-Item -Path (Join-Path $NestedModule.ModuleBase Metadata.psm1) -Destination $OutputModule.ModuleBase
Remove-Item $NestedModule.ModuleBase -Recurse

# Because this is a double-module, combine the exports of both modules
# Put the ExportedFunctions of both in the manifest
Update-Metadata -Path $OutputModule.Path -PropertyName FunctionsToExport `
                -Value @(
                    @(
                        $NestedModule.ExportedFunctions.Keys
                        $OutputModule.ExportedFunctions.Keys
                    ) | Select-Object -Unique
                    # @('*')
                )

# Put the ExportedAliases of both in the manifest
Update-Metadata -Path $OutputModule.Path -PropertyName AliasesToExport `
                -Value @(
                    @(
                        $NestedModule.ExportedAliases.Keys
                        $OutputModule.ExportedAliases.Keys
                    ) | Select-Object -Unique
                    # @('*')
                )