function Export-PowerLinePrompt {
    [CmdletBinding()]
    param()

    $Local:Configuration = $Script:PowerLineConfig
    $Configuration.Prompt = [ScriptBlock[]]$global:Prompt
    $Configuration.Colors = [PoshCode.Pansies.RgbColor[]]$global:Prompt.Colors


    @{
        ExtendedCharacters = [PoshCode.Pansies.Entities]::ExtendedCharacters
        EscapeSequences    = [PoshCode.Pansies.Entities]::EscapeSequences
        PowerLineConfig    = $Script:PowerLineConfig
    } | Export-Configuration -AsHashtable

}