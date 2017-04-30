function Add-PowerLineBlock {
    <#
        .Synopsis
            Insert a PowerLine block into the $PowerLinePrompt
        .Description
            Allows changing the foreground and background colors based on elevation or success.

            Tests elevation fist, and then whether the last command was successful, so if you pass separate colors for each, the Elevated*Color will be used when PowerShell is running as administrator and there is no error. The Error*Color will be used whenever there's an error, whether it's elevated or not.
        .Example
            New-PowerLineBlock (Get-Elapsed) -ForegroundColor White -BackgroundColor DarkBlue -ErrorBackground DarkRed -ElevatedForegroundColor Yellow

            This example shows the time elapsed executing the last command in White on a DarkBlue background, but switches the text to yellow if elevated, and the background to red on error.
    #>
    [CmdletBinding(DefaultParameterSetName="Error")]
    param(
        # The text, object, or scriptblock to show as output
        [Parameter(Position=0, Mandatory=$true)]
        [Alias("Text")]
        $Object,

        # The foreground color to use when the last command succeeded
        [RgbColor]$ForegroundColor,

        # The background color to use when the last command succeeded
        [RgbColor]$BackgroundColor,

        # The foreground color to use when the process is elevated (running as administrator)
        [RgbColor]$ElevatedForegroundColor,

        # The background color to use when the process is elevated (running as administrator)
        [RgbColor]$ElevatedBackgroundColor,

        # The foreground color to use when the last command failed
        [RgbColor]$ErrorForegroundColor,

        # The background color to use when the last command failed
        [RgbColor]$ErrorBackgroundColor,

        # The line to insert the block to. Index starts at 0.
        # If the number is out of range, a new line will be added to the prompt
        # Defaults to -1 (the last line).
        [int]$Line = -1,

        # The column to insert the block to (Left or Right aligned).
        # Defaults to the Left column
        [ValidateSet("Left","Right")]
        [string]$Column = "Left",

        # The position in column to insert the block to. The left-aligned column is 0, the right-aligned column is 1.
        # Defaults to append at the end.
        [ValidateSet(-1,0,1)]
        [int]$InsertAt = -1
    )
    $Parameters = @{} + $PSBoundParameters
    # Remove the position parameters:
    $null = $Parameters.Remove("Line")
    $null = $Parameters.Remove("Column")
    $null = $Parameters.Remove("InsertAt")

    $blocks = [PowerLine.TextFactory]$Parameters

    if($Line -gt ($global:PowerLinePrompt.Lines.Count - 1)) {
        $null = $global:PowerLinePrompt.Add((New-Object PowerLine.Line))
        $Line = -1
    }

    [int]$Column = if($Column -eq "Left") { 0 } else { 1 }
    if($Column -gt ($global:PowerLinePrompt.Lines[$Line].Columns.Count - 1)) {
        $null = $global:PowerLinePrompt.Lines[$Line].Columns.Add((New-Object PowerLine.Column))
    }

    if($InsertAt -lt 0 -or $InsertAt -gt $global:PowerLinePrompt.Lines[$Line].Columns[$Column].Blocks.Count) {
        $global:PowerLinePrompt.Lines[$Line].Columns[$Column].Blocks.Add($blocks)
    } else {
        $global:PowerLinePrompt.Lines[$Line].Columns[$Column].Blocks.Insert($InsertAt,$blocks)
    }
}