function Write-PowerlinePrompt {
    [CmdletBinding()]
    [OutputType([string])]
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

        $CacheKey = if ($Script:PowerLineConfig.NoCache) {
            [Guid]::NewGuid()
        } else {
            $MyInvocation.HistoryId
        }

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
        $BufferWidth = [Console]::BufferWidth
        $CSI = "$([char]27)["

        # Pre-invoke everything, because then we can use .Cache
        for ($b = 0; $b -lt $Buffer.Count; $b++) {
            $block = $Buffer[$b].Invoke($CacheKey)
        }

        [PoshCode.PowerLine.State]::Alignment = "Left"

        # $LastBackground = $null
        for ($b = 0; $b -lt $Buffer.Count; $b++) {
            $block = $Buffer[$b]

            # Column Separator
            if ($block.Object -eq [PoshCode.PowerLine.Space]::RightAlign) {
                [PoshCode.PowerLine.State]::Alignment = "Right"
                $result += $line + $Csi + "s" # STORE
                $line = ""
            # New Line
            } elseif ($block.Object -eq [PoshCode.PowerLine.Space]::NewLine) {
                if ([PoshCode.PowerLine.State]::Alignment) {
                    [PoshCode.PowerLine.State]::Alignment = "Left"
                    ## This is a VERY simplistic test for escape sequences
                    $lineLength = ($line -replace "\u001B.*?\p{L}").Length
                    # Write-Debug "The buffer is $($BufferWidth) wide, and the line is $($lineLength) long so we're aligning to $($Align)"
                    $result += "$CSI$(1 + $BufferWidth - $lineLength)G"
                }
                $extraLineCount++
                $result += $line + $CSI + "0m`n" # CLEAR
                $line = ""
            # If the cache is null, it won't draw anything
            } elseif ($block.Cache) {
                $Neighbor = $null
                $Direction = if ([PoshCode.PowerLine.State]::Alignment) { -1 } else { +1 }
                $n = $b
                # If this is not a spacer, it should use the color of the next non-empty block
                do {
                    $n += $Direction
                    if ($n -lt 0 -or $n -ge $Buffer.Count) {
                        $Neighbor = $null
                        break;
                    } elseif ($Buffer[$n].Cache) {
                        $Neighbor = $Buffer[$n]
                    }
                } while(!$Neighbor)

                # If this is a spacer, it should not render at all if the next non-empty block is a spacer
                if ($block.Object -eq [PoshCode.PowerLine.Space]::Spacer -and $Neighbor.Object -eq [PoshCode.PowerLine.Space]::Spacer) {
                    continue
                }

                if ($text = $block.ToLine($Neighbor.BackgroundColor, $CacheKey)) {
                    $line += $text
                }

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
            $result += "$CSI$(1 + $BufferWidth - $lineLength)G"
            $line += $CSI + "u" # Recall
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
