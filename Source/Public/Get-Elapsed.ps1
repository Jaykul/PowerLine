function Get-Elapsed {
    <#
    .Synopsis
        Get the time span elapsed during the execution of command (by default the previous command)
    .Description
        Calls Get-History to return a single command and returns the difference between the Start and End execution time
    #>
    [OutputType([string])]
    [CmdletBinding(DefaultParameterSetName = "SimpleFormat")]
    param(
        # The command ID to get the execution time for (defaults to the previous command)
        [Parameter()]
        [int]$Id,

        # A Timespan format pattern such as "{0:ss\.fff}"
        [Parameter(ParameterSetName = 'SimpleFormat')]
        [string]$Format = "{0:d\d\ h\:mm\:ss\.fff}",

        # Automatically use different formats depending on the duration
        [Parameter(Mandatory, ParameterSetName = 'AutoFormat')]
        [switch]$Trim
    )
    $null = $PSBoundParameters.Remove("Format")
    $null = $PSBoundParameters.Remove("Trim")
    $LastCommand = Get-History -Count 1 @PSBoundParameters
    if(!$LastCommand) { return "" }
    $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
    $Result = $Format -f $Duration
    if ($Trim) {
        if ($Duration.Days -ne 0) {
            "{0:d\d\ h\:mm}" -f $Duration
        } elseif ($Duration.Hours -ne 0) {
            "{0:h\:mm\:ss}" -f $Duration
        } elseif ($Duration.Minutes -ne 0) {
            "{0:m\:ss\.fff}" -f $Duration
        } elseif ($Duration.Seconds -ne 0) {
            "{0:s\.fff\s}" -f $Duration
        } elseif ($Duration.Milliseconds -gt 10) {
            ("{0:fff\m\s}" -f $Duration).Trim("0")
        } else {
            ("{0:ffffff\μ\s}" -f $Duration).Trim("0")
        }
    } else {
        $Result
    }
}
