function Get-CursorPosition {
    <#
        .SYNOPSIS
            Write a VT ANSI escape sequence to the host and capture the response
        .EXAMPLE
            $Row, $Col = (Get-VtResponse "`e[6n") -split ';' -replace "[`e\[R]"
            Gets the current cursor position into $Row and $Col
    #>
    [Alias("DECXCPR")]
    [CmdletBinding()]
    param()

    [Console]::Write("`e[6n")
    $response = -join @(while ([Console]::KeyAvailable) { [Console]::ReadKey($true).KeyChar })
    $Row, $Col = $response -replace '\e\[(\d+;\d+)R','$1' -split ';'
    [System.Drawing.Point]::new( $Col, $Row )
    if ($UserInput) {
        [ReadLine]::Insert($UserInput)
    }
}
