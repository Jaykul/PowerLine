function Get-CursorPosition {
    <#
        .SYNOPSIS
            Write a VT ANSI escape sequence to the host and capture the response
        .EXAMPLE
            $Point = Get-CursorPosition
            Gets the current cursor position as a Drawing.Point with X (Column) and Y (Row)
    #>
    [Alias("DECXCPR")]
    [CmdletBinding()]
    param()
    [Console]::Write("$([char]27)[6n")
    $response = -join @(while ([Console]::KeyAvailable) { [Console]::ReadKey($true).KeyChar })
    $Row, $Col = $response -replace '\e\[(\d+;\d+)R','$1' -split ';'
    [System.Drawing.Point]::new( $Col, $Row )
    if ($UserInput) {
        [ReadLine]::Insert($UserInput)
    }
}
