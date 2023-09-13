#requires -module @{ModuleName='PowerLine';ModuleVersion='4.0.0'}
param(
    $StartColor = "Purple4",
    $EndColor = "Violet"
)
$Color = Get-Gradient $StartColor $EndColor -steps 5 | Get-Complement -Passthru -BlackAndWhite

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
    New-TerminalBlock -Bg $Color[0] -Fg $Color[1] -EBg VioletRed4 $MyInvocation.HistoryId
    Show-ElapsedTime -Autoformat -Bg $Color[2] -Fg $Color[3] -Prefix "&stopwatch; " # only shows the minimum portion of elapsed time necessary
    Show-Date -Format "h:mm" -Bg $Color[4] -Fg $Color[5] # 24-hour format
    Show-PoshGitStatus -Bg "Gray20"
    Show-Path -Bg $Color[6] -Fg $Color[7]
    New-TerminalBlock -Newline
    New-TerminalBlock -Bg $Color[8] -Fg $Color[9] "I ${Fg:VioletRed4}&hearts;$($Color[9].ToVt()) PS"
)
