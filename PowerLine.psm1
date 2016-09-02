#!/usr/bin/env powershell
using namespace System.Collections.Generic

Add-Type -Path $PSScriptRoot/PowerLine.cs


if(!$PowerLinePrompt) {
    [PowerLine.Prompt]$Script:PowerLinePrompt = @(,[PowerLine.Line]::New(
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
                [System.IO.Directory]::SetCurrentDirectory( (Get-Location -PSProvider FileSystem).ProviderPath )
            }
        } catch {}

        if($Host.UI.SupportsVirtualTerminal -or ($Env:ConEmuANSI -eq "ON")) {
            $PowerLinePrompt.ToString()
        } else {
            Write-Host "No PowerLine for you! `$Host.UI.SupportsVirtualTerminal is false, and `$Env:ConEmuANSI` is not 'ON'" -ForegroundColor Red -BackgroundColor Black
            return "> "
        }
    }
}

Export-ModuleMember -Function Set-PowerLinePrompt, Get-Elapsed -Variable PowerLinePrompt