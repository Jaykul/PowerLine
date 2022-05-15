#!/usr/bin/env powershell
using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace PoshCode.Pansies

# Ensure the global prompt variable exists and is typed the way we expect
[System.Collections.Generic.List[ScriptBlock]]$Global:Prompt = [ScriptBlock[]]@(
    if (Test-Path Variable:Prompt) {
        if ($Prompt.Colors) {
            try {
                [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$script:Colors = $Prompt.Colors
            } catch {
                Write-Warning "Couldn't use existing `$Prompt.Colors"
            }
        }

        $Prompt | ForEach-Object { $_ }
    }
)

Add-MetadataConverter @{ [char] = { "'$_'" } }
