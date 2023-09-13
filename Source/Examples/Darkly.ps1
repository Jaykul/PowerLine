#requires -Module Pansies, PowerLine
[CmdletBinding()]param()

Set-PowerLinePrompt -SetCurrentDirectory -DefaultSeparator "$([char]0xE0B1)" -DefaultCaps "","$([char]0xE0B0)" -Title {
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
    Show-Date -Format "h\:mm" -Prefix "🕒" -Background 'Gray23'
    Show-ElapsedTime -Autoformat -Prefix "⏱️" -Background 'Gray47'
) -PSReadLineContinuationPrompt '▌ ' -PSReadLineContinuationPromptColor '[38;2;99;184;255m'
