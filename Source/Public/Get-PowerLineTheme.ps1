function Get-PowerLineTheme {
    <#
        .SYNOPSIS
            Get the themeable PowerLine settings
    #>
    [CmdletBinding()]
    param()

    $Local:Configuration = $Script:PowerLineConfig
    $Configuration.Prompt = [PoshCode.PowerLine.PowerLineBlock[]]$global:Prompt
    $Configuration.Colors = [PoshCode.Pansies.RgbColor[]]$global:Prompt.Colors

    $null = $Configuration.Remove("DefaultAddIndex")

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

    $Result = New-Object PSObject -Property $Configuration
    $Result.PSTypeNames.Insert(0, "PowerLine.Theme")
    $Result
}
