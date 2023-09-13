#requires -module @{ModuleName='PowerLine';ModuleVersion='4.0.0'}
param(
    $StartColor = "DeepSkyBlue",
    $EndColor = "SlateBlue4"
)
$Colors = Get-Gradient $StartColor $EndColor -steps 8 | Get-Complement -Passthru -BlackAndWhite

# If this is re-run, clear up the old job, and start a new one
Get-Job -Name WeatherQuery -ErrorAction Ignore | Stop-Job -PassThru | Remove-Job
$null = Start-ThreadJob -Name WeatherQuery {
    while ($true) {
        (Invoke-RestMethod "wttr.in?format=%c%t") -replace " +", " "
        Start-Sleep 300 # This job will update the weather every 5 minutes
    }
}

$ContinuationPromptColor = $Colors[0]

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -RepeatPrompt LastLine -PSReadlineErrorColor Tomato -PSReadLineContinuationPrompt █ -PSReadLineContinuationPromptColor $Colors[0] -Title {
    -join @(
        if (Test-Elevation) { "Admin: " }
        "PS" + $PSVersionTable.PSVersion.Major + " "
        Convert-Path $pwd
    )
} -Prompt @(
    Show-ElapsedTime -Autoformat -Bg White -Fg Black -Prefix "" -Caps '',''
    New-TerminalBlock -Newline

    Show-Date -Format "h\:mm" -Bg $Colors[2] -Fg $Colors[3]
    Show-JobOutput -Name WeatherQuery -Bg $Colors[4] -Fg $Colors[5]
    Show-LocationStack
    Show-NestedPromptLevel -RepeatCharacter "&Gear;" -Postfix " " -Bg $Colors[6] -Fg $Colors[7]
    New-TerminalBlock -Spacer -Bg $Colors[6]

    Show-PoshGitStatus -Bg $Colors[8]
    Show-Path -HomeString "&House;" -Separator '' -Bg $Colors[10] -Fg $Colors[11]
    New-TerminalBlock -Newline

    # This is literally just a decorative chevron to match the continuation prompt
    New-TerminalBlock -Content "&ColorSeparator;" -Background $Colors[0] -Foreground $colors[13]
    Show-HistoryId -Bg $Colors[14] -Fg $Colors[15]
)

