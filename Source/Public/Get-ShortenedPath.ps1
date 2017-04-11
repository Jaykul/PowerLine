function Get-ShortenedPath {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        $Path = $pwd,

        [Parameter()]
        [switch]
        $RelativeToHome,

        [Parameter()]
        [int]
        $MaximumLength = [int]::MaxValue,

        [Parameter()]
        [switch]
        $SingleCharacterSegment        
    )

    if ($MaximumLength -le 0) {
        return [string]::Empty
    }

    if ($RelativeToHome -and $Path.ToLower().StartsWith($Home.ToLower())) {
        $Path = '~' + $Path.Substring($Home.Length)
    }

    if (($MaximumLength -gt 0) -and ($Path.Length -gt $MaximumLength)) {
        $Path = $Path.Substring($Path.Length - $MaximumLength)
        if ($Path.Length -gt 3) {
            $Path = "..." + $Path.Substring(3)
        }
    }

    # Credit: http://www.winterdom.com/powershell/2008/08/13/mypowershellprompt.html
    if ($SingleCharacterSegment) {
        # Remove prefix for UNC paths
        $Path = $Path -replace '^[^:]+::', ''
        # handle paths starting with \\ and . correctly
        $Path = ($Path -replace '\\(\.?)([^\\])[^\\]*(?=\\)','\$1$2')
    }

    $Path
}