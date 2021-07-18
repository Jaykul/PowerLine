#requires -module @{ModuleName='PowerLine';ModuleVersion='3.0.5'}

# You can change the separators by setting properties on [PoshCode.Pansies.Entities]::ExtendedCharacters
# For example, in the Consolas font, this is an extra long backslash:
[PoshCode.Pansies.Entities]::ExtendedCharacters.Separator = $([char]0x2572)

# Now that PSReadLine has been fixed, we can have right-aligned stuff on our prompt
$global:Prompt = @(
    { $MyInvocation.HistoryId }
    { "&Gear;" * $NestedPromptLevel }
    { $pwd.Drive.Name }
    { Split-Path $pwd -leaf }

    { "`t" } # Add a few right-aligned blocks
    { Get-Elapsed }
    { Get-Date -Format "T" }
)

Set-PowerLinePrompt -ResetSeparators -SetCurrentDirectory -Title {
    -join @(if (Test-Elevation) { "Administrator: " }
        if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - "}
        Convert-Path $pwd)
} -Colors "SteelBlue4", "DodgerBlue3", "DeepSkyBlue2", "SkyBlue2", "SteelBlue2", "LightSkyBlue1"
