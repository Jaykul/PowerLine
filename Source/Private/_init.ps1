#!/usr/bin/env powershell
using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace PoshCode.Pansies

[PoshCode.TerminalBlock]::DefaultCaps = "","$([char]0xE0B0)"

# Ensure the global prompt variable exists and is typed the way we expect
[System.Collections.Generic.List[PoshCode.TerminalBlock]]$Global:Prompt = [PoshCode.TerminalBlock[]]@(
    if (Test-Path Variable:Prompt) {
        $Prompt | ForEach-Object { [PoshCode.TerminalBlock]$_ }
    }
)
