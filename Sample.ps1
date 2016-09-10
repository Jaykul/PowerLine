#requires -module @{ModuleName='PowerLine';ModuleVersion='1.1.0'}, @{ModuleName='PSGit'; ModuleVersion='2.0.3'}
using module PowerLine
using namespace PowerLine



$global:PowerLinePrompt = 1,
    # two lines
    @(
        # on the first line, two columns -- the first one is null (empty), the second is right-justified
        $null,
        @(
            @{ bg = "DarkGray"; fg = "Black"; text = { Get-Elapsed } }
            @{ bg = "Gray";     fg = "Black"; text = { Get-Date -f "T" } }
        )
    ),
    (
        @{ bg = "Blue";     fg = "White"; text = { $MyInvocation.HistoryId } },
        @{ bg = "Cyan";     fg = "White"; text = { [PowerLine.Prompt]::Gear * $NestedPromptLevel } },
        @{ bg = "Cyan";     fg = "White"; text = { if($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } } },
        @{ bg = "DarkBlue"; fg = "White"; text = { $pwd.Drive.Name } },
        @{ bg = "DarkBlue"; fg = "White"; text = { Split-Path $pwd -leaf } },
        # This requires my PoshCode/PSGit module and the use of the SamplePSGitConfiguration -- remove the last LeftCap in that.
        @{ bg = "DarkCyan";               text = { Get-GitStatusPowerline } }
    )

Set-PowerLinePrompt -CurrentDirectory -PowerLineFont -Title { "PowerShell - {0} ({1})" -f (Convert-Path $pwd),  $pwd.Provider.Name }
