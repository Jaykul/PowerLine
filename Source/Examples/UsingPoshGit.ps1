$global:GitPromptSettings = New-GitPromptSettings
$global:GitPromptSettings.BeforeStatus = ''
$global:GitPromptSettings.AfterStatus = ''
$global:GitPromptSettings.PathStatusSeparator = ''
$global:GitPromptSettings.BeforeStash.Text = "$(Text '&ReverseSeparator;')"
$global:GitPromptSettings.AfterStash.Text = "$(Text '&Separator;')"


Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -Title {
    -join @(
        if (Test-Elevation) { "Admin: " }
        if ($IsCoreCLR) { "pwsh - " } else { "PowerShell - " }
        Convert-Path $pwd
    )
} -Prompt @(
    New-TerminalBlock -Fg Gray95 -Bg Gray20 -EBg VioletRed4 $MyInvocation.HistoryId
    Show-ElapsedTime -Trim   # only shows the minimum portion of elapsed time necessary
    Show-Date -f "HH:mm" # 24-hour format
    Show-PoshGitStatus
    Show-Path
    New-TerminalBlock -Newline
    New-TerminalBlock -Fg Gray95 -Bg Gray40 "I ${Fg:Green}&hearts;${Fg:Gray95} PS"
)
