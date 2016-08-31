#requires -module PowerLine
using module PowerLine

$global:PowerLinePrompt = [PowerLinePrompt]::new(@(
    [PowerLine]::New(@(
            [PowerLineBlock]::Column # Column break, the rest is right-aligned
            @{ bg = "DarkGray"; fg = "white"; text = { Get-Elapsed } }
        )
    )
    [PowerLine]::New(@(
            @{ bg = "blue";     fg = "white"; text = { $MyInvocation.HistoryId } }
            @{ bg = "cyan";     fg = "white"; text = { "$([PowerLine]::Gear)" * $NestedPromptLevel } }
            @{ bg = "cyan";     fg = "white"; text = { if($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } } }
            @{ bg = "darkblue"; fg = "white"; text = { $pwd.Drive.Name } }
            @{ bg = "darkblue"; fg = "white"; text = { Split-Path $pwd -leaf } }
        ),
        $true
    )
), 1)

function global:prompt {
    "${global:PowerLinePrompt}"
}
