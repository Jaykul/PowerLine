function Test-Success {
    <#
    .Synopsis
        Get a value indicating whether the last command succeeded or not
    #>
    [CmdletBinding()]
    param()

    $script:LastSuccess
}

Export-ModuleMember -Function *-* -Alias *