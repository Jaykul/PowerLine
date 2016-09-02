#requires -module @{ModuleName='PowerLine';ModuleVersion='1.1.0'}, @{ModuleName='PSGit'; ModuleVersion='2.0.2'}
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
        @{ bg = "DarkBlue"; fg = "White"; text = { Split-Path $pwd -leaf } },
        # This requires my PoshCode/PSGit module and the use of the SamplePSGitConfiguration
        @{ bg = "DarkCyan";               text = { $status = ([PowerLine.Line]@(Get-GitStatusPowerline)).ToString(); $status.SubString(0,$status.Length -4) } }
    )

Set-PowerLinePrompt
