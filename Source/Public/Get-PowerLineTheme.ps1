function Get-PowerLineTheme {
    <#
        .SYNOPSIS
            Get the themeable PowerLine settings
    #>
    [CmdletBinding()]
    param()

    $Local:Configuration = $Script:PowerLineConfig
    $Configuration.Prompt = [PoshCode.TerminalBlock[]]$global:Prompt

    $null = $Configuration.Remove("DefaultAddIndex")

    # Strip common parameters if they're on here (so we can use -Verbose)
    foreach($name in [System.Management.Automation.PSCmdlet]::CommonParameters) {
        $null = $Configuration.Remove($name)
    }

    if (Get-Command Get-PSReadLineOption) {
        $PSReadLineOptions = Get-PSReadLineOption
        # PromptText and ContinuationPrompt can have colors in them
        $Configuration.PSReadLinePromptText = $PSReadLineOptions.PromptText
        $Configuration.PSReadLineContinuationPrompt = $PSReadLineOptions.ContinuationPrompt
        # If the ContinuationPrompt has color in it, this is irrelevant, but keep it anyway
        $Configuration.PSReadLineContinuationPromptColor = $PSReadLineOptions.ContinuationPromptColor
    }

    if ($null -eq $Configuration.Title -or $Configuration.Title.ToString().Trim().Length -eq 0) {
        $null = $Configuration.Remove("Title")
    }

    [PowerLineTheme]$Configuration
}
