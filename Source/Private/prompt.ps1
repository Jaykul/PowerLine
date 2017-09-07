function prompt {
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
    $UniqueColorsCount = 0
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
            # Each $buffer gets a color, if it needs one (it's not whitespace)
            $UniqueColorsCount += [bool]$buffer.Where({![string]::IsNullOrWhiteSpace($_.Object) -and $_.BackgroundColor -eq $null -and $_.ForegroundColor -eq $null },1)
            , $buffer
        }
    ).Where( {$_.Object})

    # Based on the number of text blocks, get a color gradient or the user's color choices
    [PoshCode.Pansies.RgbColor[]]$Colors = @()
    if ($PowerLineColors.Count -ge $UniqueColorsCount) {
        $Colors = $PowerLineColors
    } elseif ($PowerLineColors.Count -gt 2) {
        $Colors = $PowerLineColors[0..($PowerLineColors.Count - 3)]
        $Colors += @(Get-Gradient ($PowerLineColors[-2]) ($PowerLineColors[-1]) ($UniqueColorsCount - $Colors.Count) -Flatten)
    } else {
        $Colors = @($PowerLineColors) * $UniqueColorsCount
    }

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
    $result + $line + ([PoshCode.Pansies.Text]@{
        Object          = "$ColorSeparator&Clear;"
        ForegroundColor = $LastBackground
        BackgroundColor = $Host.UI.RawUI.BackgroundColor
    })
}