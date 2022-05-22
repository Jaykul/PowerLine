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
        # Path will be truncated to ensure it's shorter
        [Parameter(Position = 1)]
        [int]$Length = [int]::MaxValue,

        # Optionally, a strict maximum number of levels of path to display
        # Path will be truncated to ensure it's shorter
        [Parameter()]
        [int]$Depth = [int]::MaxValue,

        # Show the drive name on the front. Does not count toward length
        [switch]$DriveName,

        # A character to use for $Home. Defaults to "~"
        # You can use "&House;" to get 🏠 if you have Pansies set to EnableEmoji!
        # NOTE: this is based on the provider.
        # By default, only the FileSystem provider has a Home, but you can set them!
        [string]$HomeString,

        # Only shows the path down to the root of git projects
        [switch]$GitDir,

        # Show only the first letter for all directories except the last one
        [Parameter()]
        [switch]$SingleLetterPath,

        # Show the first letter instead of truncating
        [Parameter()]
        [switch]$LeftoversAsOneLetter,

        #
        [switch]$ToRepo,

        # Optionally, turn it into a hyperlink to the full path.
        # In Windows Terminal, for instance, this makes it show the full path on hover, and open your file manager on ctrl+click
        [Parameter()]
        [switch]$AsUrl,

        # A decorative replacement for the path separator. Defaults to DirectorySeparatorChar
        [ArgumentCompleter({
            [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new(
                [System.Management.Automation.CompletionResult[]]@(
                # The Consolas-friendly block characters ▌and▐ and ╲ followed by all the extended powerline cahracters
                @([string[]][char[]]@(@(0xe0b0..0xe0d4) + @(0x2588..0x259b) + @(0x256d..0x2572) + @('\','/'))).ForEach({
                    [System.Management.Automation.CompletionResult]::new("'$_'", $_, "ParameterValue", $_) })
            ))
        })]
        [string]$Separator
    )

    # If user passes 0 (or less), I just refuse to deal with it
    if ($Length -le 0 -or $Depth -le 0) {
        return [string]::Empty
    }

    $OriginalPath = $Path
    $resolved = Resolve-Path $Path
    $provider = $resolved.Provider
    if (!$Separator) {
        $Separator = $provider.ItemSeparator
    }
    $Drive = $resolved.Drive.Name + ":"
    $Path = $resolved.Path


    $BaseHome = $Provider.Home
    Write-Verbose "ProviderHome: $BaseHome"

    if ($GitDir -and (Get-Command git)) {
        Push-Location $OriginalPath
        $toplevel = git rev-parse --show-toplevel 2>$null | Convert-Path
        Write-Verbose "GitDir: $TopLevel"
        Write-Verbose "Path: $Path"
        if (!$LASTEXITCODE -and $Path.StartsWith($TopLevel, "OrdinalIgnoreCase")) {
            $Path = $Path.SubString($TopLevel.Length)
            # If we're in a gitdir, we insist on showing it (using driveName logic)
            $Drive = Split-Path $TopLevel -Leaf
            $DriveName = $true
            $Depth = $Depth - 1
            Write-Verbose "Full: $Path"
        }
        Pop-Location
    }

    if ($Path) {
        if ($HomeString -and $BaseHome -and $Path.StartsWith($BaseHome, "OrdinalIgnoreCase")) {
            # If we're in $HOME, we insist on showing it (using driveName logic)
            $Drive = ''
            $DriveName = $false
            $Path = $HomeString + $Path.Substring($Home.Length)
        } else {
            $Path = Split-Path $Path -NoQualifier
        }

        # Trust the provider's separator
        [PoshCode.Pansies.Text]$Path = $Path.Trim($provider.ItemSeparator)
        $Pattern = [regex]::Escape($provider.ItemSeparator)

        if ($SingleLetterPath) {
            # Remove prefix for UNC paths
            $Path = $Path -replace '^[^:]+::', ''
            $Folders = $Path -split $Pattern
            if ($Folders.Length -gt 1) {
                # Supports emoji
                $Folders = $Folders[0..($Folders.Count-2)].ForEach{ [System.Text.Rune]::GetRuneAt($_,0).ToString() } + @($Folders[-1])
            }
            $Path = $Folders -join $Separator
        } else {
            $Folders = $Path -split $Pattern
        }

        $Ellipsis = [char]0x2026

        if ($Path.Length -gt $Length -or $Folders.Length -gt $Depth) {
            [Array]::Reverse($Folders)
            # Start the path with just the last folder
            $Path, $Folders = $Folders
            $PathDepth = 1
            # If just the last folder is too long, truncate it
            if ("$Path".Length + 2 -gt $Length) {
                Write-Verbose "$Path ($("$Path".Length) - $Length)"
                $Path = $Ellipsis + "$Path".Substring("$Path".Length - $Length + 1)
                if ($LeftoversAsOneLetter) {
                    $Folders = $Folders.ForEach{ [System.Text.Rune]::GetRuneAt($_,0).ToString() }
                    $Length = [int]::MaxValue
                } else {
                    $Folders = @()
                }
            }

            while ($Folders) {
                $Folder, $Folders = $Folders

                if ($Length -gt ("$Path".Length + $Folder.Length + 3) -and $Depth -gt $PathDepth) {
                    $Path = $Folder + $Separator + $Path
                } elseif ($LeftoversAsOneLetter) {
                    # Put back the $Folder as well
                    $Folders = @(@($Folder) + $Folders).ForEach{ [System.Text.Rune]::GetRuneAt($_,0).ToString() } + @($Drive.Trim($provider.ItemSeparator, $Separator))
                    $Depth = $Length = [int]::MaxValue
                    $DriveName = $False
                } else {
                    $Path = $Ellipsis + $Separator + $Path
                    break
                }
                $PathDepth++
            }
        } else {
            $Path = $Path -replace $Pattern, $Separator
        }
    }

    if ($DriveName) {
        if ($Path) {
            $Path = $Drive + $Separator + $Path
        } else {
            $Path = $Drive
        }
    }

    if ($AsUrl) {
        $8 = "$([char]27)]8;;"
        "$8{0}`a{1}$8`a" -f $OriginalPath, $Path
    } else {
        "$Path"
    }
}
