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
    #       Get-ShortPath -HomeString "~" -Separator '' -Depth 2 -GitDir
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
    [CmdletBinding(DefaultParameterSetName = "PowerLine")]
    param(
        # A script which outputs a string used to update the Window Title each time the prompt is run
        [Parameter(ValueFromPipelineByPropertyName)]
        [scriptblock]$Title,

        # Keep the .Net Current Directory in sync with PowerShell's
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("CurrentDirectory")]
        [switch]$SetCurrentDirectory,

        # Resets the prompt to use the default PowerLine characters as cap and separator
        [Parameter(ParameterSetName = "PowerLine", ValueFromPipelineByPropertyName)]
        [switch]$PowerLineFont,

        # Sets the powerline prompt without the PowerLine effect.
        # Disables background on ALL PowerLineBlocks
        # Switches the Cap and Separator to just a space.
        [Parameter(ParameterSetName = "Reset")]
        [switch]$NoBackground,

        # If true, assume full color support, otherwise normalize to 16 ConsoleColor
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$FullColor,

        # If true, adds ENABLE_VIRTUAL_TERMINAL_PROCESSING to the console output mode. Useful on PowerShell versions that don't restore the console
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$RestoreVirtualTerminal,

        # Add a "I ♥ PS" on a line by itself to it's prompt (using ConsoleColors, to keep it safe from PSReadLine)
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$Newline,

        # Add a right-aligned timestamp before the newline (implies Newline)
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$Timestamp,

        # Prevent errors in the prompt from being shown (like the normal PowerShell behavior)
        [Parameter(ValueFromPipelineByPropertyName)]
        [switch]$HideErrors,

        # One or more scriptblocks or PowerLineBlocks you want to use as your new prompt
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        $Prompt,

        # One or more colors you want to use as the prompt background colors
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$Colors,

        # If set, calls Export-PowerLinePrompt
        [Parameter()]
        [Switch]$Save,

        # The Left pointing and Right pointing cap characters are used to cap PowerLine blocks.
        # Set this by passing either a Cap object, or a string with two characters in it. Left, then right, like: 
        #
        # Following the standard PowerLine naming, when the block is left aligned, PowerLine uses the left cap on the end of each block (in the color of the background of the block, and with the background matching the NEXT block). When the block is right aligned, PowerLine uses the right cap on the start of each block, in the color of the background of the block, and with the background set to the color of the previous block.
        # Defaults to: -join [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator", "ReverseColorSeparator"]
        [PoshCode.PowerLine.PowerLineCap]$Cap,

        # The Left pointing and Right pointing separator characters are used when a script-based PowerLine block outputs multiple objects
        # Set this by passing either a Cap object, or a string with two characters in it. Left, then right, like: 
        #
        # Following the standard PowerLine naming, when the block is left aligned, PowerLine uses the left separator between outputs from a PowerLineBlock, and when it is right aligned, PowerLine uses the right separator.
        # Defaults to: -join [PoshCode.Pansies.Entities]::ExtendedCharacters["Separator", "ReverseSeparator"]
        [PoshCode.PowerLine.PowerLineCap]$Separator,

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

        [Parameter(ValueFromPipelineByPropertyName)]
        [AllowEmptyString()]
        [string]$PSReadLineContinuationPromptColor,

        # By default PowerLine caches output based on the prompt's history id
        # That makes if *very* fase if you hit ENTER or Ctrl+C or Ctrl+L repeatedly
        # But if you print the time, it wouldn't change, so you can disable that here
        [switch]$NoCache
    )
    process {
        if ($null -eq $script:OldPrompt) {
            $script:OldPrompt = $function:global:prompt
            $MyInvocation.MyCommand.Module.OnRemove = {
                $function:global:prompt = $script:OldPrompt
            }
        }

        # These switches aren't stored in the config
        $null = $PSBoundParameters.Remove("Save")
        $null = $PSBoundParameters.Remove("Newline")
        $null = $PSBoundParameters.Remove("Timestamp")

        $Configuration = Import-Configuration

        # Upodate the saved PowerLinePrompt with the parameters
        if(!$Configuration.PowerLineConfig) {
            $Configuration.PowerLineConfig = @{}
        }
        $PowerLineConfig = $Configuration.PowerLineConfig | Update-Object $PSBoundParameters

        if($Configuration.ExtendedCharacters) {
            foreach($key in $Configuration.ExtendedCharacters.Keys) {
                [PoshCode.Pansies.Entities]::ExtendedCharacters.$key = $Configuration.ExtendedCharacters.$key
            }
        }

        if($Configuration.EscapeSequences) {
            foreach($key in $Configuration.EscapeSequences.Keys) {
                [PoshCode.Pansies.Entities]::EscapeSequences.$key = $Configuration.EscapeSequences.$key
            }
        }

        if ($Null -eq $PowerLineConfig.FullColor -and $Host.UI.SupportsVirtualTerminal) {
            $PowerLineConfig.FullColor = (Get-Process -Id $global:Pid).MainWindowHandle -ne 0
        }

        # Set the default cap before we cast prompt blocks
        if ($NoBackground) {
            $PowerLineConfig["Cap"] = [PoshCode.PowerLine.State]::DefaultCap = " "
            $PowerLineConfig["Separator"] = [PoshCode.PowerLine.State]::DefaultSeparator = " "
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

                # Set the new Cap and Separator options too
                [PoshCode.PowerLine.State]::DefaultCap = $PowerLineConfig["Cap"] = -join [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator", "ReverseColorSeparator"]
                [PoshCode.PowerLine.State]::DefaultSeparator = $PowerLineConfig["Separator"] = -join [PoshCode.Pansies.Entities]::ExtendedCharacters["Separator", "ReverseSeparator"]

                # [PoshCode.Pansies.Entities]::EnableNerdFonts = $true
            } else  {
                # Use characters that at least work in Consolas and Lucida Console
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ColorSeparator'] = [char]0x258C
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseColorSeparator'] = [char]0x2590
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Separator'] = [char]0x25BA
                [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseSeparator'] = [char]0x25C4
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Branch'] = [char]0x00A7
                [PoshCode.Pansies.Entities]::ExtendedCharacters['Gear'] = [char]0x263C
                # Set the new Cap and Separator options too
                [PoshCode.PowerLine.State]::DefaultCap = $PowerLineConfig["Cap"] = -join [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator", "ReverseColorSeparator"]
                [PoshCode.PowerLine.State]::DefaultSeparator = $PowerLineConfig["Separator"] = -join [PoshCode.Pansies.Entities]::ExtendedCharacters["Separator", "ReverseSeparator"]
            }
        }

        if ($PSBoundParameters.ContainsKey("Cap")) {
            [PoshCode.PowerLine.State]::DefaultCap = $PowerLineConfig["Cap"] = $Cap
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ReverseColorSeparator"] = $Cap.Left
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator"] = $Cap.Right
        } elseif (!$PowerLineConfig.ContainsKey("Cap")) {
            # If there's nothing in the config, then default to Powerline style!
            [PoshCode.PowerLine.State]::DefaultCap = $PowerLineConfig["Cap"] = -join [PoshCode.Pansies.Entities]::ExtendedCharacters["ColorSeparator", "ReverseColorSeparator"]
        } elseif ($PowerLineConfig.ContainsKey("Cap")) {
            [PoshCode.PowerLine.State]::DefaultCap = $PowerLineConfig["Cap"]
        }
        if ($PSBoundParameters.ContainsKey("Separator")) {
            [PoshCode.PowerLine.State]::DefaultSeparator = $PowerLineConfig["Separator"] = $Separator
            [PoshCode.Pansies.Entities]::ExtendedCharacters["ReverseSeparator"] = $Separator.Left
            [PoshCode.Pansies.Entities]::ExtendedCharacters["Separator"] = $Separator.Right
        } elseif (!$PowerLineConfig.ContainsKey("Separator")) {
            # If there's nothing in the config, then default to Powerline style!
            [PoshCode.PowerLine.State]::DefaultSeparator = $PowerLineConfig["Separator"] = -join [PoshCode.Pansies.Entities]::ExtendedCharacters["Separator", "ReverseSeparator"]
        } elseif ($PowerLineConfig.ContainsKey("Separator")) {
            [PoshCode.PowerLine.State]::DefaultSeparator = $PowerLineConfig["Separator"]
        }

        # For Prompt and Colors we want to support modifying the global variable outside this function
        [System.Collections.Generic.List[PoshCode.PowerLine.PowerLineBlock]]$global:Prompt = `
        [PoshCode.PowerLine.PowerLineBlock[]]$PowerLineConfig.Prompt = $(
            if ($PSBoundParameters.ContainsKey("Prompt")) {
                $Local:Prompt
            # They didn't pass anything, and there's nothing set
            } elseif ($global:Prompt.Count -eq 0) {
                # If we found something in config
                if ($PowerLineConfig.Prompt.Count -gt 0) {
                    # If the config is already PowerLineBlock, just use that:
                    if ($PowerLineConfig.Prompt -as [PoshCode.PowerLine.PowerLineBlock[]]) {
                        $PowerLineConfig.Prompt
                    } else {
                        # Try to upgrade by casting through scriptblock
                        [ScriptBlock[]]@($PowerLineConfig.Prompt)
                    }
                } else {
                    # The default PowerLine Prompt
                    [ScriptBlock[]]@(
                        { $MyInvocation.HistoryId }
                        { Get-ShortPath -HomeString "~" -Depth 3 }
                    )
                }
            } else {
                $global:Prompt
            }
        )

        # If they passed in colors, update everything
        if ($PSBoundParameters.ContainsKey("Colors")) {
            SyncColor $Colors
            # Otherwise, if we haven't cached the colors, and there's configured colors, use those
        } elseif (!$global:Prompt.Colors -and !$Script:Colors -and $PowerLineConfig.Colors) {
            SyncColor $PowerLineConfig.Colors
        }

        if ($NoBackground) {
            @($global:Prompt).ForEach({ $_.BackgroundColor = $null })
            $global:Prompt.Colors = $PowerLineConfig.Colors = $Script:Colors = @()
        }

        if($null -eq $PowerLineConfig.DefaultAddIndex) {
            $PowerLineConfig.DefaultAddIndex    = -1
        }

        $Script:PowerLineConfig = $PowerLineConfig

        if($Newline -or $Timestamp) {
            $Script:PowerLineConfig.DefaultAddIndex = $global:Prompt.Count

            # TODO: Update this to PowerLineBlocks
            @(
                if($Timestamp) {
                    "`t"
                    { Get-Elapsed }
                    { Get-Date -format "T" }
                }
                "`n"
                { New-PowerLineBlock { "I $(New-PowerLineBlock -Fg Red3 -EFg White "&hearts;$([char]27)[30m") PS" } -Bg White -EBg Red3 -Fg Black }
            ) | Add-PowerLineBlock

            if (Get-Module PSReadLine) {
                if ($PSBoundParameters.ContainsKey("PSReadLinePromptText")) {
                    Set-PSReadLineOption -PromptText $PSReadLinePromptText
                } else {
                    Set-PSReadLineOption -PromptText @(
                        New-PowerLineBlock -Fg Black -Bg White "I ${Fg:Red3}&hearts;${Fg:Black} PS${Fg:White}${Bg:Clear}&ColorSeparator;"
                        New-PowerLineBlock -Bg Red3 -Fg White "I ${Fg:White}&hearts;${Fg:White} PS${Fg:Red3}${Bg:Clear}&ColorSeparator;"
                    )
                }
            }

            $Script:PowerLineConfig.DefaultAddIndex = @($Global:Prompt).ForEach{ $_.ToString().Trim() }.IndexOf('"`t"')
        } elseif ($PSBoundParameters.ContainsKey("Prompt")) {
            $Script:PowerLineConfig.DefaultAddIndex = -1
        }

        if (Get-Module PSReadLine) {
            $Options = @{}
            if ($PSBoundParameters.ContainsKey("PSReadLinePromptText")) {
                $Options["PromptText"] = $PSReadLinePromptText
            }

            if ($PSBoundParameters.ContainsKey("PSReadLineContinuationPrompt")) {
                $Options["ContinuationPrompt"] = $PSReadLineContinuationPrompt
            }
            if ($PSBoundParameters.ContainsKey("PSReadLineContinuationPromptColor")) {
                $Options["Colors"] = @{
                    ContinuationPrompt = $PSReadLineContinuationPromptColor
                }
            }
            if ($Options) {
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
