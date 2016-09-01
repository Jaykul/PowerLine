#!/usr/bin/env powershell
using namespace System.Collections.Generic

Add-Type -Path $PSScriptRoot/PowerLine.cs


if(!(Test-Path Variable:Global:PowerLinePrompt)) {
    $PromptLine = [PowerLine.Line]::New(
        @{ bg = "blue";     fg = "white"; text = { $MyInvocation.HistoryId } },
        @{ bg = "cyan";     fg = "white"; text = { "$([PowerLine.Line]::Gear)" * $NestedPromptLevel } },
        @{ bg = "darkblue"; fg = "white"; text = { $pwd.Drive.Name } },
        @{ bg = "darkblue"; fg = "white"; text = { Split-Path $pwd -leaf } }
    )
    # Get-Location -Stack doesn't work when we define the scriptblock in the module -- not sure why
    #    [PowerLine.Block]@{ bg = "cyan";     fg = "white"; text = { if($pushd = (Get-Location -Stack).count) { "»" + $pushd } } }
    $global:PowerLinePrompt = [PowerLine.Prompt]::new($PromptLine)
}

# # Add calculated values for the "Default" colors
# [PowerLine.Block]::EscapeCodes.fg.Default = [PowerLine.Block]::EscapeCodes.fg."$($Host.UI.RawUI.ForegroundColor)"
# [PowerLine.Block]::EscapeCodes.fg.Background = [PowerLine.Block]::EscapeCodes.fg."$($Host.UI.RawUI.BackgroundColor)"
# [PowerLine.Block]::EscapeCodes.bg.Default = [PowerLine.Block]::EscapeCodes.bg."$($Host.UI.RawUI.BackgroundColor)"


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

function Set-PowerLinePrompt {
    if($null -eq $script:OldPrompt) {
        $script:OldPrompt = $function:global:prompt
        $MyInvocation.MyCommand.Module.OnRemove = {
            $function:global:prompt = $script:OldPrompt
        }
    }

    $function:global:prompt =  {

        # FIRST, make a note if there was an error in the previous command
        $err = !$?

        try {
            if($PowerLinePrompt.SetTitle) {
                # Put the path in the title ... (don't restrict this to the FileSystem)
                $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix, (Convert-Path $pwd),  $pwd.Provider.Name
            }
            if($PowerLinePrompt.SetCwd) {
                # Make sure Windows & .Net know where we are
                # They can only handle the FileSystem, and not in .Net Core
                [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
            }
        } catch {}

        if($Host.UI.SupportsVirtualTerminal) {
            $PowerLinePrompt.ToString()
        } else {
            "> "
        }
    }
}

Update-TypeData -TypeName PowerLine.Block -DefaultDisplayPropertySet "BackgroundColor", "ForegroundColor", "Content"
