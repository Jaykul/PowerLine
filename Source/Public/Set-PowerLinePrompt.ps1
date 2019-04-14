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
    [CmdletBinding(DefaultParameterSetName = "PowerLine")]
    param(
        # A script which outputs a string used to update the Window Title each time the prompt is run
        [scriptblock]$Title,

        # Keep the .Net Current Directory in sync with PowerShell's
        [Alias("CurrentDirectory")]
        [switch]$SetCurrentDirectory,

        # If true, set the [PowerLine.Prompt] static members to extended characters from PowerLine fonts
        [Parameter(ParameterSetName = "PowerLine")]
        [switch]$PowerLineFont,

        # If true, set the [PowerLine.Prompt] static members to characters available in Consolas and Courier New
        [Parameter(ParameterSetName = "Reset")]
        [switch]$ResetSeparators,

        # If true, assume full color support, otherwise normalize to 16 ConsoleColor
        [Parameter()]
        [switch]$FullColor,

        # If true, adds ENABLE_VIRTUAL_TERMINAL_PROCESSING to the console output mode. Useful on PowerShell versions that don't restore the console
        [Parameter()]
        [switch]$RestoreVirtualTerminal,

        # Add a "I ♥ PS" on a line by itself to it's prompt (using ConsoleColors, to keep it safe from PSReadLine)
        [switch]$Newline,

        # Add a right-aligned timestamp before the newline (implies Newline)
        [switch]$Timestamp,

        [switch]$HideErrors,

        # One or more scriptblocks you want to use as your new prompt
        [System.Collections.Generic.List[ScriptBlock]]$Prompt,

        # One or more colors you want to use as the prompt background
        [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$Colors,

        # If set, calls Export-PowerLinePrompt
        [Switch]$Save

    )
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

    if ($PowerLineConfig.FullColor -eq $Null -and $Host.UI.SupportsVirtualTerminal) {
        $PowerLineConfig.FullColor = (Get-Process -Id $global:Pid).MainWindowHandle -ne 0
    }

    # For Prompt and Colors we want to support modifying the global variable outside this function
    if($PSBoundParameters.ContainsKey("Prompt")) {
        [System.Collections.Generic.List[ScriptBlock]]$global:Prompt = $Local:Prompt

    } elseif($global:Prompt.Count -eq 0 -and $PowerLineConfig.Prompt.Count -gt 0) {
        [System.Collections.Generic.List[ScriptBlock]]$global:Prompt = [ScriptBlock[]]@($PowerLineConfig.Prompt)

    } elseif($global:Prompt.Count -eq 0) {
        # The default PowerLine Prompt
        [ScriptBlock[]]$PowerLineConfig.Prompt = { $MyInvocation.HistoryId }, { Get-SegmentedPath }
        [System.Collections.Generic.List[ScriptBlock]]$global:Prompt = $PowerLineConfig.Prompt
    }

    # Prefer the existing colors over the saved colors, but not over the colors parameter
    if($PSBoundParameters.ContainsKey("Colors")) {
        InitializeColor $Colors
    } elseif($global:Prompt.Colors) {
        InitializeColor $global:Prompt.Colors
    } elseif($PowerLineConfig.Colors) {
        InitializeColor $PowerLineConfig.Colors
    } else {
        InitializeColor
    }

    if ($ResetSeparators -or ($PSBoundParameters.ContainsKey("PowerLineFont") -and !$PowerLineFont) ) {
        # Use characters that at least work in Consolas
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
                { Get-Date -f "T" }
            }
            { "`n" }
            { New-PromptText { "I $(New-PromptText -Fg Red -EFg White "&hearts;$([char]27)[30m") PS" } -Bg White -EBg Red -Fg Black }
        ) | Add-PowerLineBlock

        $Script:PowerLineConfig.DefaultAddIndex = @($Global:Prompt).ForEach{ $_.ToString().Trim() }.IndexOf('"`t"')
    } elseif ($PSBoundParameters.ContainsKey("Prompt")) {
        $Script:PowerLineConfig.DefaultAddIndex = -1
    }

    # Finally, update the prompt function
    $function:global:prompt = { Write-PowerlinePrompt }
    [PoshCode.Pansies.RgbColor]::ResetConsolePalette()

    # If they asked us to save, or if there's nothing saved yet
    if($Save -or ($PSBoundParameters.Count -and !(Test-Path (Join-Path (Get-StoragePath) Configuration.psd1)))) {
        Export-PowerLinePrompt
    }
}

Set-PowerLinePrompt
