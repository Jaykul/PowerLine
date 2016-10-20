using namespace System.Collections.Generic
Add-Type -Path .\PowerLine.cs
. .\Write-AnsiHost.ps1

function New-FakeHostWithCursorPosition {
    param(
        [int]$X,
        [int]$Y
    )

    [PSCustomObject]@{
        UI = [PSCustomObject]@{
            RawUI = [PSCustomObject]@{
                CursorPosition = New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList $X, $Y
            }
        }
    }
}

Describe "Write-AnsiHost" {
    Mock Write-Host {}

    It "Processes the cursor up escape code" {
        $y = Get-Random -Maximum 9999
        $myHost = New-FakeHostWithCursorPosition -Y $y
        Mock Get-Host { $myHost }
        $n = Get-Random -Minimum 1 -Maximum 9999
        "$([char]0x1B)[$($n)A" | Write-AnsiHost
        $myHost.UI.RawUI.CursorPosition.Y | Should Be ($y - $n)
    }

    It "Processes the cursor down escape code" {
        $y = Get-Random -Maximum 9999
        $myHost = New-FakeHostWithCursorPosition -Y $y
        Mock Get-Host { $myHost }
        $n = Get-Random -Minimum 1 -Maximum 9999
        "$([char]0x1B)[$($n)B" | Write-AnsiHost
        $myHost.UI.RawUI.CursorPosition.Y | Should Be ($y + $n)
    }

    It "Processes the cursor forward escape code" {
        $x = Get-Random -Maximum 9999
        $myHost = New-FakeHostWithCursorPosition -X $x
        Mock Get-Host { $myHost }
        $n = Get-Random -Minimum 1 -Maximum 9999
        "$([char]0x1B)[$($n)C" | Write-AnsiHost
        $myHost.UI.RawUI.CursorPosition.X | Should Be ($x + $n)
    }

    It "Processes the cursor back escape code" {
        $x = Get-Random -Maximum 9999
        $myHost = New-FakeHostWithCursorPosition -X $x
        Mock Get-Host { $myHost }
        $n = Get-Random -Minimum 1 -Maximum 9999
        "$([char]0x1B)[$($n)D" | Write-AnsiHost
        $myHost.UI.RawUI.CursorPosition.X | Should Be ($x - $n)
    }

    It "Processes the cursor next line escape code" {
        $y = Get-Random -Maximum 9999
        $myHost = New-FakeHostWithCursorPosition -X (Get-Random -Minimum 1 -Maximum 9999) -Y $y
        Mock Get-Host { $myHost }
        $n = Get-Random -Minimum 1 -Maximum 9999
        "$([char]0x1B)[$($n)E" | Write-AnsiHost
        $myHost.UI.RawUI.CursorPosition | Should Be (New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList 0, ($y + $n))
    }

    It "Processes the cursor previous line escape code" {
        $y = Get-Random -Maximum 9999
        $myHost = New-FakeHostWithCursorPosition -X (Get-Random -Minimum 1 -Maximum 9999) -Y $y
        Mock Get-Host { $myHost }
        $n = Get-Random -Minimum 1 -Maximum 9999
        "$([char]0x1B)[$($n)F)" | Write-AnsiHost
        $myHost.UI.RawUI.CursorPosition | Should Be (New-Object -TypeName System.Management.Automation.Host.Coordinates -ArgumentList 0, ($y - $n))
    }

    It "Processes the cursor horizontal absolute escape code" {
        $myHost = New-FakeHostWithCursorPosition -X (Get-Random -Maximum 9999)
        Mock Get-Host { $myHost }
        $n = Get-Random -Maximum 9999
        "$([char]0x1B)[$($n)G" | Write-AnsiHost
        $myHost.UI.RawUI.CursorPosition.X | Should Be ($n - 1)
    }

    It "Processes the color escape codes" {
        $bg = [System.ConsoleColor](Get-Random -Maximum 15)
        $fg = [System.ConsoleColor](Get-Random -Maximum 15)
        $text = "PS"
        Write-AnsiHost -Text ([PowerLine.AnsiHelper]::WriteAnsi($fg, $bg, $text))
        Assert-MockCalled Write-Host 1 { $Object -eq $text -and $ForegroundColor -eq $fg -and $BackgroundColor -eq $bg } -Exactly
    }
}