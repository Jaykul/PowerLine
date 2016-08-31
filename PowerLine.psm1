#!/usr/bin/env powershell
using namespace System.Collections.Generic

class PowerLineBlock {
    [Nullable[ConsoleColor]]$BackgroundColor
    [Nullable[ConsoleColor]]$ForegroundColor
    [Object]$Content
    [bool]$Clear = $false

    PowerLineBlock() {}

    PowerLineBlock([hashtable]$values) {
        foreach($key in $values.Keys) {
            if("bg" -eq $key -or "BackgroundColor" -match "^$key") {
                $this.BackgroundColor = $values.$key
            }
            elseif("fg" -eq $key -or "ForegroundColor" -match "^$key") {
                $this.ForegroundColor = $values.$key
            }
            elseif("fg" -eq $key -or "ForegroundColor" -match "^$key") {
                $this.ForegroundColor = $values.$key
            }
            elseif("text" -match "^$key" -or "Content" -match "^$key") {
                $this.Content = $values.$key
            }
            elseif("Clear" -match "^$key") {
                $this.Clear = $values.$key
            }
            else {
                throw "Unknown key '$key' in hashtable. Allowed values are BackgroundColor, ForegroundColor, Content, and Clear"
            }
        }
   }

   [string] GetText() {
      if($this.Content -is [scriptblock]) {
         return & $this.Content
      } else {
         return $this.Content
      }
   }

   [string] ToString() {
      return $(
         if($this.BackgroundColor) {
            [PowerLineBlock]::EscapeCodes.bg."$($this.BackgroundColor)"
         } else {
            [PowerLineBlock]::EscapeCodes.bg.Clear
         }
      ) + $(
         if($this.ForegroundColor) {
            [PowerLineBlock]::EscapeCodes.fg."$($this.ForegroundColor)"
         } else {
            [PowerLineBlock]::EscapeCodes.fg.Clear
         }
      ) + $this.GetText() + $(
         if($this.Clear) {
            [PowerLineBlock]::EscapeCodes.bg.Clear
            [PowerLineBlock]::EscapeCodes.fg.Clear
         }
      )
   }

   static [PowerLineBlock] $Column = [PowerLineBlockCache][PowerLineBlock]@{Content="`t"}
   static [hashtable] $EscapeCodes = @{
      ESC = ([char]27) + "["
      CSI = [char]155
      Clear = ([char]27) + "[0m"
      fg = @{
         Clear       = ([char]27) + "[39m"
         Black       = ([char]27) + "[30m";  DarkGray    = ([char]27) + "[90m"
         DarkRed     = ([char]27) + "[31m";  Red         = ([char]27) + "[91m"
         DarkGreen   = ([char]27) + "[32m";  Green       = ([char]27) + "[92m"
         DarkYellow  = ([char]27) + "[33m";  Yellow      = ([char]27) + "[93m"
         DarkBlue    = ([char]27) + "[34m";  Blue        = ([char]27) + "[94m"
         DarkMagenta = ([char]27) + "[35m";  Magenta     = ([char]27) + "[95m"
         DarkCyan    = ([char]27) + "[36m";  Cyan        = ([char]27) + "[96m"
         Gray        = ([char]27) + "[37m";  White       = ([char]27) + "[97m"
      }
      bg = @{
         Clear       = ([char]27) + "[49m"
         Black       = ([char]27) + "[40m"; DarkGray    = ([char]27) + "[100m"
         DarkRed     = ([char]27) + "[41m"; Red         = ([char]27) + "[101m"
         DarkGreen   = ([char]27) + "[42m"; Green       = ([char]27) + "[102m"
         DarkYellow  = ([char]27) + "[43m"; Yellow      = ([char]27) + "[103m"
         DarkBlue    = ([char]27) + "[44m"; Blue        = ([char]27) + "[104m"
         DarkMagenta = ([char]27) + "[45m"; Magenta     = ([char]27) + "[105m"
         DarkCyan    = ([char]27) + "[46m"; Cyan        = ([char]27) + "[106m"
         Gray        = ([char]27) + "[47m"; White       = ([char]27) + "[107m"
      }
   }
}

class PowerLineBlockCache : PowerLineBlock {
    [string]$Content
    [int]$Length

    PowerLineBlockCache([PowerLineBlock] $output) {

        $this.BackgroundColor = $output.BackgroundColor
        $this.ForegroundColor = $output.ForegroundColor
        $this.Content = $output.GetText()
        $this.Length = $this.Content.Length
    }
}

class PowerLine  {
    static [char]$LeftCap  = [char]0xe0b0 # right-pointing arrow
    static [char]$RightCap = [char]0xe0b2 # left-pointing arrow
    static [char]$LeftSep  = [char]0xe0b1 # left open >
    static [char]$RightSep = [char]0xe0b3 # right open <

    static [char]$Branch   = [char]0xe0a0 # Branch symbol
    static [char]$LOCK     = [char]0xe0a2 # Padlock
    static [char]$GEAR     = [char]0x26ef # The settings icon, I use it for debug
    static [char]$POWER    = [char]0x26a1 # The Power lightning-bolt icon

    [bool]$IsPromptLine = $false

    [System.Collections.Generic.List[PowerLineBlock]]$Blocks = [System.Collections.Generic.List[PowerLineBlock]]@()

    PowerLine() {}
    PowerLine([PowerLineBlock[]]$Blocks) {
        $this.Blocks = $Blocks
    }
    PowerLine([PowerLineBlock[]]$Blocks, [bool]$PromptLine) {
        $this.Blocks = $Blocks
        $this.IsPromptLine = $PromptLine
    }

    [string] ToString() {
        # Initialize variables ...
        $width = [Console]::BufferWidth
        $leftLength = 0
        $rightLength = 0

        # Precalculate all the text and remove empty blocks
        $Output = ([PowerLineBlockCache[]]@($this.Blocks)) | Where Length

        # Output each block with appropriate separators and caps
        return $(for($l=0; $l -lt $Output.Length; $l++) {
            $block = $Output[$l]
            if([PowerLineBlock]::Column -eq $block) {
                # the length of the second column
                $rightLength = ($(for($r=$l+1; $r -lt $Output.Length; $r++) {
                    $Output[$r].length + 1
                }) | Measure-Object -Sum).Sum

                $space = $width - $rightLength

                if($leftLength) {
                    # Output a cap on the left if there's output there
                    # Use the Background of the previous block as the foreground
                    [PowerLineBlock]@{
                        ForegroundColor = ($Output[($l-1)]).BackgroundColor
                        Content = [PowerLine]::LeftCap
                        Clear = $true
                    }
                }

                if($this.IsPromptLine) {
                    "$([PowerLineBlock]::EscapeCodes.ESC)s"
                }
                "$([PowerLineBlock]::EscapeCodes.ESC)${space}G"

                # the right cap uses the background of the next block as it's foreground
                [PowerLineBlock]@{
                    ForegroundColor = ($Output[($l+1)]).BackgroundColor
                    Content = [PowerLine]::RightCap
                }
            } else {
                if($leftLength -eq 0 -and $rightLength -eq 0) {
                    # On a new line, recalculate the length of the "left-aligned" line
                    $leftLength = ($(for($r=$l; $r -lt $Output.Length -and $Output[$r] -ne [PowerLineBlock]::NewLine -and $Output[$r] -ne [PowerLineBlock]::Column; $r++) {
                        $Output[$r].length + 1
                    }) | Measure-Object -Sum).Sum
                }

                $block # the actual output
                if($Output[($l+1)] -ne [PowerLineBlock]::NewLine -and $Output[($l+1)] -ne [PowerLineBlock]::Column)
                {
                    # if the next block is the sambe background color, use a >
                    if($block.BackgroundColor -eq $Output[($l+1)].BackgroundColor) {
                        if($rightLength) {
                            [PowerLine]::RightSep
                        } else {
                            [PowerLine]::LeftSep
                        }
                    } else {
                        # Otherwise output a cap
                        [PowerLineBlock]@{
                            ForegroundColor = $block.BackgroundColor
                            BackgroundColor = $Output[($l+1)].BackgroundColor
                            Content = if($rightLength) {
                                [PowerLine]::RightCap
                            } else {
                                [PowerLine]::LeftCap
                            }
                        }
                    }
                }
            }
        }

        # Output a cap on the left if we didn't already
        if(!$rightLength -and $leftLength) {
            [PowerLineBlock]@{
                ForegroundColor = ($Output[($l-1)]).BackgroundColor
                Content = [PowerLine]::LeftCap
                Clear = $true
            }
        }
        [PowerLineBlock]::EscapeCodes.fg.Clear
        [PowerLineBlock]::EscapeCodes.bg.Clear
        # Anchor here if we didn't already
        if($this.IsPromptLine -and !$rightLength) {
            "$([PowerLineBlock]::EscapeCodes.ESC)s"
        }) -join ""
    }
}

class PowerLinePrompt {
    [bool]$SetTitle = $true
    [bool]$SetCwd = $true
    [int]$PrefixLines = 0
    [System.Collections.Generic.List[PowerLine]]$Lines = [System.Collections.Generic.List[PowerLine]]@()

    PowerLinePrompt() { }

    PowerLinePrompt([PowerLine[]]$PowerLines) {
        $this.Lines.AddRange($PowerLines)
    }

    PowerLinePrompt([PowerLine[]]$PowerLines, [int]$PrefixLines) {
        $this.Lines.AddRange($PowerLines)
        $this.PrefixLines = $PrefixLines
    }

    [string] ToString() {
        return $(
            # Like output on the previous line(s)
            if($this.PrefixLines -ne 0)
            {
                "$([PowerLineBlock]::EscapeCodes.ESC)1A" * [Math]::Abs($this.PrefixLines)
            }

            $this.Lines -join "`n"

            # RECALL LOCATION
            if($this.Lines.IsPromptLine -contains $true) {
                "$([PowerLineBlock]::EscapeCodes.ESC)u"
            }
            [PowerLineBlock]::EscapeCodes.fg.Default
        ) -join ""
    }

}

if(!(Test-Path Variable:Global:PowerLinePrompt)) {
    $PromptLine = [PowerLine]::New(@(
        [PowerLineBlock]@{ bg = "blue";     fg = "white"; text = { $MyInvocation.HistoryId } }
        [PowerLineBlock]@{ bg = "cyan";     fg = "white"; text = { "$([PowerLine]::Gear)" * $NestedPromptLevel } }
        [PowerLineBlock]@{ bg = "darkblue"; fg = "white"; text = { $pwd.Drive.Name } }
        [PowerLineBlock]@{ bg = "darkblue"; fg = "white"; text = { Split-Path $pwd -leaf } }
    )
    )
    # Get-Location -Stack doesn't work when we define the scriptblock in the module -- not sure why
    #    [PowerLineBlock]@{ bg = "cyan";     fg = "white"; text = { if($pushd = (Get-Location -Stack).count) { "»" + $pushd } } }

    $PromptLine.IsPromptLine = $true
    $global:PowerLinePrompt = [PowerLinePrompt]::new(@($PromptLine))
}
# Add calculated values for the "Default" colors
[PowerLineBlock]::EscapeCodes.fg.Default = [PowerLineBlock]::EscapeCodes.fg."$($Host.UI.RawUI.ForegroundColor)"
[PowerLineBlock]::EscapeCodes.fg.Background = [PowerLineBlock]::EscapeCodes.fg."$($Host.UI.RawUI.BackgroundColor)"
[PowerLineBlock]::EscapeCodes.bg.Default = [PowerLineBlock]::EscapeCodes.bg."$($Host.UI.RawUI.BackgroundColor)"


function Get-Elapsed {
   [CmdletBinding()]
   param(
      [Parameter()]
      [int]$Id,

      [Parameter()]
      [string]$Format = "{0:h\:mm\:ss\.ffff}"
   )
   $LastCommand = Get-History -Count 1 @PSBoundParameters
   if(!$LastCommand) { return "" }
   $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
   $Format -f $Duration
}

function Set-PowerLinePrompt {
    $function:global:prompt =  {

        # FIRST, make a note if there was an error in the previous command
        $err = !$?

        try {
            if($PowerLinePrompt.SetTitle) {
                # Put the path in the title ... (don't restrict this to the FileSystem)
                $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix, (Convert-Path $pwd),  $pwd.Provider.Name
            }
            if($PowerLinePrompt.SetCwd) {
                # Make sure Windows & .Net know where we are
                # They can only handle the FileSystem, and not in .Net Core
                [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
            }
        } catch {}

        if($Host.UI.SupportsVirtualTerminal) {
            "$PowerLinePrompt"
        } else {
            "> "
        }

    }
}


#>