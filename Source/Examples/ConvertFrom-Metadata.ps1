ConvertFrom-Metadata @'
(PowerLineTheme @{
    DefaultCaps = '', ''
    DefaultSeparator = ''
    Prompt = @(
        Show-ElapsedTime -Autoformat -Prefix "⏱️" -Background 'Gray47' -Caps '', ''
        Show-Date -Format "h\:mm" -Prefix "🕒" -Background 'Gray23'
        New-TerminalBlock -Spacer
        New-TerminalBlock -Newline -Caps '',''

        # New-TerminalBlock " " -Caps '',''

        # New-TerminalBlock "`u{200D}" -Caps '',''

        Show-HistoryId -DBg 'SteelBlue1' -EBg '#8B2252' -Fg 'White' -EFg 'White' -Caps '',''
        Show-Path -HomeString "&House;" -Separator '' -Background 'Gray100' -Foreground 'Black'
        # New-TerminalBlock -DFg 'White' -DBg '#63B8FF' -EFg 'White' -Cap '‍' -Content ''
    )
    PSReadLineContinuationPrompt = '▌ '
    PSReadLineContinuationPromptColor = '[38;2;99;184;255m'
    PSReadLinePromptText = '[48;2;99;184;255m[38;2;255;255;255m[49m[38;2;99;184;255m[0m','[48;2;139;34;82m[38;2;255;255;255m[49m[38;2;139;34;82m[0m'
    HideErrors = $false
    SimpleTransient = $false
    NoCache = $false
    SetCurrentDirectory = $false
})
'@ | Set-PowerLinePrompt
