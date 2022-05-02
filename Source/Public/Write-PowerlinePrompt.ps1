function Write-PowerlinePrompt {
    [CmdletBinding()]
    param()

    try {
        # FIRST, make a note if there was an error in the previous command
        [bool]$script:LastSuccess = $?
        $PromptErrors = [ordered]@{}
        # When someone sets $Prompt, they loose the colors.
        # To fix that, we cache the colors whenever we get a chance
        # And if it's not set, we re-initialize from the cache
        SyncColor

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
            [PoshCode.Pansies.NativeMethods]::EnableVirtualTerminalProcessing()
        }

        # Evaluate all the scriptblocks in $prompt
        $UniqueColorsCount = 0
        $PromptText = @(
            for ($index = 0; $index -lt $Prompt.Count; $index++) {
                $block = $Global:Prompt[$index]
                try {
                    $outputBlock = . {
                        [CmdletBinding()]param()
                        & $block
                    } -ErrorVariable logging
                    $buffer = $(
                        if($outputBlock -as [PoshCode.Pansies.Text[]]) {
                            [PoshCode.Pansies.Text[]]$outputBlock
                        } else {
                            [PoshCode.Pansies.Text[]][string[]]$outputBlock
                        }
                    ).Where{ ![string]::IsNullOrEmpty($_.Object) }
                    # Each $buffer gets a color, if it needs one (it's not whitespace)
                    $UniqueColorsCount += [bool]$buffer.Where({ !([string]::IsNullOrWhiteSpace($_.Object)) -and !$_.BackgroundColor }, 1)
                    , $buffer

                    # Capture errors from blocks. We'll find a way to display them...
                    if ($logging) {
                        $PromptErrors.Add("$index {$block}", $logging)
                    }
                } catch {
                    $PromptErrors.Add("$index {$block}", $_)
                }
            }
        ).Where{ $_.Object }

        # Based on the number of text blocks, make up colors if we need to...
        [PoshCode.Pansies.RgbColor[]]$ActualColors = @(
            if ($Script:Colors.Count -ge $UniqueColorsCount) {
                $Script:Colors
            } elseif ($Script:Colors.Count -eq 2) {
                Get-Gradient ($Script:Colors[0]) ($Script:Colors[1]) -Count $UniqueColorsCount -Flatten
            } else {
                $Script:Colors * ([Math]::Ceiling($UniqueColorsCount/$Script:Colors.Count))
            }
        )

        # Loop through the text blocks and set colors
        $ColorIndex = 0
        foreach ($block in $PromptText) {
            $ColorUsed = $False
            foreach ($b in @($block)) {
                if (![string]::IsNullOrWhiteSpace($b.Object) -and $null -eq $b.BackgroundColor) {
                    $b.BackgroundColor = $ActualColors[$ColorIndex]
                    $ColorUsed = $True
                }
            }
            $ColorIndex += $ColorUsed

            foreach ($b in @($block)) {
                if ($null -ne $b.BackgroundColor -and $null -eq $b.ForegroundColor) {
                    if ($Script:PowerLineConfig.FullColor) {
                        $b.ForegroundColor = Get-Complement $b.BackgroundColor -ForceContrast
                    } else {
                        $b.BackgroundColor, $b.ForegroundColor = Get-Complement $b.BackgroundColor -ConsoleColor -Passthru
                    }
                }
            }
        }

        ## Finally, unroll all the output and join into one string (using separators and spacing)
        $Buffer = $PromptText | ForEach-Object { $_ }
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
            # Write-Debug "STEP $b of $($Buffer.Count) [$(($String -replace "\u001B.*?\p{L}").Length)] $($String -replace "\u001B.*?\p{L}" -replace "`n","{newline}" -replace "`t","{tab}")"

            ## Allow `t to split into (2) columns:
            if ($string -eq "`t") {
                if ($LastBackground) {
                    ## Before the (column) break, add a cap
                    #Write-Debug "Pre column-break, add a $LastBackground cap"
                    $line += [PoshCode.Pansies.Text]@{
                        Object          = "&Esc;49m$ColorSeparator&Clear;&Store;"
                        ForegroundColor = $LastBackground
                        BackgroundColor = $null # $Host.UI.RawUI.BackgroundColor
                    }
                }
                $result += $line
                $line = ""
                $RightAligned = $True
                $ColorSeparator = "&ReverseColorSeparator;"
                $Separator = "&ReverseSeparator;"
                $LastBackground = $null
            ## Allow `n to create multi-line prompts
            } elseif ($string -in "`n", "`r`n") {
                if ($RightAligned) {
                    ## This is a VERY simplistic test for escape sequences
                    $lineLength = ($line -replace "\u001B.*?\p{L}").Length
                    $Align = "$([char]27)[$(1 + $BufferWidth - $lineLength)G"
                    Write-Debug "The buffer is $($BufferWidth) wide, and the line is $($lineLength) long so we're aligning to $($Align)"
                    $result += [PoshCode.Pansies.Text]::new("&Esc;$($Align)")
                    $RightAligned = $False
                } else {
                    $line += [PoshCode.Pansies.Text]@{
                        Object          = $ColorSeparator
                        ForegroundColor = $LastBackground
                        BackgroundColor = if ($Host.UI.RawUI.BackgroundColor -ge 0) { $Host.UI.RawUI.BackgroundColor } else { $null }
                    }
                }
                $extraLineCount++
                $result += $line + [PoshCode.Pansies.Text]::new("&Clear;`n")
                $line = ""
                $ColorSeparator = "&ColorSeparator;"
                $Separator = "&Separator;"
                $LastBackground = $null
            } elseif ($String -eq " ") {
                if ($LastBackground -or $RightAligned) {
                    $line +=
                    if ($RightAligned -and -not $LastBackground) {
                        [PoshCode.Pansies.Text]@{
                            Object          = "&Esc;49m$ColorSeparator"
                            ForegroundColor = ($LastBackground, $block.BackgroundColor)[$RightAligned]
                            BackgroundColor = $null
                        }
                    } elseif ($block.BackgroundColor -ne $LastBackground) {
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
                # A space turns into just a pair of separators in the background color...
                # $line += $string
                $LastBackground = $block.BackgroundColor
                #Write-Debug "Normal output ($($string -replace "\u001B.*?\p{L}")) ($($($string -replace "\u001B.*?\p{L}").Length)) on $LastBackground"
            } elseif (![string]::IsNullOrWhiteSpace($string)) {
                ## If the output is just color sequences, toss it
                if(($String -replace "\u001B.*?\p{L}").Length -eq 0) {
                    #Write-Debug "Skip empty output, staying $LastBackground"
                    continue
                }
                if($LastBackground -or $RightAligned) {
                    $line +=
                        if ($RightAligned -and -not $LastBackground) {
                            [PoshCode.Pansies.Text]@{
                                Object          = "&Esc;49m$ColorSeparator"
                                ForegroundColor = ($LastBackground, $block.BackgroundColor)[$RightAligned]
                                BackgroundColor = $null
                            }
                        } elseif($block.BackgroundColor -ne $LastBackground) {
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

        [string]$PromptErrorString = if (-not $Script:PowerLineConfig.HideErrors) {
            WriteExceptions $PromptErrors
        }

        # With the latest PSReadLine, we can support ending with a right-aligned block...
        if ($RightAligned) {
            ## This is a VERY simplistic test for escape sequences
            $lineLength = ($line -replace "\u001B.*?\p{L}").Length
            #Write-Debug "The buffer is $($BufferWidth) wide, and the line is $($lineLength) long"
            $Align = "$([char]27)[$(1 + $BufferWidth - $lineLength)G"
            $result += [PoshCode.Pansies.Text]::new("$([char]27)[$Align")
            $RightAligned = $False
            $line += [PoshCode.Pansies.Text]::new("&Recall;")
        } else {
            $line += ([PoshCode.Pansies.Text]@{
                Object          = "$([char]27)[49m$ColorSeparator&Clear;"
                ForegroundColor = $LastBackground
            })
        }

        # At the end, output everything as one single string
        # create the number of lines we need for output up front:
        ("`n" * $extraLineCount) + ("$([char]27)M" * $extraLineCount) +
        $PromptErrorString + $result + $line
    } catch {
        Write-Warning "Exception in PowerLinePrompt`n$_"
        "${PWD}>"
    }
}
