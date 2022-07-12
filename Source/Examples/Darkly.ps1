#requires -Module PowerLine
[CmdletBinding()]param()

Write-Verbose "First we set the default caps"
[PoshCode.TerminalBlock]::DefaultCapsLeftAligned = "","`u{E0B0}"
[PoshCode.TerminalBlock]::DefaultCapsRightAligned ="`u{E0B2}",""

Write-Verbose "Then we set the prompt"
Set-PowerLinePrompt -SetCurrentDirectory -DefaultSeparator "`u{E0B1}","`u{E0B3}" -DefaultCapsLeftAligned "","`u{E0B0}" -DefaultCapsRightAligned "`u{E0B2}","" -Title {
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
    Show-Path -HomeString "&House;" -Separator '' -Background 'Gray100' -Foreground 'Black'
    Show-PoshGitStatus -Background 'Gray23'
    Show-Date -Format "h\:mm" -Prefix "🕒"  -Alignment 'Right' -Background 'Gray23'
    Show-ElapsedTime -Autoformat -Prefix "⏱️"  -Alignment 'Right' -Background 'Gray47'
    Show-HistoryId -Background 'SteelBlue1' -ErrorBackgroundColor '#8B2252'
) -Verbose # -LeftCap "","`u{E0B0}" -RightCap "`u{E0B2}",""
