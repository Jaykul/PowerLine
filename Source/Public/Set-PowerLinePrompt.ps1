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
    #   Set-PowerLinePrompt -PowerLineFont
    #
    #   Sets the powerline prompt using the actual PowerLine font characters, and ensuring that we're using the default characters. Note that you can still change the characters used to separate blocks in the PowerLine output after running this, by setting the static members of [PowerLine.Prompt] like Separator and ColorSeparator...
    #.Example
    #   Set-PowerLinePrompt -ResetSeparators
    #
    #   Sets the powerline prompt and forces the use of "safe" separator characters. You can still change the characters used to separate blocks in the PowerLine output after running this, by setting the static members of [PowerLine.Prompt] like Separator and ColorSeparator...
    #.Example
    #   Set-PowerLinePrompt -FullColor
    #
    #   Sets the powerline prompt and forces the assumption of full RGB color support instead of 16 color
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

        # If true, set the [PowerLine.Prompt] static members to extended characters from PowerLine fonts
        [Parameter(ParameterSetName = "PowerLine", ValueFromPipelineByPropertyName)]
        [switch]$PowerLineFont,

        # If true, set the [PowerLine.Prompt] static members to characters available in Consolas and Courier New
        [Parameter(ParameterSetName = "Reset")]
        [switch]$ResetSeparators,

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

        # One or more scriptblocks you want to use as your new prompt
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [System.Collections.Generic.List[PoshCode.PowerLine.Block]]$Prompt,

        # One or more colors you want to use as the prompt background
        [Parameter(Position = 1, ValueFromPipelineByPropertyName)]
        [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$Colors,

        # If set, calls Export-PowerLinePrompt
        [Parameter()]
        [Switch]$Save,

        # A hashtable of extended characters you can use in PowerLine output (or any PANSIES output) with HTML entity syntax like "&hearts;". By default you have the HTML named entities plus the Branch (), Lock (), Gear (⛯) and Power (⚡) icons. You can add any characters you wish, but to change the Powerline theme, you need to specify these four keys using matching pairs:
        #
        # @{
        #    "ColorSeparator" = ""
        #    "ReverseColorSeparator" = ""
        #    "Separator" = ""
        #    "ReverseSeparator" = ""
        # }
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("ExtendedCharacters")]
        [hashtable]$PowerLineCharacters,

        # When there's a parse error, PSReadLine changes a part of the prompt red, but it assumes the default prompt is just foreground color
        # You can use this option to override the character, OR to specify BOTH the normal and error strings.
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

        # For Prompt and Colors we want to support modifying the global variable outside this function
        if($PSBoundParameters.ContainsKey("Prompt")) {
            [System.Collections.Generic.List[PoshCode.PowerLine.Block]]$global:Prompt = $Local:Prompt

        } elseif($global:Prompt.Count -eq 0 -and $PowerLineConfig.Prompt.Count -gt 0) {
            [System.Collections.Generic.List[PoshCode.PowerLine.Block]]$global:Prompt = [PoshCode.PowerLine.Block[]][ScriptBlock[]]@($PowerLineConfig.Prompt)

        } elseif($global:Prompt.Count -eq 0) {
            # The default PowerLine Prompt
            [ScriptBlock[]]$PowerLineConfig.Prompt = { $MyInvocation.HistoryId }, { Get-ShortPath -HomeString "~" -Depth 3 }
            [System.Collections.Generic.List[PoshCode.PowerLine.Block]]$global:Prompt = [PoshCode.PowerLine.Block[]]$PowerLineConfig.Prompt
        }

        # If they passed in colors, update everything
        if ($PSBoundParameters.ContainsKey("Colors")) {
            SyncColor $Colors
        # Otherwise, if we haven't cached the colors, and there's configured colors, use those
        } elseif (!$global:Prompt.Colors -and !$Script:Colors -and $PowerLineConfig.Colors) {
            SyncColor $PowerLineConfig.Colors
        }

        if ($ResetSeparators -or ($PSBoundParameters.ContainsKey("PowerLineFont") -and !$PowerLineFont) ) {
            # Use characters that at least work in Consolas and Lucida Console
            [PoshCode.Pansies.Entities]::ExtendedCharacters['ColorSeparator'] = [char]0x258C
            [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseColorSeparator'] = [char]0x2590
            [PoshCode.Pansies.Entities]::ExtendedCharacters['Separator'] = [char]0x25BA
            [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseSeparator'] = [char]0x25C4
            [PoshCode.Pansies.Entities]::ExtendedCharacters['Branch'] = [char]0x00A7
            [PoshCode.Pansies.Entities]::ExtendedCharacters['Gear'] = [char]0x263C
        }
        if ($PowerLineFont) {
            # Make sure we're using the PowerLine custom use extended characters:
            [PoshCode.Pansies.Entities]::ExtendedCharacters['ColorSeparator'] = [char]0xe0b0
            [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseColorSeparator'] = [char]0xe0b2
            [PoshCode.Pansies.Entities]::ExtendedCharacters['Separator'] = [char]0xe0b1
            [PoshCode.Pansies.Entities]::ExtendedCharacters['ReverseSeparator'] = [char]0xe0b3
            [PoshCode.Pansies.Entities]::ExtendedCharacters['Branch'] = [char]0xE0A0
            [PoshCode.Pansies.Entities]::ExtendedCharacters['Gear'] = [char]0x26EF
        }
        if ($PowerLineCharacters) {
            foreach ($key in $PowerLineCharacters.Keys) {
                [PoshCode.Pansies.Entities]::ExtendedCharacters["$key"] = $PowerLineCharacters[$key].ToString()
            }
        }

        if($null -eq $PowerLineConfig.DefaultAddIndex) {
            $PowerLineConfig.DefaultAddIndex    = -1
        }

        $Script:PowerLineConfig = $PowerLineConfig

        if($Newline -or $Timestamp) {
            $Script:PowerLineConfig.DefaultAddIndex = $global:Prompt.Count

            @(
                if($Timestamp) {
                    { "`t" }
                    { Get-Elapsed }
                    { Get-Date -format "T" }
                }
                { "`n" }
                { New-PromptText { "I $(New-PromptText -Fg Red3 -EFg White "&hearts;$([char]27)[30m") PS" } -Bg White -EBg Red3 -Fg Black }
            ) | Add-PowerLineBlock

            if (Get-Module PSReadLine) {
                if ($PSBoundParameters.ContainsKey("PSReadLinePromptText")) {
                    Set-PSReadLineOption -PromptText $PSReadLinePromptText
                } else {
                    Set-PSReadLineOption -PromptText @(
                        New-PromptText -Fg Black -Bg White "I ${Fg:Red3}&hearts;${Fg:Black} PS${Fg:White}${Bg:Clear}&ColorSeparator;"
                        New-PromptText -Bg Red3 -Fg White "I ${Fg:White}&hearts;${Fg:White} PS${Fg:Red3}${Bg:Clear}&ColorSeparator;"
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
