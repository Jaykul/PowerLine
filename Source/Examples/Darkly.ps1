#requires -Module Pansies, PowerLine
[CmdletBinding()]param()

Write-Verbose "First we set the default caps"
[PoshCode.TerminalBlock]::DefaultCapsLeftAligned = "","$([char]0xE0B0)"
[PoshCode.TerminalBlock]::DefaultCapsRightAligned = "$([char]0xE0B2)",""

Write-Verbose "Then we set the prompt"
Set-PowerLinePrompt -SetCurrentDirectory -DefaultSeparator "$([char]0xE0B1)","$([char]0xE0B3)" -DefaultCapsLeftAligned "","$([char]0xE0B0)" -DefaultCapsRightAligned "$([char]0xE0B2)","" -Title {
    -join @(
        if (Test-Elevation) {
            "Administrator: "
        }
        if ($IsCoreCLR) {
            "pwsh - "
        } else {
            "Windows PowerShell - "
        }
        Convert-Path $pwd
    )
} -Prompt @(
    Show-HistoryId -Background 'SteelBlue1' -ErrorBackgroundColor '#8B2252'
    Show-Path -HomeString "&House;" -Separator '' -Background 'Gray100' -Foreground 'Black'
    Show-PoshGitStatus -Background 'Gray23'
    Show-Date -Format "h\:mm" -Prefix "🕒"  -Alignment 'Right' -Background 'Gray23'
    Show-ElapsedTime -Autoformat -Prefix "⏱️"  -Alignment 'Right' -Background 'Gray47'
    New-TerminalBlock -DFg 'White' -DBg '#63B8FF' -EFg 'White' -Cap '‍' -Content ''
) -Verbose -PSReadLineContinuationPrompt '▌ ' -PSReadLineContinuationPromptColor '[38;2;99;184;255m' -PSReadLinePromptText '[48;2;99;184;255m[38;2;255;255;255m[49m[38;2;99;184;255m[0m','[48;2;139;34;82m[38;2;255;255;255m[49m[38;2;139;34;82m[0m'
