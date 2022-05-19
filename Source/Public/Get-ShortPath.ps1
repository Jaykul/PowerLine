function Get-ShortPath {
    <#
        .SYNOPSIS
            Get a shortened version of a path for human readability
        .DESCRIPTION
            Trims the length of the path using various techniques
    #>
    [CmdletBinding(DefaultParameterSetName = "Length")]
    param(
        # The path to shorten (by default, the present working directory: $pwd)
        [Parameter(Position=0)]
        [string]$Path = $pwd,

        # Optionally, a strict maximum length of path to display
        # Path will be truncated to ensure it's shorter, and an ellipsis substituted
        [Parameter(Position = 1, ParameterSetName = "Length")]
        [int]$MaximumLength = [int]::MaxValue,

        # Optionally, a strict maximum number of levels of path to display
        # Path will be truncated to ensure it's shorter, and an ellipsis substituted
        [Parameter(ParameterSetName = "Segments")]
        [int]$LimitDirectoryCount = [int]::MaxValue,

        # Show the drive name on the front
        [switch]$DriveName,

        # Don't use ~ to shorten the $Home path
        [switch]$NoHome,

        # Optionally, show only the first letter for each directory except it's last
        [Parameter()]
        [switch]$OneLetterDirectories,

        # Optionally, turn it into a hyperlink to the full path.
        # In Windows Terminal, for instance, this makes it show the full path on hover, and open your file manager on ctrl+click
        [Parameter()]
        [switch]$AsUrl,

        # A decorative replacement for the path separator. Defaults to DirectorySeparatorChar
        [string]$Separator
    )

    # If user passes 0 (or less), I just refuse to deal with it
    if ($MaximumLength -le 0 -or $LimitDirectoryCount -le 0) {
        return [string]::Empty
    }

    $OriginalPath = $Path
    $resolved = Resolve-Path $Path
    $provider = $resolved.Provider
    $drive = $resolved.Drive.Name
    if (!$Separator) {
        $Separator = $provider.ItemSeparator
    }

    $Path = $resolved.Path

    if (!$NoHome -and $Path.ToLower().StartsWith($Home.ToLower())) {
        $drive = ''
        $Path = '~' + $Path.Substring($Home.Length)
    } else {
        $Path = Split-Path $Path -NoQualifier
    }

    # Trust the provider's separator
    $Path = $Path.Trim($provider.ItemSeparator)
    $Pattern = [regex]::Escape($provider.ItemSeparator)

    if ($OneLetterDirectories) {
        # Remove prefix for UNC paths
        $Path = $Path -replace '^[^:]+::', ''
        $Folders = $Path -split $Pattern
        if ($Folders.Length -gt 1) {
            # Supports emoji
            $Folders = $folders[0..($Folders.Length-2)].ForEach{
                    [System.Text.Rune]::GetRuneAt($_,0).ToString()
                } + $Folders[-1]
        }
        $Path = $Folders -join $Separator
    } else {
        $Folders = $Path -split $Pattern
    }

    $Ellipsis = [char]0x2026

    if ($Path.Length -gt $MaximumLength -or $Folders.Length -gt $LimitDirectoryCount) {
        [Array]::Reverse($Folders)
        # Start the path with just the last folder
        $Path, $Folders = $Folders
        do {
            $Folder, $Folders = $Folders
            if ($Path.Length + 2 -gt $MaximumLength) {
                $Path = $Ellipsis + $Path.Substring($Path.Length - $MaximumLength + 1)
                break
            }
            if ($Path.Length + $Folder.Length + 3 -le $MaximumLength) {
                $Path = $Folder + $Separator + $Path
            } else {
                $Path = $Ellipsis + $Separator + $Path
                break
            }
        } while ($Folders)
    }

    if ($DriveName) {
        $Path = $drive + ":" + $Separator + $Path
    }

    if ($AsUrl) {
        $8 = "$([char]27)]8;;"
        "$8{0}`a{1}$8`a" -f $OriginalPath, $Path
    } else {
        $Path
    }
}
