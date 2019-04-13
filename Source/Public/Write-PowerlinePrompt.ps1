function Write-PowerlinePrompt {
    [CmdletBinding()]
    param()

    try {
        # FIRST, make a note if there was an error in the previous command
        [bool]$script:LastSuccess = $?
        $PromptErrors = [ordered]@{}

        # Then handle PowerLinePrompt Features:
        if ($Script:PowerLineConfig.Title) {
            try {
                $Host.UI.RawUI.WindowTitle = [System.Management.Automation.LanguagePrimitives]::ConvertTo( (& $Script:PowerLineConfig.Title), [string] )
            } catch {
                $PromptErrors.Add("0 {$($Script:PowerLineConfig.Title)}", $_)
                Write-Error "Failed to set Title from scriptblock { $($Script:PowerLineConfig.Title) }"
            }
        }
        if ($Script:PowerLineConfig.SetCurrentDirectory) {
            try {
                # Make sure Windows & .Net know where we are
                # They can only handle the FileSystem, and not in .Net Core
                [System.IO.Directory]::SetCurrentDirectory( (Get-Location -PSProvider FileSystem).ProviderPath )
            } catch {
                $PromptErrors.Add("0 { SetCurrentDirectory }", $_)
                Write-Error "Failed to set CurrentDirectory to: (Get-Location -PSProvider FileSystem).ProviderPath"
            }
        }
        if ($Script:PowerLineConfig.RestoreVirtualTerminal -and (-not $IsLinux -and -not $IsMacOS)) {
            [PoshCode.Pansies.Console.WindowsHelper]::EnableVirtualTerminalProcessing()
        }

        # Evaluate all the scriptblocks in $prompt
        $UniqueColorsCount = 0
        $PromptText = @(
            for($b = 0; $b -lt $Prompt.Count; $b++) {
                $block = $Global:Prompt[$b]
                try {
                    $block = & $block
                    $buffer = $(
                        if($block -as [PoshCode.Pansies.Text[]]) {
                            [PoshCode.Pansies.Text[]]$block
                        } else {
                            [PoshCode.Pansies.Text[]][string[]]$block
                        }
                    ).Where{ ![string]::IsNullOrEmpty($_.Object) }

                    # Each $buffer gets a color, if it needs one (it's not whitespace)
                    $UniqueColorsCount += [bool]$buffer.Where({![string]::IsNullOrWhiteSpace($_.Object) -and $_.BackgroundColor -eq $null -and $_.ForegroundColor -eq $null }, 1)
                    , $buffer
                # Capture errors from blocks. We'll find a way to display them...
                } catch {
                    $PromptErrors.Add("$b {$block}", $_)
                }
            }
        ).Where{ $_.Object }

        # When someone sets $Prompt, they loose the colors.
        # To fix that, we cache the colors whenever we get a chance
        # And if it's not set, we re-initialize from the cache
        if(!$Global:Prompt.Colors) {
            InitializeColor
        }
        # Based on the number of text blocks, get a color gradient or the user's color choices
        [PoshCode.Pansies.RgbColor[]]$Colors = @(
            if ($Global:Prompt.Colors.Count -ge $UniqueColorsCount) {
                $Global:Prompt.Colors
            } elseif ($Global:Prompt.Colors.Count -eq 2) {
                Get-Gradient ($Global:Prompt.Colors[0]) ($Global:Prompt.Colors[1]) -Count $UniqueColorsCount -Flatten
            } else {
                $Global:Prompt.Colors * ([Math]::Ceiling($UniqueColorsCount/$Global:Prompt.Colors.Count))
            }
        )

        # Loop through the text blocks and set colors
        $ColorIndex = 0
        foreach ($block in $PromptText) {
            $ColorUsed = $False
            foreach ($b in @($block)) {
                if (![string]::IsNullOrWhiteSpace($b.Object) -and $b.BackgroundColor -eq $null) {
                    $b.BackgroundColor = $Colors[$ColorIndex]
                    $ColorUsed = $True
                }
            }
            $ColorIndex += $ColorUsed

            foreach ($b in @($block)) {
                if ($b.BackgroundColor -ne $null -and $b.ForegroundColor -eq $null) {
                    if($Script:PowerLineConfig.FullColor) {
                        $b.ForegroundColor = Get-Complement $b.BackgroundColor -ForceContrast
                    } else {
                        $b.BackgroundColor, $b.ForegroundColor = Get-Complement $b.BackgroundColor -ConsoleColor -Passthru
                    }
                }
            }
        }

        ## Finally, unroll all the output and join into one string (using separators and spacing)
        $Buffer = $PromptText | % { $_ }
        $extraLineCount = 0
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

            ## Allow `t to split into (2) columns:
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
            ## Allow `n to create multi-line prompts
            } elseif ($string -in "`n", "`r`n") {
                if($RightAligned) {
                    ## This is a VERY simplistic test for escape sequences
                    $lineLength = ($line -replace "\u001B.*?\p{L}").Length
                    $Align = $BufferWidth - $lineLength
                    #Write-Debug "The buffer is $($BufferWidth) wide, and the line is $($lineLength) long so we're aligning to $($Align)"
                    $result += [PoshCode.Pansies.Text]::new("&Esc;$($Align)G ")
                    $RightAligned = $False
                } else {
                    $line += [PoshCode.Pansies.Text]@{
                        Object          = "$ColorSeparator"
                        ForegroundColor = $LastBackground
                        BackgroundColor = $Host.UI.RawUI.BackgroundColor
                    }
                }
                $extraLineCount++
                $result += $line + "`n"
                $line = ""
                $ColorSeparator = "&ColorSeparator;"
                $Separator = "&Separator;"
                $LastBackground = $null
            } elseif(![string]::IsNullOrWhiteSpace($string)) {
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

        [string]$PromptErrorString = if ($Script:PowerLineConfig.HideErrors) {
            WriteExceptions $PromptErrors
        }
        # At the end, output everything as one single string
        # create the number of lines we need for output up front:
        ("`n" * $extraLineCount) + ("`eM" * $extraLineCount) +
        $PromptErrorString + $result + $line + ([PoshCode.Pansies.Text]@{
            Object          = "$ColorSeparator&Clear;"
            ForegroundColor = $LastBackground
            # BackgroundColor = $Host.UI.RawUI.BackgroundColor
        })
    } catch {
        Write-Warning "Exception in PowerLinePrompt`n$_"
        "${PWD}>"
    }
}