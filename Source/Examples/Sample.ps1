#requires -module @{ModuleName='PowerLine';ModuleVersion='3.3.1'}

$global:prompt = @(
    { "`t" } # On the first line, right-justify
    { New-PowerLineBlock (Get-Elapsed) -ErrorBack DarkRed -ErrorFore Gray74 -Fore Gray74 -Back DodgerBlue4 }
    { Get-Date -Format "T" }
    { "`n" } # Start another line
    { $MyInvocation.HistoryId }
    { "&Gear;" * $NestedPromptLevel }
    { if ($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } }
    { $pwd.Drive.Name }
    { Split-Path $pwd -Leaf }
)

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -Title {
    -join @(
        if (Test-Elevation) { "Administrator: " }
        if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - " }
        Convert-Path $pwd
    )
} -Colors "SteelBlue4", "DodgerBlue3", "DeepSkyBlue2", "SkyBlue2", "SteelBlue2", "LightSkyBlue1"
