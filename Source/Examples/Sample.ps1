#requires -module @{ModuleName='PowerLine';ModuleVersion='3.3.1'}

$global:prompt = [PoshCode.TerminalBlock[]]@(
    New-TerminalBlock (Show-ElapsedTime) -ErrorBack DarkRed -ErrorFore Gray74 -Fore Gray74 -Back DodgerBlue4
    Show-Date -Format "T"
    "`n" # Start another line
    Show-HistoryId
    Show-NestedPromptLevel -RepeatCharacter "&Gear;" -Postfix " "
    Show-LocationStack -Prefix "$([char]187)"
    Show-Path -Depth 1 -AsUrl
)

Set-PowerLinePrompt -SetCurrentDirectory -PowerLineFont -Title {
    -join @(
        if (Test-Elevation) { "Administrator: " }
        if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - " }
        Convert-Path $pwd
    )
}
