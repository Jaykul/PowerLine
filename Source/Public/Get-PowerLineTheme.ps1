function Get-PowerLineTheme {
    <#
        .SYNOPSIS
            Get the themeable PowerLine settings
    #>
    [CmdletBinding()]
    param()

    [PowerLineTheme]$Local:Configuration = $Script:PowerLineConfig

    # We use global:Prompt except when importing and exporting
    $Configuration.Prompt = [PoshCode.TerminalBlock[]]$global:Prompt

    if (Get-Command Get-PSReadLineOption) {
        $PSReadLineOptions = Get-PSReadLineOption
        # PromptText and ContinuationPrompt can have colors in them
        $Configuration.PSReadLinePromptText = $PSReadLineOptions.PromptText
        $Configuration.PSReadLineContinuationPrompt = $PSReadLineOptions.ContinuationPrompt
        # If the ContinuationPrompt has color in it, this is irrelevant, but keep it anyway
        $Configuration.PSReadLineContinuationPromptColor = $PSReadLineOptions.ContinuationPromptColor
    }

    $Configuration
}
