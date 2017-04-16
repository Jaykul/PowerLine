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
    #   Set-PowerLinePrompt -UseAnsiEscapes
    #
    #   Sets the powerline prompt and forces the use of ANSI escape sequences in the string output (rather than Write-Host) to change colors, regardless of what we're able to detect about the console.
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
        [switch]$ResetSeparators,

        # If true, override the default testing for ANSI consoles and force the use of Escape Sequences rather than Write-Host
        [Parameter()]
        [switch]$UseAnsiEscapes = $($Host.UI.SupportsVirtualTerminal -or $Env:ConEmuANSI -eq "ON"),

        # If true, adds ENABLE_VIRTUAL_TERMINAL_PROCESSING to the console output mode. Useful on PowerShell versions that don't restore the console
        [Parameter()]
        [switch]$RestoreVirtualTerminal
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

    $global:PowerLinePrompt.UseAnsiEscapes = $UseAnsiEscapes
    $global:PowerLinePrompt.RestoreVirtualTerminal = $RestoreVirtualTerminal


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
        [PowerLine.Prompt]::Branch   = [char]0xE0A0
        [PowerLine.Prompt]::Gear     = [char]0x26EF
    }

    $function:global:prompt =  {

        # FIRST, make a note if there was an error in the previous command
        [bool]$script:LastSuccess = $?

        try {
            if($global:PowerLinePrompt.Title) {
                $Host.UI.RawUI.WindowTitle = [System.Management.Automation.LanguagePrimitives]::ConvertTo( (& $global:PowerLinePrompt.Title), [string] )
            }
            if($global:PowerLinePrompt.SetCurrentDirectory) {
                # Make sure Windows & .Net know where we are
                # They can only handle the FileSystem, and not in .Net Core
                [System.IO.Directory]::SetCurrentDirectory( (Get-Location -PSProvider FileSystem).ProviderPath )
            }
        } catch {}

        if ($global:PowerLinePrompt.RestoreVirtualTerminal) {
                [PowerLine.ConsoleMode]::RestoreVirtualTerminal()
        }
        $global:PowerLinePrompt.ToString($Host.UI.RawUI.BufferSize.Width)
    }
}