#requires -module @{ModuleName='PowerLine';ModuleVersion='1.1.0'}
using module PowerLine
using namespace PowerLine

# Replace the Caps and Separators with characters that exist in Consolas and Courier New
[PowerLine.Prompt]::ColorSeparator = [char]0x258C
[PowerLine.Prompt]::ReverseColorSeparator = [char]0x2590
[PowerLine.Prompt]::Separator = [char]0x25BA
[PowerLine.Prompt]::ReverseSeparator = [char]0x25C4

$global:PowerLinePrompt = 1,
    @(
        # on the first line, two columns -- the first one is null (empty), the second is right-justified
        $null,
        @(
            @{ bg = "DarkGray"; fg = "Black"; text = { Get-Elapsed } }
            @{ bg = "Gray";     fg = "Black"; text = { Get-Date -f "T" } }
        )
    ),
    @(
        @{ bg = "Blue";     fg = "White"; text = { $MyInvocation.HistoryId } }
        @{ bg = "Cyan";     fg = "White"; text = { [PowerLine.Prompt]::Gear * $NestedPromptLevel } }
        @{ bg = "Cyan";     fg = "White"; text = { if($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } } }
        @{ bg = "DarkBlue"; fg = "White"; text = { $pwd.Drive.Name } }
        @{ bg = "DarkBlue"; fg = "White"; text = { Split-Path $pwd -leaf } }
    )

Set-PowerLinePrompt -ResetSeparators -CurrentDirectory -Title { "PowerShell - {0} ({1})" -f (Convert-Path $pwd),  $pwd.Provider.Name }
