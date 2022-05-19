function Test-Elevation {
    <#
    .Synopsis
        Get a value indicating whether the process is elevated (running as administrator or root)
    #>
    [CmdletBinding()]
    param()
    [PoshCode.PowerLine.State]::Elevated
}
