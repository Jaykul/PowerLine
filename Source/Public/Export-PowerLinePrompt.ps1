function Export-PowerLinePrompt {
    [CmdletBinding()]
    param()

    Get-PowerLineTheme | Export-Configuration -AsHashtable

}
