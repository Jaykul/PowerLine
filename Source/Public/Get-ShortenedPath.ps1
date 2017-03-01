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
        $MaximumLength = [int]::MaxValue
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

    $Path
}