#requires -module @{ModuleName='PowerLine';ModuleVersion='4.0.0'}
param(
    $LineOneStart = "DeepSkyBlue",
    $LineOneEnd = "SlateBlue4",
    $LineTwoStart = "Magenta1",
    $LineTwoEnd = "SlateBlue4"
)
$LineOne = Get-Gradient $LineOneStart $LineOneEnd -steps 8 | Get-Complement -Passthru -BlackAndWhite
$LineTwo = Get-Gradient $LineTwoStart $LineTwoEnd -steps 8 | Get-Complement -Passthru -BlackAndWhite


Set-PowerLinePrompt -SetCurrentDirectory -AutoRefresh RecalculateLastLine -PowerLineFont -Title {
    -join @(
        if (Test-Elevation) { "Administrator: " }
        if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - " }
        Convert-Path $pwd
    )
} -Prompt @(
    New-TerminalBlock -Content { Update-ZLocation $pwd }
    Show-ElapsedTime -Autoformat -Prefix "&hourglassdone;" -Bg DeepSkyBlue -Fg Black -Caps '', ''
    New-TerminalBlock -NewLine
    New-TerminalBlock -NewLine

    Show-NestedPromptLevel -BackgroundColor Magenta1 -RepeatCharacter "&gear;" -Postfix " "
    Show-HistoryId -Bg Magenta4 -Fg White
    New-TerminalBlock -Spacer

    Show-KubeContext -Bg DarkOrchid2 -Fg White
    Show-AzureContext -Bg Purple3 -Prefix "&nf-mdi-azure; " -Fg White
    Show-Path -HomeString "&House;" -Separator '' -Bg SlateBlue4 -Fg White -Depth 3
    New-TerminalBlock -Spacer

    Show-PoshGitStatus -Bg Gray30
    New-TerminalBlock -NewLine
    Show-Date -Format "h\:mm" -Bg DeepSkyBlue4 -Fg White
)
