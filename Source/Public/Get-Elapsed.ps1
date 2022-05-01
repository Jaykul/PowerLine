function Get-Elapsed {
    <#
    .Synopsis
        Get the time span elapsed during the execution of command (by default the previous command)
    .Description
        Calls Get-History to return a single command and returns the difference between the Start and End execution time
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The command ID to get the execution time for (defaults to the previous command)
        [Parameter()]
        [int]$Id,

        # A Timespan format pattern such as "{0:ss\.ffff}"
        [Parameter()]
        [string]$Format = "{0:d\d\ h\:mm\:ss\.ffff}",

        # If set trim leading zeros and separators off to make the string as short as possible
        [switch]$Trim
    )
    $null = $PSBoundParameters.Remove("Format")
    $null = $PSBoundParameters.Remove("Trim")
    $LastCommand = Get-History -Count 1 @PSBoundParameters
    if(!$LastCommand) { return "" }
    $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
    $Result = $Format -f $Duration
    if ($Trim) {
        $Short = $Result.Trim("0:d .")
        if ($Short.Length -lt 5) {
            $Short + "ms"
        } elseif ($Short.Length -lt 8) {
            $Short + "s"
        } else {
            $Short
        }
    } else {
        $Result
    }
}
