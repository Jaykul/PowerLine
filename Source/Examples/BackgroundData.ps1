#requires -module @{ModuleName='PowerLine';ModuleVersion='3.4.0'}

# If this is re-run, clear up the old job, and start a new one
Get-Job -Name WeatherQuery -ErrorAction Ignore | Stop-Job -PassThru | Remove-Job
$null = Start-ThreadJob -Name WeatherQuery {
    while ($true) {
        (Invoke-RestMethod "wttr.in?format=%c%t") -replace " +", " "
        Start-Sleep 300 # This job will update the weather every 5 minutes
    }
}

$ContinuationPromptColor = [RgbColor]"DeepSkyBlue"

Set-PSReadLineOption -ContinuationPrompt █ -Colors @{ ContinuationPrompt = $ContinuationPromptColor.ToVt() }

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -RepeatPrompt LastLine -PSReadlineErrorColor Tomato -Title {
    -join @(
        if (Test-Elevation) { "Admin: " }
        "PS" + $PSVersionTable.PSVersion.Major + " "
        Convert-Path $pwd
    )
} -Prompt @(
    Show-ElapsedTime -Autoformat -Bg White -Fg Black -Prefix "" -Caps '',''
    New-TerminalBlock -Newline

    Show-Date -Format "h\:mm" -Bg DeepSkyBlue -Fg Black
    Show-JobOutput -Name WeatherQuery -Bg DeepSkyBlue3 -Fg Black
    Show-NestedPromptLevel -RepeatCharacter "&Gear;" -Postfix " " -Bg DeepSkyBlue4 -Fg White
    New-TerminalBlock -Spacer

    Show-PoshGitStatus -Bg Gray30
    Show-Path -HomeString "&House;" -Separator '' -Bg SkyBlue4 -Fg White
    New-TerminalBlock -Newline

    # This is basically Show-HistoryId, but I want to use it as the last part of my prompt, and have PSReadLine updated.
    # New-TerminalBlock  {
    #     # In order for PSReadLine to work properly, it needs the $PromptText set to match the end of my prompt...
    #     $ContinuationPromptColor = (Get-PSReadLineOption).ContinuationPromptColor
    #     $fg:Black + ($ContinuationPromptColor -replace "\[3","[4") + "&ColorSeparator;" + $ContinuationPromptColor + $bg:LightSkyBlue + "&ColorSeparator;" + $Fg:Black + $MyInvocation.HistoryId

    # } -BackgroundColor LightSkyBlue -ForegroundColor Black
    # New-TerminalBlock -Spacer
    New-TerminalBlock -Content "&ColorSeparator;" -Background $ContinuationPromptColor -Foreground Black
    Show-HistoryId -Bg LightSkyBlue -Fg Black
)

