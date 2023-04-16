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

        #PowerLinePrompt Features:
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

        $CacheKey = if ($NoCache) {
            $null
        } else {
            $MyInvocation.HistoryId
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

        # Output them all, using the color of adjacent blocks for PowerLine's classic cap "overlap"
        $builder = [System.Text.StringBuilder]::new()
        for ($b = 0; $b -lt $Prompt.Count; $b++) {
            $Neighbor = $null
            $Block = $Prompt[$b]

            $n = $b
            # Your neighbor is the next non-empty block with the same alignment as you
            while (++$n -lt $Prompt.Count -and $Block.Alignment -eq $Prompt[$n].Alignment) {
                if ($Prompt[$n].Cache) {
                    $Neighbor = $Prompt[$n]
                    break;
                }
            }

            # Don't render spacers, if they don't have a real (non-space) neighbors
            if ($Block.Content -eq "Spacer" -and (!$Neighbor.Cache -or $Neighbor.Content -eq "Spacer")) {
                continue
            }

            $null = $builder.Append($Block.ToString($true, $Neighbor.BackgroundColor, $CacheKey))
        }
        $result = $builder.ToString()
        # This is the fastest way to count lines in PowerShell.
        $extraLineCount = $result.Split("`n").Count

        [string]$PromptErrorString = if (-not $Script:PowerLineConfig.HideErrors) {
            WriteExceptions $PromptErrors
        }

        # At the end, output everything as one single string
        # create the number of lines we need for output up front:
        ("`n" * $extraLineCount) + ("$([char]27)M" * $extraLineCount) + $PromptErrorString + $result
        if ($global:LASTEXITCODE) {
            Write-Warning "LASTEXITCODE set in PowerLinePrompt: $global:LASTEXITCODE"
        }
    } catch {
        Write-Warning "Exception in PowerLinePrompt`n$_"
        "${PWD}>"
    } finally {
        # Put back LASTEXITCODE so you don't have to turn off your prompt when things go wrong
        $global:LASTEXITCODE = [PoshCode.TerminalBlock]::LastExitCode
    }
}
