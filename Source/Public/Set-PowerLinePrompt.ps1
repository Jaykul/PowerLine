function Set-PowerLinePrompt {
    #.Synopsis
    #   Set the default PowerLine prompt function which uses the $PowerLinePrompt variable
    #.Description
    #   Overwrites the current prompt function with one that uses the PowerLinePrompt variable
    #   Note that this doesn't try to preserve any changes already made to the prompt by modules like ZLocation
    #.Example
    #   Set-PowerLinePrompt -CurrentDirectory
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

        # One or more scriptblocks you want to use as your new prompt
        [List[ScriptBlock]]$Prompt,

        # One or more colors you want to use as the prompt background
        [List[RgbColor]]$Colors

    )
    if ($null -eq $script:OldPrompt) {
        $script:OldPrompt = $function:global:prompt
        $MyInvocation.MyCommand.Module.OnRemove = {
            $function:global:prompt = $script:OldPrompt
        }
    }

    $Local:PowerLinePrompt = Import-Configuration | Update-Object $PSBoundParameters
    if($Local:PowerLinePrompt.ExtendedCharacters) {
        $ExtendedCharacters = [Collections.Generic.Dictionary[String,Char]]::new()
        foreach($key in $Local:PowerLinePrompt.ExtendedCharacters.Keys) {
            $ExtendedCharacters.$key = $Local:PowerLinePrompt.ExtendedCharacters.$key
        }

        [PoshCode.Pansies.Entities]::ExtendedCharacters = $ExtendedCharacters
    }

    if($Local:PowerLinePrompt.EscapeSequences) {
        $EscapeSequences = [Collections.Generic.Dictionary[String,String]]::new()
        foreach($key in $Local:PowerLinePrompt.EscapeSequences.Keys) {
            $EscapeSequences.$key = $Local:PowerLinePrompt.EscapeSequences.$key
        }
        [PoshCode.Pansies.Entities]::EscapeSequences = $EscapeSequences
    }

    if ($Local:PowerLinePrompt.FullColor -eq $Null -and $Host.UI.SupportsVirtualTerminal) {
        $Local:PowerLinePrompt.FullColor = (Get-Process -Id $global:Pid).MainWindowHandle -ne 0
    }

    # If they didn't pass in the prompt, use the existing one
    # NOTE: we know $global:Prompt is set because we set it at import
    if($PSBoundParameters.ContainsKey("Prompt")) {
        # Otherwise, copy the colors onto the new one
        Add-Member -InputObject $Local:Prompt -MemberType NoteProperty -Name Colors -Value $global:Prompt.Colors
        $Local:PowerLinePrompt.Prompt = $Prompt
    }
    if($Local:PowerLinePrompt.Prompt) {
        $global:Prompt = [ScriptBlock[]]$local:PowerLinePrompt.Prompt
    }

    if($PSBoundParameters.ContainsKey("Colors")) {
        $local:PowerLinePrompt.Colors = $Colors
    }
    if($Local:PowerLinePrompt.Colors) {
        InitializeColor $global:Prompt $local:PowerLinePrompt.Colors
    } else {
        $local:PowerLinePrompt.Colors = InitializeColor $global:Prompt -Passthru
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

    $Local:PowerLinePrompt.ExtendedCharacters = [PoshCode.Pansies.Entities]::ExtendedCharacters
    $Local:PowerLinePrompt.EscapeSequences    = [PoshCode.Pansies.Entities]::EscapeSequences
    if($null -eq $Local:PowerLinePrompt.DefaultAddIndex) {
        $Local:PowerLinePrompt.DefaultAddIndex    = -1
    }

    Export-Configuration $Local:PowerLinePrompt

    $Script:PowerLinePrompt = [PSCustomObject]$Local:PowerLinePrompt

    if($Script:PowerLinePrompt.Newline -or $Script:PowerLinePrompt.Timestamp) {
        $Script:PowerLinePrompt.DefaultAddIndex = $Insert = $global:Prompt.Count
        @(
            if($Script:PowerLinePrompt.Timestamp) {
                { "`t" }
                { Get-Elapsed }
                { Get-Date -f "T" }
            }
            { "`n" }
            { New-PromptText {
                "I $(New-PromptText -Fg Red -ErrorForegroundColor White "&hearts;$([char]27)[30m") PS"
              } -BackgroundColor White -ErrorBackgroundColor Red -ForegroundColor Black }
        ) | Add-PowerLineBlock
        $Script:PowerLinePrompt.DefaultAddIndex = $Insert
    }

    $function:global:prompt = $function:script:Prompt
    [PoshCode.Pansies.RgbColor]::ResetConsolePalette()
}

Set-PowerLinePrompt