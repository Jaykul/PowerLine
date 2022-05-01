#requires -module @{ModuleName='PowerLine';ModuleVersion='3.4.0'}

Get-Job -Name WeatherQuery -EA 0| Stop-Job -PassThru | Remove-Job
$global:WeatherJob = Start-ThreadJob -Name WeatherQuery {
    while ($true) {
        Invoke-RestMethod "wttr.in?format=%c%t"
        Start-Sleep 300 # This job will update the weather every 5 minutes
    }
}

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -Title {
    -join @(
        if (Test-Elevation) { "Admin: " }
        "PS" + $PSVersionTable.PSVersion.Major + " "
        Convert-Path $pwd
    )
} -Colors @(
    "SteelBlue4", "DodgerBlue3", "DeepSkyBlue2", "SkyBlue2", "SteelBlue2", "LightSkyBlue1"
) -Prompt @(
    # Consume the output of the job:
    # In this case, I only want the most recent output, so [-1]
    { $WeatherJob.Output[-1] }
    { "&Gear;" * $NestedPromptLevel }
    { $pwd.Drive.Name }
    { Split-Path $pwd -Leaf }
    {
        # In order for PSReadLine to work properly, it needs the $PromptText set to match the end of my prompt...
        $MyInvocation.HistoryId

        # Because I don't have a "Write-PowerLineBlock" I am doing all this by hand:
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
    }
    { "`t" }
    { Get-Elapsed -Trim }
    { Get-Date -Format "T" }
)
