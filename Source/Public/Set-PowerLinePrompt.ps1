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

        # PowerLine uses TerminalBlocks, and the DefaultCaps parameter sets [PoshCode.TerminalBlocks]::DefaultCaps
        # These are the cap character(s) that will be used (by default) on blocks
        # Pass two characters: the first for the left side, the second for the right side.
        [Parameter(ParameterSetName = "Manual", ValueFromPipelineByPropertyName)]
        [PoshCode.BlockCaps]$DefaultCaps,

        # PowerLine uses TerminalBlocks, and the DefaultSeparator parameter sets [PoshCode.TerminalBlocks]::DefaultSeparator
        # The separator character is used by some TerminalBlocks to separate multiple objects (like a path separator)
        [Parameter(ParameterSetName = "Manual", ValueFromPipelineByPropertyName)]
        [Alias("Separator")]
        [string]$DefaultSeparator,

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

        # How to render repeated prompts. A prompt is considered a repeat if it's run multiple times without a command,
        # such as when pressing enter repeatedly, or hitting Ctrl+C or Ctrl+L (any time the $MyInvcation.HistoryId does not change)
        #
        # By default, PowerLine uses "CachedPrompt" which repeats the whole prompt, but doesn't re-run the prompt blocks.
        #
        # You can choose to render only the last block, or the last line of the prompt, or to Recalculate the whole prompt.
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet("LastBlock", "LastLine", "CachedPrompt", "Recalculate")]
        [string]$RepeatPrompt,

        # When there's a parse error, PSReadLine changes a part of the prompt based on it's PromptText configuration.
        # This setting causes PowerLine to update the PSReadLiine PromptText on each run.
        #
        # By default, if the last prompt block has a background color, it will be set to tomato red (otherwise, the foreground color)
        # If you pass just one color, that color will be used instead of tomato red.
        # If you pass a pair of colors, the first will be replaced with the second throughout the entire last line of the prompt
        #
        # To disable this feature, pass an empty array, and PowerLine will not change the PromptText
        [Parameter(ValueFromPipelineByPropertyName)]
        [RgbColor[]]$PSReadLineErrorColor,

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

        # Switches have a (non-null) default value, so we need to set them in case they were not passed explicitly
        $Configuration = Import-Configuration -ErrorAction SilentlyContinue | Update-Object @{
            HideErrors = $HideErrors
            SetCurrentDirectory = $SetCurrentDirectory
        }

        # Strip common parameters to avoid adding nonsense to the object
        foreach ($name in [System.Management.Automation.PSCmdlet]::CommonParameters + @("Save", "NoBackground", "PowerLineFont")) {
            $null = $PSBoundParameters.Remove($name)
        }
    }
    process {
        try {
            [PowerLineTheme]$Local:PowerLineConfig = $Configuration | Update-Object $PSBoundParameters
        } catch {
            $ConfigPath = Join-Path (Get-ConfigurationPath) "Configuration.psd1"
            $Date = Get-Date -f "yyyyMMdd"
            $NewPath = [IO.Path]::ChangeExtension($ConfigPath, "$Date.psd1")
            $Index = 0
            while(Test-Path $NewPath) {
                $Index++
                $NewPath = [IO.Path]::ChangeExtension($ConfigPath, "$Date.$Index.psd1")
            }
            Write-Warning "Failed to import existing config, creating default prompt. Moved old '$ConfigPath' to '$NewPath'"
            Move-Item $ConfigPath $NewPath -Force

            try {
                # Redo the import, so they get configuration from our default file
                [PowerLineTheme]$Local:PowerLineConfig = Import-Configuration -ErrorAction SilentlyContinue | Update-Object @{
                    HideErrors          = $HideErrors
                    SetCurrentDirectory = $SetCurrentDirectory
                } | Update-Object $PSBoundParameters
            } catch {
                [PowerLineTheme]$Local:PowerLineConfig = $PSBoundParameters
            }
        }

        # Set the default cap & separator before we cast prompt blocks
        if ($NoBackground) {
            $PowerLineConfig.DefaultCaps = [PoshCode.TerminalBlock]::DefaultCaps = "", " "
            $PowerLineConfig.DefaultSeparator = [PoshCode.TerminalBlock]::DefaultSeparator = "/"
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
            } else {
                # Use characters that at least work in Consolas and Lucida Console
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ColorSeparator'] = [char]0x258C
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseColorSeparator'] = [char]0x2590
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Separator'] = [char]0x25BA
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseSeparator'] = [char]0x25C4
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Branch'] = [char]0x00A7
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Gear'] = [char]0x263C
            }
            # Set the new Cap and Separator options too
            [PoshCode.TerminalBlock]::DefaultCaps = $PowerLineConfig.DefaultCaps = "", [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator"]
            [PoshCode.TerminalBlock]::DefaultSeparator = $PowerLineConfig.Separator = [PoshCode.Pansies.Entities]::ExtendedCharacters["Separator"]
        }

        if ($PSBoundParameters.ContainsKey("DefaultCaps")) {
            [PoshCode.TerminalBlock]::DefaultCaps = $PowerLineConfig.DefaultCaps = $DefaultCaps
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator"] = $DefaultCaps.Right
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ReverseColorSeparator"] = $DefaultCaps.Left
        } elseif (!$PowerLineConfig.DefaultCaps) {
            # If there's nothing in the config, then default to Powerline style!
            [PoshCode.TerminalBlock]::DefaultCaps = $PowerLineConfig.DefaultCaps = "", [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator"]
        } elseif ($PowerLineConfig.DefaultCaps) {
            [PoshCode.TerminalBlock]::DefaultCaps = $PowerLineConfig.DefaultCaps
        }

        if ($PSBoundParameters.ContainsKey("DefaultSeparator")) {
            [PoshCode.TerminalBlock]::DefaultSeparator = $PowerLineConfig.DefaultSeparator = $DefaultSeparator
        } elseif (!$PowerLineConfig.DefaultSeparator) {
            # If there's nothing in the config, then default to Powerline style!
            [PoshCode.TerminalBlock]::DefaultSeparator = $PowerLineConfig.DefaultSeparator = [PoshCode.Pansies.Entities]::ExtendedCharacters["DefaultSeparator"]
        } elseif ($PowerLineConfig.DefaultSeparator) {
            [PoshCode.TerminalBlock]::DefaultSeparator = $PowerLineConfig.DefaultSeparator
        }

        # These switches aren't stored in the config
        $null = $PSBoundParameters.Remove("Save")

        Write-Verbose "Setting global:Prompt"
        # We want to support modifying the global:prompt variable outside this function
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
        if ($NoBackground) {
            foreach($block in $PowerLineConfig.Prompt){
                $block.BackgroundColor = $null
            }
        }

        [System.Collections.Generic.List[PoshCode.TerminalBlock]]$global:Prompt = $PowerLineConfig.Prompt

        if ($null -eq $PowerLineConfig.DefaultAddIndex) {
            $PowerLineConfig.DefaultAddIndex    = -1
        }

        $Script:PowerLineConfig = $PowerLineConfig

        if (Get-Module PSReadLine) {
            $Options = @{}
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
