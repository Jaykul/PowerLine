#!/usr/bin/env powershell
using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace PoshCode.Pansies

# Ensure the global prompt variable exists and is typed the way we expect
[System.Collections.Generic.List[PoshCode.PowerLine.PowerLineBlock]]$Global:Prompt = [PoshCode.PowerLine.PowerLineBlock[]]@(
    if (Test-Path Variable:Prompt) {
        if ($Prompt.Colors) {
            try {
                [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$script:Colors = $Prompt.Colors
            } catch {
                Write-Warning "Couldn't use existing `$Prompt.Colors"
            }
        }

        $Prompt | ForEach-Object { [PoshCode.PowerLine.PowerLineBlock]$_ }
    }
)

$xlr8r = [psobject].assembly.gettype("System.Management.Automation.TypeAccelerators")
@{
    "PowerLineBlock" = [PoshCode.PowerLine.PowerLineBlock]
    "PowerLineCap" = [PoshCode.PowerLine.PowerLineCap]
    "Space" = [PoshCode.PowerLine.Space]
}.GetEnumerator().ForEach({
    $Name = $_.Key
    $Type = $_.Value
    if ($xlr8r::AddReplace) {
        $xlr8r::AddReplace( $Name, $Type)
    } else {
        $null = $xlr8r::Remove( $Name )
        $xlr8r::Add( $Name, $Type)
    }
    trap [System.Management.Automation.MethodInvocationException] {
        if ($xlr8r::get.keys -contains $Name) {
            if ($xlr8r::get[$Name] -ne $Type) {
                Write-Error "Cannot add accelerator [$Name] for [$($Type.FullName)]n                  [$Name] is already defined as [$($xlr8r::get[$Name].FullName)]"
            }
            Continue;
        }
        throw
    }
})
