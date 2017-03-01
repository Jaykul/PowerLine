function Test-Elevation {
    <#
    .Synopsis
        Get a value indicating whether the process is elevated (running as administrator)
    #>
    [CmdletBinding()]
    param()

    [Security.Principal.WindowsIdentity]::GetCurrent().Owner -eq 'S-1-5-32-544'
}