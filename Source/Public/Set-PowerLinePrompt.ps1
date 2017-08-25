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
    [CmdletBinding(DefaultParameterSetName = "PowerLine")]
    param(
        # A script which outputs a string used to update the Window Title each time the prompt is run
        [scriptblock]$Title,

        # Keep the .Net Current Directory in sync with PowerShell's
        [switch]$CurrentDirectory,

        # If true, set the [PowerLine.Prompt] static members to extended characters from PowerLine fonts
        [Parameter(ParameterSetName = "PowerLine")]
        [switch]$PowerLineFont,

        # If true, set the [PowerLine.Prompt] static members to characters available in Consolas and Courier New
        [Parameter(ParameterSetName = "Reset")]
        [switch]$ResetSeparators,

        # If true, override the default testing for ANSI consoles and force the use of Escape Sequences rather than Write-Host
        [Parameter()]
        [switch]$UseAnsiEscapes = $($Host.UI.SupportsVirtualTerminal -or $Env:ConEmuANSI -eq "ON"),

        # If true, adds ENABLE_VIRTUAL_TERMINAL_PROCESSING to the console output mode. Useful on PowerShell versions that don't restore the console
        [Parameter()]
        [switch]$RestoreVirtualTerminal,

        [switch]$Newline
    )
    if ($null -eq $script:OldPrompt) {
        $script:OldPrompt = $function:global:prompt
        $MyInvocation.MyCommand.Module.OnRemove = {
            $function:global:prompt = $script:OldPrompt
        }
    }

    $Local:PowerLinePrompt = @{
        UseAnsiEscapes         = $UseAnsiEscapes
        RestoreVirtualTerminal = $RestoreVirtualTerminal
    }

    if ($PSBoundParameters.ContainsKey("Title")) {
        $Local:PowerLinePrompt['Title'] = $Title
    }
    if ($PSBoundParameters.ContainsKey("CurrentDirectory")) {
        $Local:PowerLinePrompt['SetCurrentDirectory'] = $CurrentDirectory
    }
    if($Newline) {
        $Script:DefaultAddIndex = $Insert = $Prompt.Count
        @(
            { "`t" }
            { Get-Elapsed }
            { Get-Date -f "T" }
            { "`n" }
            { New-PromptText {
                "I $(New-PromptText -Fg Red -ErrorForegroundColor White "&hearts;$([char]27)[30m") PS"
              } -BackgroundColor White -ErrorBackgroundColor Red -ForegroundColor Black }
        ) | Add-PowerLineBlock
        $Script:DefaultAddIndex = $Insert
    } else {
        $Script:DefaultAddIndex = -1
    }

    $Script:PowerLinePrompt = [PSCustomObject]$Local:PowerLinePrompt

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

    $function:global:prompt = {
        # FIRST, make a note if there was an error in the previous command
        [bool]$script:LastSuccess = $?

        # Then handle PowerLinePrompt Features:
        if ($Script:PowerLinePrompt.Title) {
            try {
                $Host.UI.RawUI.WindowTitle = [System.Management.Automation.LanguagePrimitives]::ConvertTo( (& $Script:PowerLinePrompt.Title), [string] )
            } catch {
                Write-Error "Failed to set Title from scriptblock { $($Script:PowerLinePrompt.Title) }"
            }
        }
        if ($Script:PowerLinePrompt.SetCurrentDirectory) {
            try {
                # Make sure Windows & .Net know where we are
                # They can only handle the FileSystem, and not in .Net Core
                [System.IO.Directory]::SetCurrentDirectory( (Get-Location -PSProvider FileSystem).ProviderPath )
            } catch {
                Write-Error "Failed to set CurrentDirectory to: (Get-Location -PSProvider FileSystem).ProviderPath"
            }
        }
        if ($Script:PowerLinePrompt.RestoreVirtualTerminal) {
            [PoshCode.Pansies.Console.WindowsHelper]::EnableVirtualTerminalProcessing()
        }

        # Evaluate any scriptblocks in the prompt
        $PromptTextCount = 0
        $PromptText = @(
            foreach ($block in $Prompt) {
                [PoshCode.Pansies.Text[]]$buffer = if ($block -is [scriptblock]) {
                    $block = & $block
                    if($block -as [PoshCode.Pansies.Text[]]) {
                        $block
                    } else {
                        [string[]]$block
                    }
                } else {
                    $block
                }
                $PromptTextCount += $buffer.Where( {$_.Object -notin "`n", "`r`n", "`t" -and $_.BackgroundColor -eq $null -and $_.ForegroundColor -eq $null }).Count
                , $buffer
            }
        ).Where( {$_.Object})

        # Based on the number of text blocks, get a color gradient or the user's color choices
        [PoshCode.Pansies.RgbColor[]]$Colors = @()
        if ($PowerLineColors.Count -ge $PromptTextCount) {
            $Colors = $PowerLineColors
        } elseif ($PowerLineColors.Count -gt 2) {
            $Colors = $PowerLineColors[0..($PowerLineColors.Count - 2)]
            $Colors += @(Get-Gradient ($PowerLineColors[-2]) ($PowerLineColors[-1]) ($PromptTextCount - $Colors.Count) -Flatten)
        } else {
            $Colors = @($PowerLineColors) * $PromptTextCount
        }

        # Loop through the text blocks and set colors
        $ColorIndex = 0
        foreach ($block in $PromptText) {
            $ColorUsed = $False
            foreach ($b in @($block)) {
                if ($b.Object -notin "`n", "`r`n", "`t" -and $b.BackgroundColor -eq $null) {
                    $b.BackgroundColor = $Colors[$ColorIndex]
                    $ColorUsed = $True
                }
            }
            $ColorIndex += $ColorUsed

            foreach ($b in @($block)) {
                if ($b.BackgroundColor -ne $null -and $b.ForegroundColor -eq $null) {
                    # Invert the foreground and push it to nearly black/white
                    $Foreground = $b.BackgroundColor.ToHunterLab()
                    $Foreground.L = (10, 90)[(100 - $Foreground.L) -gt 50]
                    $b.ForegroundColor = $Foreground
                }
            }
        }

        ## Finally, unroll all the output and join into one string (using separators and spacing)
        $Buffer = $PromptText | % { $_ }
        $line = ""
        $result = ""
        $RightAligned = $False
        $BufferWidth = [Console]::BufferWidth
        $ColorSeparator = "&ColorSeparator;"
        $Separator = "&Separator;"
        $LastBackground = $null
        for ($b = 0; $b -lt $Buffer.Count; $b++) {
            $block = $Buffer[$b]
            $string = $block.ToString()
            #Write-Debug "STEP $b of $($Buffer.Count) [$(($String -replace "\u001B.*?\p{L}").Length)] $($String -replace "\u001B.*?\p{L}" -replace "`n","{newline}" -replace "`t","{tab}")"

            ## This adds support for `t to split into (2) columns:
            if ($string -eq "`t") {
                if($LastBackground) {
                    ## Before the (column) break, add a cap
                    #Write-Debug "Pre column-break, add a $LastBackground cap"
                    $line += [PoshCode.Pansies.Text]@{
                        Object          = "$ColorSeparator "
                        ForegroundColor = $LastBackground
                        BackgroundColor = $Host.UI.RawUI.BackgroundColor
                    }
                }
                $result += $line
                $line = ""
                $RightAligned = $True
                $ColorSeparator = "&ReverseColorSeparator;"
                $Separator = "&ReverseSeparator;"
                $LastBackground = $Host.UI.RawUI.BackgroundColor
            } elseif ($string -in "`n", "`r`n") {
                if($RightAligned) {
                    ## This is a VERY simplistic test for escape sequences
                    $lineLength = ($line -replace "\u001B.*?\p{L}").Length
                    $Align = $BufferWidth - $lineLength
                    #Write-Debug "The buffer is $($BufferWidth) wide, and the line is $($lineLength) long so we're aligning to $($Align)"
                    $result += [PoshCode.Pansies.Text]::new("&Esc;$($Align)G ")
                } else {
                    $line += [PoshCode.Pansies.Text]@{
                        Object          = "$ColorSeparator"
                        ForegroundColor = $LastBackground
                        BackgroundColor = $Host.UI.RawUI.BackgroundColor
                    }
                }
                $result += $line + "`n"
                $line = ""
                $RightAligned = $False
                $ColorSeparator = "&ColorSeparator;"
                $Separator = "&Separator;"
                $LastBackground = $null
            } elseif($string) {
                ## If the output is just color sequences, toss it
                if(($String -replace "\u001B.*?\p{L}").Length -eq 0) {
                    #Write-Debug "Skip empty output, staying $LastBackground"
                    continue
                }
                if($LastBackground -or $RightAligned) {
                    $line += if($block.BackgroundColor -ne $LastBackground) {
                        [PoshCode.Pansies.Text]@{
                            Object          = $ColorSeparator
                            ForegroundColor = ($LastBackground, $block.BackgroundColor)[$RightAligned]
                            BackgroundColor = ($block.BackgroundColor, $LastBackground)[$RightAligned]
                        }
                    } else {
                        [PoshCode.Pansies.Text]@{
                            Object          = $Separator
                            BackgroundColor = $block.BackgroundColor
                            ForegroundColor = $block.ForegroundColor
                        }
                    }
                }
                $line += $string
                $LastBackground = $block.BackgroundColor
                #Write-Debug "Normal output ($($string -replace "\u001B.*?\p{L}")) ($($($string -replace "\u001B.*?\p{L}").Length)) on $LastBackground"
            }
        }
        $result + $line + ([PoshCode.Pansies.Text]@{
            Object          = "$ColorSeparator&Clear;"
            ForegroundColor = $LastBackground
            BackgroundColor = $Host.UI.RawUI.BackgroundColor
        })
    }
}