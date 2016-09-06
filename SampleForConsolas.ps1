#requires -module @{ModuleName='PowerLine';ModuleVersion='1.1.0'}
using module PowerLine
using namespace PowerLine

# Replace the Caps and Separators with characters that exist in Consolas and Courier New
[PowerLine.Block]::LeftCap = [char]0x258C
[PowerLine.Block]::RightCap = [char]0x2590
[PowerLine.Block]::LeftSep = [char]0x25BA
[PowerLine.Block]::RightSep = [char]0x25C4

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
        @{ bg = "DarkBlue"; fg = "White"; text = { Split-Path $pwd -leaf } },
    )

Set-PowerLinePrompt -Title -CurrentDirectory
