#set-alias New-PowerLineBlock New-TextFactory
function New-TextFactory {
    <#
        .Synopsis
            Create PowerLine.TextFactory with variable background colors
        .Description
            Allows changing the foreground and background colors based on elevation or success.

            Tests elevation fist, and then whether the last command was successful, so if you pass separate colors for each, the Elevated*Color will be used when PowerShell is running as administrator and there is no error. The Error*Color will be used whenever there's an error, whether it's elevated or not.
        .Example
            New-TextFactory (Get-Elapsed) -ForegroundColor White -BackgroundColor DarkBlue -ErrorBackground DarkRed -ElevatedForegroundColor Yellow

            This example shows the time elapsed executing the last command in White on a DarkBlue background, but switches the text to yellow if elevated, and the background to red on error.
    #>
    [CmdletBinding(DefaultParameterSetName="Error")]
    param(
        # The text, object, or scriptblock to show as output
        [Alias("Text")]
        [AllowNull()][AllowEmptyString()]
        [Parameter(Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)] # , Mandatory=$true
        $Object,

        # The foreground color to use when the last command succeeded
        [Alias("Foreground", "Fg")]
        [Parameter(ValueFromPipelineByPropertyName)]
        [PoshCode.Pansies.Color]$ForegroundColor,

        # The background color to use when the last command succeeded
        [Alias("Background", "Bg")]
        [Parameter(ValueFromPipelineByPropertyName)]
        [PoshCode.Pansies.Color]$BackgroundColor,

        # The foreground color to use when the process is elevated (running as administrator)
        [Parameter(ValueFromPipelineByPropertyName)]
        [PoshCode.Pansies.Color]$ElevatedForegroundColor,

        # The background color to use when the process is elevated (running as administrator)
        [Parameter(ValueFromPipelineByPropertyName)]
        [PoshCode.Pansies.Color]$ElevatedBackgroundColor,

        # The foreground color to use when the last command failed
        [Parameter(ValueFromPipelineByPropertyName)]
        [PoshCode.Pansies.Color]$ErrorForegroundColor,

        # The background color to use when the last command failed
        [Parameter(ValueFromPipelineByPropertyName)]
        [PoshCode.Pansies.Color]$ErrorBackgroundColor
    )
    $output = [PowerLine.TextFactory]@{
        Object = $Object
    }
    # Always set the defaults first, if they're provided
    if($PSBoundParameters.ContainsKey("ForegroundColor")) {
        $output.DefaultForegroundColor = $ForegroundColor
    }
    if($PSBoundParameters.ContainsKey("BackgroundColor")) {
        $output.DefaultBackgroundColor = $BackgroundColor
    }

    # If it's elevated, and they passed the elevated color ...
    if(Test-Elevation) {
        if($PSBoundParameters.ContainsKey("ElevatedForegroundColor")) {
            $output.DefaultForegroundColor = $ElevatedForegroundColor
        }
        if($PSBoundParameters.ContainsKey("ElevatedBackgroundColor")) {
            $output.DefaultBackgroundColor = $ElevatedBackgroundColor
        }
    }

    # If it failed, and they passed an error color ...
    if(!(Test-Success)) {
        if($PSBoundParameters.ContainsKey("ErrorForegroundColor")) {
            $output.DefaultForegroundColor = $ErrorForegroundColor
        }
        if($PSBoundParameters.ContainsKey("ErrorBackgroundColor")) {
            $output.DefaultBackgroundColor = $ErrorBackgroundColor
        }
    }

    $output.GetText()
}