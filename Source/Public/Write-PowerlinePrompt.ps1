function Write-PowerlinePrompt {
    [CmdletBinding()]
    param()

    try {
        # FIRST, make a note if there was an error in the previous command
        [PoshCode.PowerLine.State]::LastSuccess = $?
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
        $PromptText = @($Prompt)

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
                if (!$b.BackgroundColor) {
                    if ($b.Object -isnot [PoshCode.PowerLine.Space]) {
                        $b.BackgroundColor = $ActualColors[$ColorIndex]
                        $ColorUsed = $True
                    }
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
        # $LastBackground = $null
        for ($b = 0; $b -lt $Buffer.Count; $b++) {
            $block = $Buffer[$b]
            $OtherColor = @(
                if ($b -lt ($Buffer.Count - 2)) { $Buffer[$b + 1].BackgroundColor } else { $null }
                if ($b -gt 0) { $Buffer[$b - 1].BackgroundColor } else { $null }
            )

            # Write-Debug "STEP $b of $($Buffer.Count) [$(($String -replace "\u001B.*?\p{L}").Length)] $($String -replace "\u001B.*?\p{L}" -replace "`n","{newline}" -replace "`t","{tab}")"
            ## Allow `t to split into (2) columns:
            if ($block.Object -eq [PoshCode.PowerLine.Space]::RightAlign) {
                $result += $line + [PoshCode.Pansies.Text]::new("&Store;")
                $line = ""
                [PoshCode.PowerLine.State]::Alignment = "Right"
            ## Allow `n to create multi-line prompts
            } elseif ($block.Object -eq [PoshCode.PowerLine.Space]::NewLine) {
                if ([PoshCode.PowerLine.State]::Alignment) {
                    ## This is a VERY simplistic test for escape sequences
                    $lineLength = ($line -replace "\u001B.*?\p{L}").Length
                    # Write-Debug "The buffer is $($BufferWidth) wide, and the line is $($lineLength) long so we're aligning to $($Align)"
                    $result += [PoshCode.Pansies.Text]::new("&Esc;$(1 + $BufferWidth - $lineLength)G")
                    [PoshCode.PowerLine.State]::Alignment = "Left"
                }
                $extraLineCount++
                $result += $line + [PoshCode.Pansies.Text]::new("&Clear;`n")
                $line = ""
            } elseif ($block.Object -eq [PoshCode.PowerLine.Space]::Spacer) {
                $line += ([PoshCode.Pansies.Text]@{
                    Object          = "&Esc;7m&ColorSeparator;&Esc;27m"
                    ForegroundColor = $OtherColor[[PoshCode.PowerLine.State]::Alignment]
                })
                # Write-Debug "Spacer output $($OtherColor[![PoshCode.PowerLine.State]::Alignment]) and $($OtherColor[[PoshCode.PowerLine.State]::Alignment])"
            } else {
                # ## If the output is just color sequences, toss it
                # if (($String -replace "\u001B.*?\p{L}").Length -eq 0) {
                #     #Write-Debug "Skip empty output, staying $LastBackground"
                #     continue
                # }
                $line += $block.ToLine($OtherColor[[PoshCode.PowerLine.State]::Alignment])
                #Write-Debug "Normal output ($($string -replace "\u001B.*?\p{L}")) ($($($string -replace "\u001B.*?\p{L}").Length)) on $LastBackground"
            }
        }

        [string]$PromptErrorString = if (-not $Script:PowerLineConfig.HideErrors) {
            WriteExceptions $PromptErrors
        }

        # With the latest PSReadLine, we can support ending with a right-aligned block...
        if ([PoshCode.PowerLine.State]::Alignment) {
            ## This is a VERY simplistic test for escape sequences
            $lineLength = ($line -replace "\u001B.*?\p{L}").Length
            #Write-Debug "The buffer is $($BufferWidth) wide, and the line is $($lineLength) long"
            $result += [PoshCode.Pansies.Text]::new("&Esc;$(1 + $BufferWidth - $lineLength)G")
            $line += [PoshCode.Pansies.Text]::new("&Recall;")
            [PoshCode.PowerLine.State]::Alignment = "Left"
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
