# PowerLine: Classes for richer output and prompts

PowerLine gives you the ability to easily control background and forground colors
in prompts and other console output where ANSI VT escape sequences are supported,
including the console in Windows 10 (Anniversary Update), emulators such as ConEmu, and
on Linux and OS X.

PowerLine is intended for use in prompts, and gives you a nice modular way to
build up a prompt without having to write a lot of logic yourself.
How about a trivial example:

```posh
#requires -module PowerLine
using module PowerLine

$PowerLinePrompt = ,(
        @{ bg = "Cyan";     fg = "White"; text = { $MyInvocation.HistoryId } },
        @{ bg = "DarkBlue"; fg = "White"; text = { $pwd } }
    )

Set-PowerLinePrompt
```

![Simple Powerline](https://github.com/Jaykul/PowerLine/raw/media/simple_powerline.png)

The catch is that you need to install a [PowerLine font](https://github.com/PowerLine/fonts)
to get those nice angled separators. There are many very nice monospaced fonts to choose from,
and you can install them all by just cloning the repository and running the `install.ps1` script,
or you can just pick one and download and install that.
There are [screenshots of all of them](https://github.com/powerline/fonts/blob/master/samples/All.md)


## Doing more with your prompt

That first example is really simple, but if you're using the powerline prompt,
it's really simple to create more complicated prompts:

```posh
#requires -module PowerLine
using module PowerLine
using namespace PowerLine

$PowerLinePrompt = 1,
    (
        [BlockCache]::Column, # Right align this line
        @{ bg = "DarkGray"; fg = "White"; text = { Get-Elapsed } },
        @{ bg = "Black";    fg = "White"; text = { Get-Date -f "T" } }
    ),
    (
        @{ bg = "Blue";     fg = "White"; text = { $MyInvocation.HistoryId } },
        @{ bg = "Cyan";     fg = "White"; text = { [Line]::Gear * $NestedPromptLevel } },
        @{ bg = "Cyan";     fg = "White"; text = { if($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } } },
        @{ bg = "DarkBlue"; fg = "White"; text = { $pwd.Drive.Name } },
        @{ bg = "DarkBlue"; fg = "White"; text = { Split-Path $pwd -leaf } },
        [BlockCache]::Prompt,
        [BlockCache]::Column,
        @{ bg = "DarkRed";  fg = "White"; text = $Env:USERNAME + "@" + $Env:COMPUTERNAME}
    )

Set-PowerLinePrompt
```

![Powerline Features](https://github.com/Jaykul/PowerLine/raw/media/powerline_features.png)

This example shows most of the major features:

1. The value of a `[PowerLine.Prompt]` is actually an array of `[PowerLine.Line]`s, and each line is an array of `[Powerline.Block]`s.
2. You can pass a number as the first value to cause the first `n` lines to be output _above_ the prompt line.
This risks overlapping the output of the previous command, so you might want to ...
3. You can output a `[PowerLine.BlockCache]::Column` to make the rest of the line right-justified.
4. Blocks which occasionally have no output (like the two blocks with `"Cyan"` background in this example),
 will simply vanish when there's no output. They don't mess up the colors of the other blocks.
5. The `[PowerLine.BlockCache]::Prompt` is used to anchor the location where the cursor should end up.
You only need to do this if you want to have lines _after_ the prompt (which I don't recommend)
or right-aligned text on the prompt line, as in this example (it dissapears when you start typing).
6. You can assign static text, or a scriptblock to the "text" or "content" property of the blocks.

### Future Plans

If you have any questions, [please ask](https://github.com/jaykul/PowerLine/issues),
and feel free to send me pull requests with additional escape sequences, or whatever.

I would love help with a couple of things in particular:

Currently my methods require the use of a `[ConsoleColor]`, and since those colors
are also supported by the old-fashioned `Write-Host` command, I'm thinking about
providing a `Write-PowerLine` function for compatibility with older versions of Windows and PowerShell.

I expect that the next major Windows update to include full xterm color support,
which ConEmu (and terminals on Linux and OSX) already support, so I'm thinking about
how to make use of RGB colors and the 256 color xterm palette...

Additionally, the windows console supports full window-splitting via ANSI sequences now,
so I'd like to expose that functionality somehow ...

## Core classes summary:

The PowerLine module provides several classes in a PowerLine namespace. Three classes for use in output, and two helper classes.

* Block
* Line
* Prompt

The `PowerLine.Prompt` class is a collection of lines, and has a property `PrefixLines`
to control how far _up_ to go before outputting. The `PowerLine.Line` class is just a collection of blocks.
The `PowerLine.Block` class has the foreground/background colors (optionally), and also has a few important static string members:

* `RightSep` and `LeftSep`
* `RightCap` and `LeftCap`

These are the separators which are used between blocks. The "Cap" separators are used when the color is changing.
By default they are the solid arrows you see in all the Powerline examples. The "Sep" separators are basically
like < and > except that they go the full height of the line. There are a couple of other special characters there,
but I'll leave that for you to explore.


## Helper classes: ##

* BlockCache
* AnsiHelper

The `PowerLine.BlockCache` class is actually a subclass of the `PowerLine.Block`,
with the distinction that the `Content` property can only contain a text string, not a scriptblock.
If you look in the source, there's also a `PowerLine.Cacher` class
which is just used as a holder for an extension method to convert between them.

The `AnsiHelper class has ANSI escape sequences and some helper methods. You shouldn't need to use it directly, but if you want to, there are 2 methods and 2 static hashtables and a nested EscapeCodes classes:

#### GetCode

```posh
[PowerLine.AnsiHelper]::GetCode( [ConsoleColor]$Color, [bool]$ForBackground )
```

You call this with a color to get the ANSI escape sequence for it. Optionally, pass $true to get back background color code. You would need to use the output of that in text output to the console for it to do anything.

#### WriteAnsi

```posh
[PowerLine.AnsiHelper]::WriteAnsi( [ConsoleColor]$foreground, [ConsoleColor]$background, [object]$value, [bool]$clear )
```

This method takes a foreground and background color, an object to output,
and a boolean to indicate whether to clear the color codes back to default at the end of the string.
This is basically Write-Host, but using ANSI escape sequences, so you'll probably never need it...

#### EscapeCodes

The `[PowerLine.AnsiHelper]::Foreground` and `[PowerLine.AnsiHelper]::Background` are dictionaries
which each contain all 16 of the console colors plus a "Clear" value as ANSI escape sequences.
Additionally, there's a `[PowerLine.AnsiHelper+EscapeCodes]` class which has a few raw
escape sequences on it which I find useful to keep code readable...