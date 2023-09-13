ConvertFrom-Metadata @'
(PSObject @{
    DefaultCaps = '', ''
    DefaultSeparator = ''
    Prompt = @(
        Show-ElapsedTime -Autoformat -Prefix "⏱️" -Background 'Gray47' -Caps '', ''
        Show-Date -Format "h\:mm" -Prefix "🕒" -Background 'Gray23'
        New-TerminalBlock -Newline

        Show-HistoryId -DBg 'SteelBlue1' -EBg '#8B2252' -Fg 'White' -EFg 'White' -Caps '',''
        Show-Path -HomeString "&House;" -Separator '' -Background 'Gray100' -Foreground 'Black'
    )
    PSReadLineContinuationPrompt = '▌ '
    PSReadLineContinuationPromptColor = '[38;2;99;184;255m'
    HideErrors = $false
    RepeatPrompt = 'LastLine'
    SetCurrentDirectory = $false
})
'@ | Set-PowerLinePrompt
