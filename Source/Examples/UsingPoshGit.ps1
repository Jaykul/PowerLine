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
    { New-TerminalBlock -Fg Gray95 -Bg Gray20 -EBg VioletRed4 $MyInvocation.HistoryId }
    { Show-ElapsedTime -Trim }   # only shows the minimum portion of elapsed time necessary
    { Get-Date -f "HH:mm" } # 24-hour format
    { Write-VcsStatus }
    { Get-SegmentedPath }
    { "`n" }
    { New-TerminalBlock -Fg Gray95 -Bg Gray40 "I ${Fg:Green}&hearts;${Fg:Gray95} PS" }
) -PSReadLinePromptText @(
    # Let PSReadLine use a red heart to let us know about syntax errors
    New-TerminalBlock -Fg Gray95 -Bg Gray40 "I ${Fg:Green}&hearts;${Fg:Gray95} PS${fg:Gray40}${bg:Clear}&ColorSeparator;"
    New-TerminalBlock -Fg Gray95 -Bg Gray40 "I ${Fg:Red}&hearts;${Fg:Gray95} PS${fg:Gray40}${bg:Clear}&ColorSeparator;"
) -Colors Gray54, Gray26
