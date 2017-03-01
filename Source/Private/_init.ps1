#!/usr/bin/env powershell
using namespace System.Collections.Generic

# A convoluted way of loading the right assembly
# On PowerShell Core the assembly is loaded from disk
# Otherwise that fails, and we compile it here
if(!("PowerLine.Prompt" -as [Type])) {
    Add-Type -Path $PowerLineRoot\CSharp\*.cs
}

if(!$PowerLinePrompt) {
    [PowerLine.Prompt]$Script:PowerLinePrompt = @(,@(
        @{ bg = "Cyan";     fg = "White"; text = { $MyInvocation.HistoryId } },
        @{ bg = "DarkBlue"; fg = "White"; text = { Get-SegmentedPath } }
    ))
}