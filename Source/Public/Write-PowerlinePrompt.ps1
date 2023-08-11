function Write-PowerlinePrompt {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [switch]$NoCache
    )

    try {
        # Stuff these into static properties in case I want to use them from C#
        [PoshCode.TerminalBlock]::LastSuccess = $global:?
        [PoshCode.TerminalBlock]::LastExitCode = $global:LASTEXITCODE
        $global:LASTEXITCODE = 0

        $PromptErrors = [ordered]@{}

        # PowerLinePrompt Features:
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

        if ($Script:PowerLineConfig.SimpleTransient -and $MyInvocation.HistoryId -eq $Script:LastHistoryId) {
            # if we're transient, and SimpleTransient, just output the last line
            $LastLine = 1 + $Prompt.FindLastIndex([Predicate[PoshCode.TerminalBlock]] { $args[0].Content -eq "NewLine" })
            $local:Prompt = $Prompt.GetRange($LastLine, $Prompt.Count - $LastLine)
        }

        $CacheKey = $Script:LastHistoryId = $MyInvocation.HistoryId
        if ($NoCache -or $Script:PowerLineConfig.NoCache) {
            $CacheKey = $null
        }

        # invoke them all, to find out whether they have content
        $PromptErrors = [ordered]@{}
        for ($b = 0; $b -lt $Prompt.Count; $b++) {
            try {
                # ignore the original output (we'll fetch it from the cache with ToString to handle colors)
                $null = $Prompt[$b].Invoke($CacheKey)
                if ($Prompt[$b].HadErrors) {
                    foreach ($e in $Prompt[$b].Streams.Error) {
                        $PromptErrors.Add("$b { $($Prompt[$b].Content) }", $e)
                    }
                }
            } catch {
                $PromptErrors.Add("$b { $($Prompt[$b].Content) }", $_)
            }
        }

        [string]$PromptErrorString = if (-not $Script:PowerLineConfig.HideErrors) {
            WriteExceptions $PromptErrors
        }

        # Output them all, using the color of adjacent blocks for PowerLine's classic cap "overlap"
        $builder = [System.Text.StringBuilder]::new($PromptErrorString)
        # create the number of lines we need for output up front:
        $extraLineCount = $Prompt.Where{ $_.Content -eq "NewLine" }.Count

        $null = $builder.Append("`n" * $extraLineCount)
        $null = $builder.Append("$([char]27)M" * $extraLineCount)
        $rightAlign = $false
        $EOL = Get-CursorPosition
        # Add-Content -Value "BEFORE $($extraLineCount+1) line prompt: $EOL" -Path $HOME\PowerLine.log
        for ($b = 0; $b -lt $Prompt.Count; $b++) {
            $PreviousNeighbor = $NextNeighbor = $null
            $Block = $Prompt[$b]

            # Your previous neighbor is the previous non-empty block with the same alignment as you
            for ($p = $b - 1; $p -ge 0; $p--){
                $Prev = $Prompt[$p]
                if ($Prev.Content -is [PoshCode.SpecialBlock]) {
                    break;
                } elseif ($Prev.Cache) {
                    $PreviousNeighbor = $Prev
                    break;
                }
            }

            # Your next neighbor is the next non-empty block with the same alignment as you
            for ($n = $b + 1; $n -lt $Prompt.Count; $n++) {
                $Next = $Prompt[$n]
                if ($Next.Content -is [PoshCode.SpecialBlock]) {
                    break;
                } elseif ($Next.Cache) {
                    $NextNeighbor = $Next
                    break;
                }
            }

            # Don't render spacers, if they don't have a real (non-space) neighbors on the "next" side
            if ($Block.Content -in "Spacer" -and (!$NextNeighbor.Cache -or $NextNeighbor.Content -eq "Spacer")) {
                continue
            }

            $null = $builder.Append($Block.ToString($PreviousNeighbor.BackgroundColor, $NextNeighbor.BackgroundColor, $CacheKey))
        }

        # At the end, output everything that's left
        $builder.ToString()
        # Add-Content -Value "return prompt:`n$($Builder.ToString())" -Path $HOME\PowerLine.log
        if ($global:LASTEXITCODE) {
            Write-Warning "LASTEXITCODE set in PowerLinePrompt: $global:LASTEXITCODE"
        }
    } catch {
        Write-Warning "Exception in Write-PowerLinePrompt`n$_"
        "${PWD}>"
    } finally {
        # Put back LASTEXITCODE so you don't have to turn off your prompt when things go wrong
        $global:LASTEXITCODE = [PoshCode.TerminalBlock]::LastExitCode
    }
}
