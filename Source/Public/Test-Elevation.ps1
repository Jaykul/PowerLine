function Test-Elevation {
    <#
    .Synopsis
        Get a value indicating whether the process is elevated (running as administrator or root)
    #>
    [CmdletBinding()]
    param()
    if(-not ($IsLinux -or $IsOSX)) {
        [Security.Principal.WindowsIdentity]::GetCurrent().Owner.IsWellKnown("BuiltInAdministratorsSid")
    } else {
        0 -eq (id -u)
    }
}