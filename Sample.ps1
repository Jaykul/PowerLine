#requires -module PowerLine
using module PowerLine
using namespace PowerLine

$global:PowerLinePrompt = 1,
    (
        [PowerLine.BlockCache]::Column, # Right align this line
        @{ bg = "DarkGray"; fg = "White"; text = { Get-Elapsed } },
        @{ bg = "Black";    fg = "White"; text = { Get-Date -f "T" } }
    ),
    (
        @{ bg = "Blue";     fg = "White"; text = { $MyInvocation.HistoryId } },
        @{ bg = "Cyan";     fg = "White"; text = { [PowerLine.Block]::Gear * $NestedPromptLevel } },
        @{ bg = "Cyan";     fg = "White"; text = { if($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } } },
        @{ bg = "DarkBlue"; fg = "White"; text = { $pwd.Drive.Name } },
        @{ bg = "DarkBlue"; fg = "White"; text = { Split-Path $pwd -leaf } }
    )

Set-PowerLinePrompt
