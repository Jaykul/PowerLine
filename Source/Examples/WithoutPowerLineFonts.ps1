#requires -module @{ModuleName='PowerLine';ModuleVersion='4.0.0'}
# These two lines are, strictly speaking, redundant -- but because the TerminalBlock commands build TerminalBlocks with the default caps BEFORE Set-PowerLinePrompt changes the default caps, we need to set them first
[PoshCode.TerminalBlock]::DefaultCaps = "", " "
[PoshCode.TerminalBlock]::DefaultSeparator = "/"

Set-PowerLinePrompt -SetCurrentDirectory -NoBackground -Title {
    -join @(if (Test-Elevation) { "Administrator: " }
        if ($IsCoreCLR) { "pwsh - " } else { "Windows PowerShell - "}
        Convert-Path $pwd)
} -Prompt @(
    Show-HistoryId -Fg VioletRed1 -Postfix ""
    Show-ElapsedTime -Autoformat -Fg SlateBlue -Prefix ""
    Show-NestedPromptLevel -RepeatCharacter "&Gear;" -Postfix " " -Fg DarkGoldenrod
    Show-Path -GitDir -Postfix "${Fg:White}>" -Fg DarkGoldenrod3
)
