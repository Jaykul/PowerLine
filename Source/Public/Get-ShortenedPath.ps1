function Get-ShortenedPath {
    <#
        .SYNOPSIS
            Get a shortened version of a path for human readability
        .DESCRIPTION
            Trims the length of the path using various techniques
        .NOTES
            Inspired by some blog posts like this one
            http://www.winterdom.com/powershell/2008/08/13/mypowershellprompt.html
     #>
    [CmdletBinding()]
    param(
        # The path to shorten (by default, the present working directory: $pwd)
        [Parameter(Position=0)]
        [string]$Path = $pwd,

        # Optionally, a strict maximum length
        # Path will be truncated to ensure it's shorter, and an ellipsis substituted
        [Parameter(Position=1)]
        [int]$MaximumLength = [int]::MaxValue,

        # Optionally, use ~ to replace the $Home directory when possible
        [Parameter()]
        [switch]$RelativeToHome,

        # Optionally, trim all but the last folder to a single character
        [Parameter()]
        [switch]$SingleCharacterSegment,

        # Optionally, turn it into a hyperlink to the full path.
        # In Windows Terminal, for instance, this makes it show the full path on hover, and open your file manager on ctrl+click
        [Parameter()]
        [switch]$AsUrl
    )

    $OriginalPath = $Path

    # If user passes 0 (or less), I just refuse to deal with it
    if ($MaximumLength -le 0) {
        return [string]::Empty
    }

    if ($RelativeToHome -and $Path.ToLower().StartsWith($Home.ToLower())) {
        $Path = '~' + $Path.Substring($Home.Length)
    }

    $Separator = [regex]::Escape([IO.Path]::DirectorySeparatorChar)

    if ($SingleCharacterSegment) {
        # Remove prefix for UNC paths
        $Path = $Path -replace '^[^:]+::', ''
        # Be careful to handle paths starting with \\ and . correctly
        $Path = ($Path -replace "$Separator(\.?)([^$Separator])[^$Separator]*(?=$Separator)", '\$1$2')
    }

    if ($Path.Length -gt $MaximumLength) {
        $Folders = $Path -split $Separator
        [Array]::Reverse($Folders)
        $Path, $Folders = $Folders
        do {
            $Folder, $Folders = $Folders
            if ($Path.Length + 2 -gt $MaximumLength) {
                $Path = [char]0x2026 + $Path.Substring($Path.Length - $MaximumLength + 1)
                break
            }
            if ($Path.Length + $Folder.Length + 3 -le $MaximumLength) {
                $Path = $Folder + [IO.Path]::DirectorySeparatorChar + $Path
            } else {
                $Path = [char]0x2026 + [IO.Path]::DirectorySeparatorChar + $Path
                break
            }
        } while ($Folders)
    }

    if ($AsUrl) {
        $8 = "$([char]27)]8;;"
        "$8{0}`a{1}$8`a" -f $OriginalPath, $Path
    } else {
        $Path
    }
}
