PowerLineTheme @{
    DefaultCapsLeftAligned = '', ''
    DefaultCapsRightAligned = '', ''
    DefaultSeparator = '', ''
    Prompt = @(
        Show-HistoryId -DBg 'SteelBlue1' -EBg '#8B2252' -Fg 'White' -EFg 'White'
        Show-Path -HomeString "&House;" -Separator '' -Background 'Gray100' -Foreground 'Black'
        Show-Date -Format "h\:mm" -Prefix "🕒"  -Alignment 'Right' -Background 'Gray23'
        Show-ElapsedTime -Autoformat -Prefix "⏱️"  -Alignment 'Right' -Background 'Gray47'
        New-TerminalBlock -DFg 'White' -DBg '#63B8FF' -EFg 'White' -Content ''
    )
    PSReadLineContinuationPrompt = '█ '
    PSReadLineContinuationPromptColor = '[38;2;99;184;255m'
    PSReadLinePromptText = '[48;2;99;184;255m[38;2;255;255;255m[49m[38;2;99;184;255m[0m','[48;2;139;34;82m[38;2;255;255;255m[49m[38;2;139;34;82m[0m'
    SetCurrentDirectory = $false
}
