#!/usr/bin/env powershell
using namespace System.Collections.Generic
using namespace PoshCode.Pansies

$script:PowerLineRoot = $PSScriptRoot

if($PSVersionTable.PSVersion -lt "6.0") {
    Add-Type -Path $PSScriptRoot\lib\net451\PowerLine.dll
} else {
    Add-Type -Path $PSScriptRoot\lib\netstandard1.6\PowerLine.dll
}

if(!$PowerLinePrompt) {
    [PowerLine.Prompt]$Script:PowerLinePrompt = @(,@(
        @{ bg = "Cyan";     fg = "White"; text = { $MyInvocation.HistoryId } },
        @{ bg = "DarkBlue"; fg = "White"; text = { Get-SegmentedPath } }
    ))
}