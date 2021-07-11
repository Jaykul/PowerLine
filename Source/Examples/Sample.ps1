#requires -module @{ModuleName='PowerLine';ModuleVersion='3.0.5'}, @{ModuleName='PSGit'; ModuleVersion='2.0.4'}

$global:prompt = @(
    { "`t" } # On the first line, right-justify
    { New-PowerLineBlock (Get-Elapsed) -ErrorBackgroundColor DarkRed -ErrorForegroundColor White -ForegroundColor Black -BackgroundColor DarkGray }
    { Get-Date -format "T" }
    { "`n" } # Start another line
    { $MyInvocation.HistoryId }
    { "&Gear;" * $NestedPromptLevel }
    { if($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } }
    { $pwd.Drive.Name }
    { Split-Path $pwd -leaf }
    # This requires my PoshCode/PSGit module and the use of the SamplePSGitConfiguration
    { Get-GitStatusPowerline }
)

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -Title {
    -join @(if (Test-Elevation) { "Administrator: " }
        if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - "}
        Convert-Path $pwd)
} -Colors "White", "Gray", "Blue", "Cyan", "Cyan", "DarkBlue", "DarkBlue", "DarkCyan"
