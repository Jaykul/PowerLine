#requires -module @{ModuleName='PowerLine';ModuleVersion='3.0.5'}

# You can change the separators by setting properties on [PoshCode.Pansies.Entities]::ExtendedCharacters
# For example, this is an extra long backslash, in Consolas:
[PoshCode.Pansies.Entities]::ExtendedCharacters.Separator = $([char]0x2572)

$global:Prompt = @(
    { "`t" } # On the first line, right-justify
    { Get-Elapsed }
    { Get-Date -f "T" }
    { "`n" } # Start another line
    { $MyInvocation.HistoryId }
    { "&Gear;" * $NestedPromptLevel }
    { if($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } }
    { $pwd.Drive.Name }
    { Split-Path $pwd -leaf }
)

Set-PowerLinePrompt -ResetSeparators -SetCurrentDirectory -Title {
    -join @(if (Test-Elevation) { "Administrator: " }
        if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - "}
        Convert-Path $pwd)
} -Colors DarkGray, Gray, Blue, Cyan, Cyan, DarkBlue, DarkBlue
