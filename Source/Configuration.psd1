PSObject @{
    DefaultCaps = '', ''
    DefaultSeparator = ''
    Prompt = @(
        Show-HistoryId -DBg 'SteelBlue1' -EBg '#8B2252' -Fg 'White' -EFg 'White'
        Show-Path -HomeString "&House;" -Separator '' -Background 'Gray100' -Foreground 'Black'
        Show-Date -Format "h\:mm" -Prefix "🕒" -Background 'Gray23'
        Show-ElapsedTime -Autoformat -Prefix "⏱️" -Background 'Gray47'
        New-TerminalBlock -DFg 'White' -DBg '#63B8FF' -EFg 'White' -Content ''
    )
    PSReadLineContinuationPrompt = '█ '
    PSReadLineContinuationPromptColor = '[38;2;99;184;255m'
    PSReadLineErrorColor = 'Tomato'
    SetCurrentDirectory = $false
}
