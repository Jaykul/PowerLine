#!/usr/bin/env powershell
using namespace System.Collections.Generic

Add-Type -Path (Join-Path $PSScriptRoot PowerLine.cs)


if(!$PowerLinePrompt) {
    [PowerLine.Prompt]$Script:PowerLinePrompt = @(,@(
        @{ bg = "Cyan";     fg = "White"; text = { $MyInvocation.HistoryId } },
        @{ bg = "DarkBlue"; fg = "White"; text = { $pwd } }
    ))
    # Get-Location -Stack doesn't work when we define the scriptblock in the module -- not sure why
    #    [PowerLine.Block]@{ bg = "cyan";     fg = "white"; text = { if($pushd = (Get-Location -Stack).count) { "»" + $pushd } } }
}

function Get-Elapsed {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$Id,

        [Parameter()]
        [string]$Format = "{0:h\:mm\:ss\.ffff}"
    )
    $LastCommand = Get-History -Count 1 @PSBoundParameters
    if(!$LastCommand) { return "" }
    $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
    $Format -f $Duration
}

function Test-Success {
    [CmdletBinding()]
    param()
    return $script:LastSuccess
}

function Set-PowerLinePrompt {
    [CmdletBinding(DefaultParameterSetName="PowerLine")]
    param(
        # Update the Window Title each time the prompt is run
        [scriptblock]$Title,

        # Keep the .Net Current Directory in sync with PowerShell's
        [switch]$CurrentDirectory,

        [Parameter(ParameterSetName="PowerLine")]
        [switch]$PowerLineFont,

        [Parameter(ParameterSetName="Reset")]
        [switch]$ResetSeparators
    )
    if($null -eq $script:OldPrompt) {
        $script:OldPrompt = $function:global:prompt
        $MyInvocation.MyCommand.Module.OnRemove = {
            $function:global:prompt = $script:OldPrompt
        }
    }
    if($PSBoundParameters.ContainsKey("Title")) {
        $global:PowerLinePrompt.Title = $Title
    }
    if($PSBoundParameters.ContainsKey("CurrentDirectory")) {
        $global:PowerLinePrompt.SetCurrentDirectory = $CurrentDirectory
    }

    if($ResetSeparators -or ($PSBoundParameters.ContainsKey("PowerLineFont") -and !$PowerLineFont) ) {
        # Use characters that at least work in Consolas
        [PowerLine.Prompt]::ColorSeparator  = [char]0x258C
        [PowerLine.Prompt]::ReverseColorSeparator = [char]0x2590
        [PowerLine.Prompt]::Separator  = [char]0x25BA
        [PowerLine.Prompt]::ReverseSeparator = [char]0x25C4
        [PowerLine.Prompt]::Branch   = [char]0x00A7
        [PowerLine.Prompt]::Gear     = [char]0x263C
    }
    if($PowerLineFont) {
        # Make sure we're using the PowerLine custom use extended characters:
        [PowerLine.Prompt]::ColorSeparator = [char]0xe0b0
        [PowerLine.Prompt]::ReverseColorSeparator = [char]0xe0b2
        [PowerLine.Prompt]::Separator = [char]0xe0b1
        [PowerLine.Prompt]::ReverseSeparator = [char]0xe0b3
        [PowerLine.Prompt]::Branch   = [char]0x26EF
        [PowerLine.Prompt]::Gear     = [char]0xE0A0
    }

    $function:global:prompt =  {

        # FIRST, make a note if there was an error in the previous command
        $script:LastSuccess = !$?

        try {
            if($PowerLinePrompt.Title) {
                $Host.UI.RawUI.WindowTitle = & $PowerLinePrompt.Title
            }
            if($PowerLinePrompt.SetCurrentDirectory) {
                # Make sure Windows & .Net know where we are
                # They can only handle the FileSystem, and not in .Net Core
                [System.IO.Directory]::SetCurrentDirectory( (Get-Location -PSProvider FileSystem).ProviderPath )
            }
        } catch {}

        if($Host.UI.SupportsVirtualTerminal -or ($Env:ConEmuANSI -eq "ON")) {
            $PowerLinePrompt.ToString($Host.UI.RawUI.BufferSize.Width)
        } else {
            Write-Host "No PowerLine for you! `$Host.UI.SupportsVirtualTerminal is false, and `$Env:ConEmuANSI` is not 'ON'" -ForegroundColor Red -BackgroundColor Black
            return "> "
        }
    }
}



Export-ModuleMember -Function Set-PowerLinePrompt, Get-Elapsed -Variable PowerLinePrompt