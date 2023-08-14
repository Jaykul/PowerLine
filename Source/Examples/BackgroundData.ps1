#requires -module @{ModuleName='PowerLine';ModuleVersion='3.4.0'}
# If this is re-run, clear up the old job:
Get-Job -Name WeatherQuery -EA 0 | Stop-Job -PassThru | Remove-Job
$global:WeatherJob = Start-ThreadJob -Name WeatherQuery {
    while ($true) {
        Invoke-RestMethod "wttr.in?format=%c%t"
        Start-Sleep 300 # This job will update the weather every 5 minutes
    }
}

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -SimpleTransient -Title {
    -join @(
        if (Test-Elevation) { "Admin: " }
        "PS" + $PSVersionTable.PSVersion.Major + " "
        Convert-Path $pwd
    )
} -Prompt @(
    Show-ElapsedTime -Autoformat -BackgroundColor 00688B -ForegroundColor White
    New-TerminalBlock -Newline
    New-TerminalBlock {
        # Consume the output of the job:
        # In this case, I only want the most recent output, so [-1]
        $global:WeatherJob.Output[-1]
    } -BackgroundColor 00BFFF -ForegroundColor Black
    Show-NestedPromptLevel -RepeatCharacter "&Gear;" -Postfix " " -BackgroundColor 473C8B -ForegroundColor White
    Show-Path -HomeString "&House;" -Separator '' -Bg B23AEE -Fg White
    Show-PoshGitStatus -Bg Gray30
    New-TerminalBlock -Spacer
    Show-Date -Bg 7D26CD
    New-TerminalBlock -Newline
    # This is basically Show-HistoryId, but I want to use it as the last part of my prompt, and have PSReadLine updated.
    New-TerminalBlock  {
        # In order for PSReadLine to work properly, it needs the $PromptText set to match the end of my prompt...
        $MyInvocation.HistoryId

        # Because I don't have a "Write-TerminalBlock" I am doing all this by hand:This is
        # Need to draw ">ID>" but the > each have to be FOREGROUND = the BACKGROUND of the previous block
        # AND the color changes depending on whether nestedPrompt rendered or not
        [string]$CS = [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator"]
        $thisBg = $NestedPromptLevel ? $bg:SteelBlue2 : $bg:SkyBlue2
        $previousFg = $NestedPromptLevel ? $fg:SkyBlue2 : $fg:DeepSkyBlue2
        $thisFg = $NestedPromptLevel ? $fg:SteelBlue2 : $fg:SkyBlue2

        Set-PSReadlineOption -PromptText @(
            ($thisBg + $previousFg + $CS + $fg:white + $MyInvocation.HistoryId + $thisFg + $bg:clear + $CS)
            ($bg:Gray44 + $previousFg + $CS + $fg:white + $MyInvocation.HistoryId + $fg:Gray44 + $bg:clear + $CS)
        )
    } -BackgroundColor SteelBlue2 -ForegroundColor Black
)
