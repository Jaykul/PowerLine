#!/usr/bin/env powershell
using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace PoshCode.Pansies

# Ensure the global prompt variable exists and is typed the way we expect
[System.Collections.Generic.List[PoshCode.PowerLine.Block]]$Global:Prompt = [PoshCode.PowerLine.Block[]]@(
    if (Test-Path Variable:Prompt) {
        if ($Prompt.Colors) {
            try {
                [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$script:Colors = $Prompt.Colors
            } catch {
                Write-Warning "Couldn't use existing `$Prompt.Colors"
            }
        }

        $Prompt | ForEach-Object { [PoshCode.PowerLine.Block]$_ }
    }
)

<#
Add-MetadataConverter @{
    PowerLineBlock = { New-PowerLineBlock @Args }
    [char]                     = { "'$_'" }
    [PoshCode.PowerLine.Block] = {
        if ($_.Object -is [PoshCode.PowerLine.Space]) {
            "PowerLineBlock -$($_.Object) -Separator @('$($_.Separator.Left)', '$($_.Separator.Right)') -Cap @('$($_.Cap.Left)', '$($_.Cap.Right)')"
        } elseif ($_.Object -is [scriptblock]) {
            "PowerLineBlock $("(ScriptBlock '{0}')" -f ($_.Object -replace "'", "''")) -Separator @('$($_.Separator.Left)', '$($_.Separator.Right)') -Cap @('$($_.Cap.Left)', '$($_.Cap.Right)') -ForegroundColor '$($_.ForegroundColor)' -BackgroundColor '$($_.BackgroundColor)' -ElevatedForegroundColor '$($_.ElevatedForegroundColor)' -ElevatedBackgroundColor '$($_.ElevatedBackgroundColor)' -ErrorForegroundColor '$($_.ErrorForegroundColor)' -ErrorBackgroundColor '$($_ErrorBackgroundColor)'"
        } else {
            "PowerLineBlock $(ConvertTo-Metadata $_.Object) -Separator @('$($_.Separator.Left)', '$($_.Separator.Right)') -Cap @('$($_.Cap.Left)', '$($_.Cap.Right)') -ForegroundColor '$($_.ForegroundColor)' -BackgroundColor '$($_.BackgroundColor)' -ElevatedForegroundColor '$($_.ElevatedForegroundColor)' -ElevatedBackgroundColor '$($_.ElevatedBackgroundColor)' -ErrorForegroundColor '$($_.ErrorForegroundColor)' -ErrorBackgroundColor '$($_ErrorBackgroundColor)'"
        }
    }
}
#>
