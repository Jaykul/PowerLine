function Get-SegmentedPath {
    <#
    .Synopsis
        Gets PowerLine Blocks for each folder in the path
    .Description
        Returns an array of hashtables which can be cast to PowerLine Blocks.
        Includes support for limiting the number of segments or total length of the path, but defaults to 3 segments max
    #>
    [CmdletBinding(DefaultParameterSetName="Segments")]
    param(
        # The path to segment. Defaults to $pwd
        [Parameter(Position=0)]
        [string]
        $Path = $pwd,

        # The maximum number of segments. Defaults to 3
        [Parameter(ParameterSetName="Segments")]
        $SegmentLimit = 3,

        # The maximum length. Defaults to 0 (no max)
        [Parameter(ParameterSetName="Length")]
        [int]
        $LengthLimit = 0,

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

    # Define reusable constants.
    $directorySeparatorChar = [System.IO.Path]::DirectorySeparatorChar
    $ellipses = data { [char]0x2026 }
    $resolvedHome = (Resolve-Path -LiteralPath $Home).Path
    Write-Debug "`$directorySeparatorChar = '$directorySeparatorChar'"
    Write-Debug "`$ellipses = '$ellipses'"
    Write-Debug "`$resolvedHome = '$resolvedHome'"

    # Resolve path.
    $resolved = (Resolve-Path -LiteralPath $Path).Path
    Write-Debug "`$resolved = '$resolved'"

    # Split path into qualifier (or pseudo-qualifier) and no qualifier parts.
    if($resolved.ToLower().StartsWith($resolvedHome.ToLower())) {
        $qualifier = '~'
        $noQualifier = $resolved.Substring($resolvedHome.Length)
    } else {
        $qualifier = Split-Path $resolved -Qualifier
        $noQualifier = Split-Path $resolved -NoQualifier
    }
    Write-Debug "`$qualifier = '$qualifier'"
    Write-Debug "`$noQualifier = '$noQualifier'"

    # Ensure that the path neither starts nor ends with the directory separator character. This is necessary in
    # order to avoid a reundant empty leading and/or trailing path segment when splitting the path into segments.
    $trimmed = $noQualifier
    if($trimmed.StartsWith($directorySeparatorChar)) {
        $trimmed = $trimmed.Substring(1)
    }
    if($trimmed.EndsWith($directorySeparatorChar)) {
        $trimmed = $trimmed.Substring(0, $trimmed.Length - 1)
    }
    Write-Debug "`$trimmed = '$trimmed'"

    # Split path into segments.
    $split = if($trimmed) { $trimmed.Split($directorySeparatorChar) } else { @() }
    Write-Debug "`$split = @( $($split.ForEach{ "'$_'" } -join ', ') )"

    #region Apply segment count and length limits.
    $limited = @($qualifier) + $split
    $prependEllipses = $false

    function Test-SegmentLimit ([string[]] $Segments, [bool] $PrependEllipses) {
        -not (
            ($SegmentLimit -gt 0) -and  # There is a segment limit.
            ($SegmentLimit -lt (  # The segment limit is exceeded.
                $Segments.Count +
                $(if ($PrependEllipses) { 1 } else { 0 })
            ))
        )
    }
    while (($limited.Count -gt 1) -and -not (Test-SegmentLimit $limited $prependEllipses)) {
        $limited = $limited | Select-Object -Skip 1
        $prependEllipses = $true
    }

    function Test-LengthLimit ([string[]] $Segments, [bool] $PrependEllipses) {
        -not (
            ($LengthLimit -gt 0) -and  # There is a length limit.
            ($LengthLimit -lt (  # The length limit is exceeded.
                (($Segments | Measure-Object 'Length' -Sum).Sum) +
                ($Segments.Count - 1) +  # count of separators required (assuming separator length of one)
                $(if ($PrependEllipses) { 2 } else { 0 })  # length of ellipses character and trailing separator
            ))
        )
    }
    while (($limited.Count -gt 1) -and -not (Test-LengthLimit $limited $prependEllipses)) {
        $limited = $limited | Select-Object -Skip 1
        $prependEllipses = $true
    }

    if ($prependEllipses) {
        $limited = @($ellipses) + $limited
    }

    Write-Debug "`$limited = @( $( $limited.ForEach{ "'$_'" } -join ', ') )"
    #endregion

    # Prepare the path for conversion to Pansies text(s).
    $buffer = $limited.ForEach{
        $output = @{ Object = $_ }

        # Always set the defaults first, if they're provided.
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

        $output
    }
    Write-Debug "`$buffer = @( $($buffer.ForEach{ "@{ $(($_.GetEnumerator() | ForEach-Object { "$($_.Key) = '$($_.Value)'" }) -join '; ') }" } -join ', ') )"

    # Output the segmented path as an array of Pansies texts.
    [PoshCode.Pansies.Text[]]$buffer
}
