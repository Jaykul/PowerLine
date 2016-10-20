function Write-AnsiHost {
    <#
    .Synopsis
        Writes a string with ANSI VT escape sequences to the Host
    .Description
        Translates any ANSI VT escape sequences in the $Text parameter into the appropriate commands for the PS Host.

        Currently only the color and cursor movement escape sequences are supported.
    .Example
        Write-AnsiHost -Text "$([char]0x1B)[91Error!"

        This example produces the same output as Write-Host -Object "Error!" -ForegroundColor [System.ConsoleColor]::Red -NoNewline
    .Example
        "$([char]0x1B)[1AHeader" | Write-AnsiHost

        This example produces the same output as the following series of commands:
            $c = $Host.UI.RawUI.CursorPosition
            $c.Y -= 1
            $Host.UI.RawUI.CursorPosition = $c
            Write-Host -Object "Header" -NoNewline
    #>
    param(
        # The text with ANSI VT escape sequences to write to the Host
        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)] [System.String[]] $Text
    )

    begin {
        $bg = $fg = $null
    }
    process {
        foreach ($item in $Text) {
            foreach ($token in Get-AnsiTokens -Text $item) {
                $param = Get-AnsiParameter -Value $token.data
                if ("[A" -ceq $token.code) {
                    if (!$param) { $param = 1 }
                    Update-CursorPosition { $c.Y -= $param }
                }
                if ("[B" -ceq $token.code) {
                    if (!$param) { $param = 1 }
                    Update-CursorPosition { $c.Y += $param }
                }
                if ("[C" -ceq $token.code) {
                    if (!$param) { $param = 1 }
                    Update-CursorPosition { $c.X += $param }
                }
                if ("[D" -ceq $token.code) {
                    if (!$param) { $param = 1 }
                    Update-CursorPosition { $c.X -= $param }
                }
                if ("[E" -ceq $token.code) {
                    if (!$param) { $param = 1 }
                    Update-CursorPosition { $c.X = 0; $c.Y += $param }
                }
                if ("[F" -ceq $token.code) {
                    if (!$param) { $param = 1 }
                    Update-CursorPosition { $c.X = 0; $c.Y -= $param }
                }
                if ("[G" -ceq $token.code) {
                    if ($param) { $param -= 1 }
                    if (Test-Path variable:psISE) {
                        $x = (Get-Host).UI.RawUI.CursorPosition.X
                        if ($x -lt $param) { Write-Host -Object (" " * ($param - $x)) -NoNewline}
                    } else {
                        Update-CursorPosition { $c.X = $param }
                    }
                }
                if ("[m" -ceq $token.code -and 30 -le $param -and 37 -ge $param) {
                    $fg = $colors[$param - 30]
                }
                if ("[m" -ceq $token.code -and 40 -le $param -and 47 -ge $param) {
                    $bg = $colors[$param - 40]
                }
                if ("[m" -ceq $token.code -and 90 -le $param -and 97 -ge $param) {
                    $fg = $colors[$param - 90 + 8]
                }
                if ("[m" -ceq $token.code -and 100 -le $param -and 107 -ge $param) {
                    $bg = $colors[$param - 100 + 8]
                }
                if ($null -eq $token.code -and -not [System.String]::IsNullOrEmpty($token.data)) {
                    $params = @{ Object = $token.data }
                    if ($null -ne $fg) { $params.Add("ForegroundColor", $fg) }
                    if ($null -ne $bg) { $params.Add("BackgroundColor", $bg) }
                    Write-Host -NoNewline @params
                }
            }
        }
    }
}

function Get-AnsiTokens {
    param(
        [Parameter(Mandatory=$true)] [string] $Text
    )

    $dataBufferStart = 0
    $readingCsiData = $false
    for ($i = 0; $i -lt $Text.Length; $i++) {
        if ($readingCsiData -and 0x40 -le $Text.Chars($i) -and 0x7E -ge $Text.Chars($i)) {
            [PSCustomObject]@{ code = "[" + $Text.Chars($i); data = $Text.Substring($dataBufferStart, $i - $dataBufferStart) }
            $dataBufferStart = $i + 1
            $readingCsiData = $false
        }
        if (0x1B -eq $Text.Chars($i) -and 0x40 -le $Text.Chars($i+1) -and 0x5F -ge $Text.Chars($i+1)) {
            if ($i - $dataBufferStart -gt 0) { [PSCustomObject]@{ code = $null; data = $Text.Substring($dataBufferStart, $i - $dataBufferStart) } }
            $dataBufferStart = ++$i + 1
            if (0x5B -ne $Text.Chars($i)) { [PSCustomObject]@{ code = $Text.Chars($i); data = $null} } else { $readingCsiData = $true }
        }
    }
    [PSCustomObject]@{ code = $null; data = $Text.Substring($dataBufferStart, $i - $dataBufferStart)}
}

function Get-AnsiParameter {
    param(
        [string] $Value
    )

    $result = 0
    [int]::TryParse($Value, [ref]$result) | Out-Null
    if (0 -gt $result) { $result = 0 }
    $result
}

function Update-CursorPosition {
    param (
        [scriptblock]$updateFunction = {}
    )

    $c = (Get-Host).UI.RawUI.CursorPosition
    & $updateFunction
    (Get-Host).UI.RawUI.CursorPosition = $c
}

$colors = @(
    [System.ConsoleColor]::Black
    [System.ConsoleColor]::DarkRed
    [System.ConsoleColor]::DarkGreen
    [System.ConsoleColor]::DarkYellow
    [System.ConsoleColor]::DarkBlue
    [System.ConsoleColor]::DarkMagenta
    [System.ConsoleColor]::DarkCyan
    [System.ConsoleColor]::Gray
    [System.ConsoleColor]::DarkGray
    [System.ConsoleColor]::Red
    [System.ConsoleColor]::Green
    [System.ConsoleColor]::Yellow
    [System.ConsoleColor]::Blue
    [System.ConsoleColor]::Magenta
    [System.ConsoleColor]::Cyan
    [System.ConsoleColor]::White
)