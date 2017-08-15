function New-PromptText {
    <#
        .Synopsis
            Create PoshCode.Pansies.Text with variable background colors
        .Description
            Allows changing the foreground and background colors based on elevation or success.

            Tests elevation fist, and then whether the last command was successful, so if you pass separate colors for each, the Elevated*Color will be used when PowerShell is running as administrator and there is no error. The Error*Color will be used whenever there's an error, whether it's elevated or not.
        .Example
            New-PromptText { Get-Elapsed } -ForegroundColor White -BackgroundColor DarkBlue -ErrorBackground DarkRed -ElevatedForegroundColor Yellow

            This example shows the time elapsed executing the last command in White on a DarkBlue background, but switches the text to yellow if elevated, and the background to red on error.
    #>
    [CmdletBinding(DefaultParameterSetName="Error")]
    [Alias("New-PowerLineBlock")]
    [Alias("New-TextFactory")]
    param(
        # The text, object, or scriptblock to show as output
        [Alias("Text", "Object")]
        [AllowNull()][EmptyStringAsNull()]
        [Parameter(Position=0, ValueFromPipeline, ValueFromPipelineByPropertyName)] # , Mandatory=$true
        $InputObject,

        # The foreground color to use when the last command succeeded
        [Alias("Foreground", "Fg")]
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()][EmptyStringAsNull()]
        [RgbColor]$ForegroundColor,

        # The background color to use when the last command succeeded
        [Alias("Background", "Bg")]
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()][EmptyStringAsNull()]
        [RgbColor]$BackgroundColor,

        # The foreground color to use when the process is elevated (running as administrator)
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()][EmptyStringAsNull()]
        [RgbColor]$ElevatedForegroundColor,

        # The background color to use when the process is elevated (running as administrator)
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()][EmptyStringAsNull()]
        [RgbColor]$ElevatedBackgroundColor,

        # The foreground color to use when the last command failed
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()][EmptyStringAsNull()]
        [RgbColor]$ErrorForegroundColor,

        # The background color to use when the last command failed
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowNull()][EmptyStringAsNull()]
        [RgbColor]$ErrorBackgroundColor
    )
    process {

        $output = [PoshCode.Pansies.Text]@{
            Object = $InputObject
        }
        # Always set the defaults first, if they're provided
        if($PSBoundParameters.ContainsKey("ForegroundColor") -and $ForegroundColor -ne $Null) {
            $output.ForegroundColor = $ForegroundColor
        }
        if($PSBoundParameters.ContainsKey("BackgroundColor") -and $BackgroundColor -ne $Null) {
            $output.BackgroundColor = $BackgroundColor
        }

        # If it's elevated, and they passed the elevated color ...
        if(Test-Elevation) {
            if($PSBoundParameters.ContainsKey("ElevatedForegroundColor") -and $ElevatedForegroundColor -ne $Null) {
                $output.ForegroundColor = $ElevatedForegroundColor
            }
            if($PSBoundParameters.ContainsKey("ElevatedBackgroundColor") -and $ElevatedBackgroundColor -ne $Null) {
                $output.BackgroundColor = $ElevatedBackgroundColor
            }
        }

        # If it failed, and they passed an error color ...
        if(!(Test-Success)) {
            if($PSBoundParameters.ContainsKey("ErrorForegroundColor") -and $ErrorForegroundColor -ne $Null) {
                $output.ForegroundColor = $ErrorForegroundColor
            }
            if($PSBoundParameters.ContainsKey("ErrorBackgroundColor") -and $ErrorBackgroundColor -ne $Null) {
                $output.BackgroundColor = $ErrorBackgroundColor
            }
        }

        $output
    }
}