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
    <#
    .Synopsis
        Get the time span elapsed during the execution of command (by default the previous command)
    .Description
        Calls Get-History to return a single command and returns the difference between the Start and End execution time
    #>
    [CmdletBinding()]
    param(
        # The command ID to get the execution time for (defaults to the previous command)
        [Parameter()]
        [int]$Id,

        # A Timespan format pattern such as "{0:ss\.ffff}"
        [Parameter()]
        [string]$Format = "{0:h\:mm\:ss\.ffff}"
    )
    $null = $PSBoundParameters.Remove("Format")
    $LastCommand = Get-History -Count 1 @PSBoundParameters
    if(!$LastCommand) { return "" }
    $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
    $Format -f $Duration
}

function Test-Success {
    <#
    .Synopsis
        Get a value indicating whether the last command succeeded or not
    #>
    [CmdletBinding()]
    param()

    $script:LastSuccess
}

function Test-Elevation {
    <#
    .Synopsis
        Get a value indicating whether the process is elevated (running as administrator)
    #>
    [CmdletBinding()]
    param()

    [Security.Principal.WindowsIdentity]::GetCurrent().Owner -eq 'S-1-5-32-544'
}

function New-PowerLineBlock {
    <#
        .Synopsis
            Create PowerLine.Blocks with variable background colors
        .Description
            Allows changing the foreground and background colors based on elevation or success.

            Tests elevation fist, and then whether the last command was successful, so if you pass separate colors for each, the Elevated*Color will be used when PowerShell is running as administrator and there is no error. The Error*Color will be used whenever there's an error, whether it's elevated or not.
        .Example

    #>
    [CmdletBinding(DefaultParameterSetName="Error")]
    param(
        # The text, object, or scriptblock to show as output
        [Parameter(Position=0, Mandatory=$true)]
        $Object,

        # The foreground color to use when the last command succeeded
        [ConsoleColor]$ForegroundColor,

        # The background color to use when the last command succeeded
        [ConsoleColor]$BackgroundColor,

        # The foreground color to use when the process is elevated (running as administrator)
        [ConsoleColor]$ElevatedForegroundColor,

        # The background color to use when the process is elevated (running as administrator)
        [ConsoleColor]$ElevatedBackgroundColor,

        # The foreground color to use when the last command failed
        [ConsoleColor]$ErrorForegroundColor,

        # The background color to use when the last command failed
        [ConsoleColor]$ErrorBackgroundColor
    )
    $output = [PowerLine.BlockFactory]@{
        Object = $Object
    }
    # Always set the defaults first, if they're provided
    if($PSBoundParameters.ContainsKey("ForegroundColor")) {
        $output.DefaultForegroundColor = $ForegroundColor
    }
    if($PSBoundParameters.ContainsKey("BackgroundColor")) {
        $output.DefaultBackgroundColor = $BackgroundColor
    }

    # If it's elevated, and they passed the elevated color ...
    if(!(Test-Elevation)) {
        if($PSBoundParameters.ContainsKey("ElevatedForegroundColor")) {
            $output.DefaultForegroundColor = $ElevatedForegroundColor
        }
        if($PSBoundParameters.ContainsKey("ElevatedBackgroundColor")) {
            $output.DefaultBackgroundColor = $ElevatedBackgroundColor
        }
    }

    # If it failed, and they passed an error color ...
    if(!(Test-Success)) {
        if($PSBoundParameters.ContainsKey("ErrorForegroundColor")) {
            $output.DefaultForegroundColor = $ErrorForegroundColor
        }
        if($PSBoundParameters.ContainsKey("ErrorBackgroundColor")) {
            $output.DefaultBackgroundColor = $ErrorBackgroundColor
        }
    }

    $output.GetBlocks()
}

function Set-PowerLinePrompt {
    [CmdletBinding(DefaultParameterSetName="PowerLine")]
    param(
        # A script which outputs a string used to update the Window Title each time the prompt is run
        [scriptblock]$Title,

        # Keep the .Net Current Directory in sync with PowerShell's
        [switch]$CurrentDirectory,

        # If true, set the [PowerLine.Prompt] static members to extended characters from PowerLine fonts
        [Parameter(ParameterSetName="PowerLine")]
        [switch]$PowerLineFont,

        # If true, set the [PowerLine.Prompt] static members to characters available in Consolas and Courier New
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
        [bool]$script:LastSuccess = $?

        try {
            if($PowerLinePrompt.Title) {
                $Host.UI.RawUI.WindowTitle = [System.Management.Automation.LanguagePrimitives]::ConvertTo( (& $PowerLinePrompt.Title), [string] )
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

Export-ModuleMember -Function Set-PowerLinePrompt, Get-Elapsed, Test-Success, New-PowerLineBlock -Variable PowerLinePrompt