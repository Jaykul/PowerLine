function Get-SegmentedPath {
    <#
    .Synopsis
        Gets PowerLine Blocks for each folder in the path
    .Description
        Returns an array of hashtables which can be cast to PowerLine Blocks.
        Includes support for limiting the number of segments or total length of the path, but defaults to 3 segments max
    #>
    [OutputType([PoshCode.Pansies.Text[]])]
    [CmdletBinding(DefaultParameterSetName="Segments")]
    param(
        # The path to segment. Defaults to $pwd
        [Parameter(Position=0)]
        [string]$Path = $pwd,

        # The maximum number of segments. Defaults to 3
        [Parameter(ParameterSetName="Segments")]
        [int]$SegmentLimit = 3,

        # The maximum length. Defaults to 0 (no max)
        [Parameter(ParameterSetName="Length")]
        [int]$LengthLimit = 0,

        # Show the drive name on the front
        [switch]$ShowDrive,

        # The foreground color to use when the last command succeeded
        [PoshCode.Pansies.RgbColor]$ForegroundColor,

        # The background color to use when the last command succeeded
        [PoshCode.Pansies.RgbColor]$BackgroundColor,

        # The foreground color to use when the process is elevated (running as administrator)
        [PoshCode.Pansies.RgbColor]$ElevatedForegroundColor,

        # The background color to use when the process is elevated (running as administrator)
        [PoshCode.Pansies.RgbColor]$ElevatedBackgroundColor,

        # The foreground color to use when the last command failed
        [PoshCode.Pansies.RgbColor]$ErrorForegroundColor,

        # The background color to use when the last command failed
        [PoshCode.Pansies.RgbColor]$ErrorBackgroundColor
    )

    $resolved = Resolve-Path $Path
    $provider = $resolved.Provider
    $drive = $resolved.Drive.Name
    $Path = $resolved.Path

    $buffer = @()

    if ($Path.ToLower().StartsWith($Home.ToLower())) {
        $drive = '~'
        $Path = $Path.Substring($Home.Length)
    } else {
        $Path = Split-Path $Path -NoQualifier
    }
    $Path = $Path.Trim($provider.ItemSeparator)

    # Now we have a drive for the front, and we want $SegmentLimit - 1 pieces from the end
    # $SegmentLimit = $SegmentLimit - 1
    while ($Path) {
        $buffer += if ($Path -eq "~") {
            @{ Object = $Path }
        } else {
            @{ Object = (Split-Path $Path -Leaf).Trim($provider.ItemSeparator) }
        }
        $Path = Split-Path $Path

        if ($PSCmdlet.ParameterSetName -eq 'Segments') {
            if ($Path -and $SegmentLimit -le $buffer.Count) {
                if ($buffer.Count -gt 1) {
                    $buffer[-1] = @{ Object = [char]0x2026 }
                } else {
                    $buffer += @{ Object = [char]0x2026 }
                }
                break
            }
        }

        if ($LengthLimit) {
            $CurrentLength = ($buffer.Object | Measure-Object Length -Sum).Sum + $buffer.Count - 1
            $CurrentLength += if ($Path) { 2 } else { 0 }

            if ($LengthLimit -lt $CurrentLength) {
                if($buffer.Count -gt 1) {
                    $buffer[-1] = @{ Object = [char]0x2026 }
                } else {
                    $buffer += @{ Object = [char]0x2026 }
                }
                break
            }
        }
    }
    if ($ShowDrive -or $SegmentLimit -gt $buffer.Count) {
        $buffer += @{ Object = $Drive }
    }
    [Array]::Reverse($buffer)

    foreach($output in $buffer) {
        # Always set the defaults first, if they're provided
        if($PSBoundParameters.ContainsKey("ForegroundColor")) {
            $output.ForegroundColor = $ForegroundColor
        }
        if($PSBoundParameters.ContainsKey("BackgroundColor")) {
            $output.BackgroundColor = $BackgroundColor
        }

        # If it's elevated, and they passed the elevated color ...
        if(Test-Elevation) {
            if($PSBoundParameters.ContainsKey("ElevatedForegroundColor")) {
                $output.ForegroundColor = $ElevatedForegroundColor
            }
            if($PSBoundParameters.ContainsKey("ElevatedBackgroundColor")) {
                $output.BackgroundColor = $ElevatedBackgroundColor
            }
        }

        # If it failed, and they passed an error color ...
        if(!(Test-Success)) {
            if($PSBoundParameters.ContainsKey("ErrorForegroundColor")) {
                $output.ForegroundColor = $ErrorForegroundColor
            }
            if($PSBoundParameters.ContainsKey("ErrorBackgroundColor")) {
                $output.BackgroundColor = $ErrorBackgroundColor
            }
        }
    }
    [PoshCode.Pansies.Text[]]$buffer
}
