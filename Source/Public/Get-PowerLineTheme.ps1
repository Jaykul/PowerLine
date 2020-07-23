function Get-PowerLineTheme {
    <#
        .SYNOPSIS
            Get the themeable PowerLine settings
    #>
    [CmdletBinding()]
    param()

    $Local:Configuration = $Script:PowerLineConfig
    $Configuration.Prompt = [ScriptBlock[]]$global:Prompt
    $Configuration.Colors = [PoshCode.Pansies.RgbColor[]]$global:Prompt.Colors

    $null = $Configuration.Remove("DefaultAddIndex")

    $Configuration.PowerLineCharacters = @{
        'ColorSeparator' = [PoshCode.Pansies.Entities]::ExtendedCharacters['ColorSeparator']
        'ReverseColorSeparator' = [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseColorSeparator']
        'Separator' = [PoshCode.Pansies.Entities]::ExtendedCharacters['Separator']
        'ReverseSeparator' = [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseSeparator']
    }

    $Result = New-Object PSObject -Property $Configuration
    $Result.PSTypeNames.Insert(0, "PowerLine.Theme")
    $Result
}
