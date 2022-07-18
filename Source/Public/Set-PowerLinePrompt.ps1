function Set-PowerLinePrompt {
    #.Synopsis
    #   Set the default PowerLine prompt function which uses the $Prompt variable
    #.Description
    #   Overwrites the current prompt function with one that uses the $Prompt variable
    #   Note that this doesn't try to preserve any changes already made to the prompt by modules like ZLocation
    #.Example
    #   Set-PowerLinePrompt -SetCurrentDirectory
    #
    #   Sets the powerline prompt and activates and option supported by this prompt function to update the .Net environment with the current directory each time the prompt runs.
    #.Example
    #   Set-PowerLinePrompt -SetCurrentDirectory -Title {
    #       Show-Path -HomeString "~" -Depth 2 -GitDir
    #   } -RestoreVirtualTerminal
    #
    #   Turns on all the non-prompt features of PowerLine:
    #   - Update the .net environment with the current directory each time the prompt runs
    #   - Update the title with a short version of the path each time the prompt runs
    #   - This legacy option calls a Windows api to enable VirtualTerminal processing on old versions of the Windows Console where this wasn't the default (if git is messing up your terminal, try this).
    #.Example
    #   Set-PowerLinePrompt -PowerLineFont
    #
    #   Sets the prompt using the default PowerLine characters. Note that you can still change the characters used to separate blocks in the PowerLine output after running this, by setting the Cap and Separator.
    #.Example
    #   Set-PowerLinePrompt -NoBackground
    #
    #   Sets the powerline prompt without the PowerLine effect. This disables background color on ALL current blocks, and switches the Cap and Separator to just a space. Remember that you can change the characters used to separate blocks in your prompt, by setting the Cap and Separator without affecting backgrounds.

    [Alias("Set-PowerLineTheme")]
    [CmdletBinding(DefaultParameterSetName = "Manual")]
    param(
        # One or more scriptblocks or TerminalBlocks you want to use as your new prompt
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        $Prompt,

        # Resets the prompt to use the default PowerLine characters as cap and separator
        [Parameter(ParameterSetName = "PowerLine", Mandatory)]
        [switch]$PowerLineFont,

        # The cap character(s) that will be used (by default) on normal, left-aligned blocks
        # Pass two characters: the first for the left side, the second for the right side.
        [Parameter(ParameterSetName = "Manual", ValueFromPipelineByPropertyName)]
        [Alias("LeftCaps")]
        [PoshCode.BlockCaps]$DefaultCapsLeftAligned,

        # The cap character(s) that will be used by default on right-aligned blocks
        # Pass two characters: the first for the left side, the second for the right side.
        [Parameter(ParameterSetName = "Manual", ValueFromPipelineByPropertyName)]
        [Alias("RightCaps")]
        [PoshCode.BlockCaps]$DefaultCapsRightAligned,

        # The Left pointing and Right pointing separator characters are used when a script-based PowerLine block outputs multiple objects
        # Pass two strings. The first for blocks that are Left-aligned, the second for right-aligned blocks, like: "",""
        [Parameter(ParameterSetName = "Manual", ValueFromPipelineByPropertyName)]
        [Alias("Separator")]
        [PoshCode.BlockCaps]$DefaultSeparator,

        # Sets the powerline prompt without the PowerLine effect.
        # Disables background on ALL TerminalBlocks
        # Switches the Cap and Separator to just a space.
        [Parameter(ParameterSetName = "Reset", Mandatory)]
        [switch]$NoBackground,

        # If set, calls Export-PowerLinePrompt
        [Parameter()]
        [Switch]$Save,

        # A script which outputs a string used to update the Window Title each time the prompt is run
        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock]$Title,

        # Keep the .Net Current Directory in sync with PowerShell's
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("CurrentDirectory")]
        [switch]$SetCurrentDirectory,

        # Prevent errors in the prompt from being shown (like the normal PowerShell behavior)
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$HideErrors,

        # When there's a parse error, PSReadLine changes a part of the prompt...
        # Use this option to override PSReadLine by either specifying the characters it should replace, or by specifying both the normal and error strings.
        # If you specify two strings, they should both be the same length (ignoring escape sequences)
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$PSReadLinePromptText,

        # When you type a command that requires a second line (like if you type | and hit enter)
        # This is the prompt text. Can be an empty string. Can be anything, really.
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [string]$PSReadLineContinuationPrompt,

        # Let's you set the fg/bg of the PSReadLine continuation prompt as escape sequences.
        # The easy way is to use PANSIES notation: "$fg:Red$Bg:White"
        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [string]$PSReadLineContinuationPromptColor
    )
    begin {
        if ($null -eq $script:OldPrompt) {
            $script:OldPrompt = $function:global:prompt
            $MyInvocation.MyCommand.Module.OnRemove = {
                $function:global:prompt = $script:OldPrompt
            }
        }

        $Configuration = Import-Configuration -ErrorAction SilentlyContinue

        # Strip common parameters to avoid adding nonsense to the object
        foreach ($name in [System.Management.Automation.PSCmdlet]::CommonParameters + @("Save", "NoBackground", "PowerLineFont")) {
            $null = $PSBoundParameters.Remove($name)
        }

        [PowerLineTheme]$Local:PowerLineConfig = $Configuration | Update-Object $PSBoundParameters

        # Set the default cap before we cast prompt blocks
        if ($NoBackground) {
            $PowerLineConfig.DefaultCapsLeftAligned = [PoshCode.TerminalBlock]::DefaultCapsLeftAligned = " "
            $PowerLineConfig.DefaultCapsRightAligned = [PoshCode.TerminalBlock]::DefaultCapsRightAligned = " "
            $PowerLineConfig.DefaultSeparator = [PoshCode.TerminalBlock]::DefaultSeparator = " "
        }

        # For backward compatibility:
        if ($PSBoundParameters.ContainsKey("PowerLineFont")) {
            if ($PowerLineFont) {
                # Make sure we're using the default PowerLine characters:
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ColorSeparator'] = [char]0xe0b0
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseColorSeparator'] = [char]0xe0b2
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Separator'] = [char]0xe0b1
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseSeparator'] = [char]0xe0b3
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Branch'] = [char]0xE0A0
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Gear'] = [char]0x26EF

                # [PoshCode.Pansies.Entities]::EnableNerdFonts = $true
            } else  {
                # Use characters that at least work in Consolas and Lucida Console
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ColorSeparator'] = [char]0x258C
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseColorSeparator'] = [char]0x2590
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Separator'] = [char]0x25BA
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseSeparator'] = [char]0x25C4
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Branch'] = [char]0x00A7
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Gear'] = [char]0x263C
            }
            # Set the new Cap and Separator options too
            [PoshCode.TerminalBlock]::DefaultCapsLeftAligned = $PowerLineConfig.DefaultCapsLeftAligned = "", [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator"]
            [PoshCode.TerminalBlock]::DefaultCapsRightAligned = $PowerLineConfig.DefaultCapsRightAligned = [PoshCode.Pansies.Entities]::ExtendedCharacters["ReverseColorSeparator"], ""

            [PoshCode.TerminalBlock]::DefaultSeparator = $PowerLineConfig.Separator = -join [PoshCode.Pansies.Entities]::ExtendedCharacters["Separator", "ReverseSeparator"]
        }

        if ($PSBoundParameters.ContainsKey("DefaultCapsLeftAligned")) {
            [PoshCode.TerminalBlock]::DefaultCapsLeftAligned = $PowerLineConfig.DefaultCapsLeftAligned = $DefaultCapsLeftAligned
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator"] = $DefaultCapsLeftAligned.Right
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ReverseColorSeparator"] = $DefaultCapsLeftAligned.Left
        } elseif (!$PowerLineConfig.DefaultCapsLeftAligned) {
            # If there's nothing in the config, then default to Powerline style!
            [PoshCode.TerminalBlock]::DefaultCapsLeftAligned = $PowerLineConfig.DefaultCapsLeftAligned = "", [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator"]
        } elseif ($PowerLineConfig.DefaultCapsLeftAligned) {
            [PoshCode.TerminalBlock]::DefaultCapsLeftAligned = $PowerLineConfig.DefaultCapsLeftAligned
        }

        if ($PSBoundParameters.ContainsKey("DefaultCapsRightAligned")) {
            [PoshCode.TerminalBlock]::DefaultCapsRightAligned = $PowerLineConfig.DefaultCapsRightAligned = $DefaultCapsRightAligned
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ReverseColorSeparator"] = $DefaultCapsRightAligned.Left
        } elseif (!$PowerLineConfig.DefaultCapsRightAligned) {
            # If there's nothing in the config, then default to Powerline style!
            [PoshCode.TerminalBlock]::DefaultCapsRightAligned = $PowerLineConfig.DefaultCapsRightAligned = [PoshCode.Pansies.Entities]::ExtendedCharacters["ReverseColorSeparator"], ""
        } elseif ($PowerLineConfig.DefaultCapsRightAligned) {
            [PoshCode.TerminalBlock]::DefaultCapsRightAligned = $PowerLineConfig.DefaultCapsRightAligned
        }

        if ($PSBoundParameters.ContainsKey("DefaultSeparator")) {
            [PoshCode.TerminalBlock]::DefaultSeparator = $PowerLineConfig.DefaultSeparator = $DefaultSeparator
            [PoshCode.Pansies.Entities]::ExtendedCharacters["Separator"] = $DefaultSeparator.Left
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ReverseSeparator"] = $DefaultSeparator.Right
        } elseif (!$PowerLineConfig.DefaultSeparator) {
            # If there's nothing in the config, then default to Powerline style!
            [PoshCode.TerminalBlock]::DefaultSeparator = $PowerLineConfig.DefaultSeparator = -join [PoshCode.Pansies.Entities]::ExtendedCharacters["DefaultSeparator", "ReverseSeparator"]
        } elseif ($PowerLineConfig.DefaultSeparator) {
            [PoshCode.TerminalBlock]::DefaultSeparator = $PowerLineConfig.DefaultSeparator
        }
    }
    process {
        # These switches aren't stored in the config
        $null = $PSBoundParameters.Remove("Save")

        Write-Verbose "Setting global:Prompt"
        # We want to support modifying the global:prompt variable outside this function
        [System.Collections.Generic.List[PoshCode.TerminalBlock]]$global:Prompt = `
        [PoshCode.TerminalBlock[]]$PowerLineConfig.Prompt = @(
            if ($PSBoundParameters.ContainsKey("Prompt")) {
                Write-Verbose "Setting global:Prompt from prompt parameter"
                $Local:Prompt
            # They didn't pass anything, and there's nothing set
            } elseif ($global:Prompt.Count -eq 0) {
                # If we found something in config
                if ($PowerLineConfig.Prompt.Count -gt 0) {
                    Write-Verbose "Setting global:Prompt from powerline config"
                    # If the config is already TerminalBlock, just use that:
                    if ($PowerLineConfig.Prompt -as [PoshCode.TerminalBlock[]]) {
                        $PowerLineConfig.Prompt
                    } else {
                        # Try to upgrade by casting through scriptblock
                        [ScriptBlock[]]@($PowerLineConfig.Prompt)
                    }
                } else {
                    Write-Verbose "Setting global:Prompt from default prompt"
                    # The default PowerLine Prompt
                    Show-HistoryId -DefaultBackgroundColor DarkGray -ErrorBackgroundColor Red
                    Show-Path -DefaultBackgroundColor White
                }
            } else {
                Write-Verbose "Setting global:Prompt from existing global:prompt"
                $global:Prompt
            }
        )

        if ($null -eq $PowerLineConfig.DefaultAddIndex) {
            $PowerLineConfig.DefaultAddIndex    = -1
        }

        $Script:PowerLineConfig = $PowerLineConfig

        if (Get-Module PSReadLine) {
            $Options = @{}
            if ($PowerLineConfig.PSReadLinePromptText) {
                $Options["PromptText"] = $PowerLineConfig.PSReadLinePromptText
            }

            if ($PowerLineConfig.PSReadLineContinuationPrompt) {
                $Options["ContinuationPrompt"] = $PowerLineConfig.PSReadLineContinuationPrompt
            }
            if ($PowerLineConfig.PSReadLineContinuationPromptColor) {
                $Options["Colors"] = @{
                    ContinuationPrompt = $PowerLineConfig.PSReadLineContinuationPromptColor
                }
            }
            if ($Options) {
                Write-Verbose "Updating PSReadLine prompt options: `n$($Options.PromptText -join "`n")`n`n$($Options["Colors"]["ContinuationPrompt"])$($Options["ContinuationPrompt"])"
                Set-PSReadLineOption @Options
            }
        }

        # Finally, update the prompt function
        $function:global:prompt = { Write-PowerlinePrompt }
        [PoshCode.Pansies.RgbColor]::ResetConsolePalette()

        # If they asked us to save, or if there's nothing saved yet
        if($Save -or ($PSBoundParameters.Count -and !(Test-Path (Join-Path (Get-StoragePath) Configuration.psd1)))) {
            Export-PowerLinePrompt
        }
    }
}
