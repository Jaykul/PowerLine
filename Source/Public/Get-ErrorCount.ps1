function Get-ErrorCount {
    <#
    .Synopsis
        Get a count of new errors from previous command
    .Description
        Detects new errors generated by previous command based on tracking last seen count of errors.
    #>
    [CmdletBinding()]
    param()

    $global:Error.Count - $script:LastErrorCount
    $script:LastErrorCount = $global:Error.Count
}
