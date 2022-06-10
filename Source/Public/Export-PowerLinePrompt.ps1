function Export-PowerLinePrompt {
    [CmdletBinding()]
    param()

    $Local:Configuration = $Script:PowerLineConfig
    $Configuration.Prompt = [PoshCode.PowerLine.PowerLineBlock[]]$global:Prompt
    $Configuration.Colors = [PoshCode.Pansies.RgbColor[]]$global:Prompt.Colors

    if (Get-Command Get-PSReadLineOption) {
        $PSReadLineOptions = Get-PSReadLineOption
        # PromptText and ContinuationPrompt can have colors in them
        $Configuration.PSReadLinePromptText = $PSReadLineOptions.PromptText
        $Configuration.PSReadLineContinuationPrompt = $PSReadLineOptions.ContinuationPrompt
        # If the ContinuationPrompt has color in it, this is irrelevant, but keep it anyway
        $Configuration.PSReadLineContinuationPromptColor = $PSReadLineOptions.ContinuationPromptColor
    }

    $Configuration | Export-Configuration -AsHashtable

}
