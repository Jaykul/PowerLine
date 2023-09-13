#requires -module @{ModuleName='PowerLine';ModuleVersion='4.0.0'}
param(
    $LineOneStart = "DeepSkyBlue",
    $LineOneEnd = "SlateBlue4",
    $LineTwoStart = "Magenta1",
    $LineTwoEnd = "SlateBlue4"
)
$LineOne = Get-Gradient $LineOneStart $LineOneEnd -steps 8 | Get-Complement -Passthru -BlackAndWhite
$LineTwo = Get-Gradient $LineTwoStart $LineTwoEnd -steps 8 | Get-Complement -Passthru -BlackAndWhite


Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -Title {
    -join @(
        if (Test-Elevation) { "Administrator: " }
        if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - " }
        Convert-Path $pwd
    )
} -Prompt @(
    New-TerminalBlock -Separator ' ' -Content { Update-ZLocation $pwd }
    Show-ElapsedTime -Autoformat -Prefix "&hourglassdone;" -Bg $LineOne[2] -Fg $LineOne[3]
    Show-Date -Format "h\:mm" -Prefix "🕒" -Bg $LineOne[4] -Fg $LineOne[5]
    New-TerminalBlock -Spacer

    Show-KubeContext -Bg $LineOne[8] -Fg $LineOne[9]
    Show-AzureContext -Prefix "&nf-mdi-azure; " -Bg $LineOne[10] -Fg $LineOne[11]
    Show-Path -HomeString "&House;" -Separator '' -Depth 3 -Bg $LineOne[12] -Fg $LineOne[13]
    New-TerminalBlock -Spacer
    Show-PoshGitStatus -Bg $LineOne[14] -Fg $LineOne[15]
    New-TerminalBlock -NewLine

    # This is literally just a decorative chevron to match the continuation prompt
    New-TerminalBlock -Content "&ColorSeparator;" -Bg $LineTwo[-2] -Fg $LineTwo[0]
    Show-LocationStack -Bg $LineTwo[2] -Fg $LineTwo[3]
    Show-NestedPromptLevel -RepeatCharacter "&gear;" -Postfix " " -Bg $LineTwo[4] -Fg $LineTwo[5]
    Show-HistoryId -Bg $LineTwo[6] -Fg $LineTwo[7]
)
