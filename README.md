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

$PowerLinePrompt = @(
        @{ bg = "Cyan";     fg = "White"; text = { $MyInvocation.HistoryId } }
        @{ bg = "DarkBlue"; fg = "White"; text = { $pwd } }
    )

Set-PowerLinePrompt -PowerLineFont
```

![Simple Powerline](https://github.com/Jaykul/PowerLine/raw/media/simple_powerline.png)

The catch is that you need to install a [PowerLine font](https://github.com/PowerLine/fonts)
to get those nice angled separators. There are many very nice monospaced fonts to choose from,
and you can install them all by just cloning the repository and running the `install.ps1` script,
or you can just pick one and download and install that.
There are [screenshots of all of them](https://github.com/powerline/fonts/blob/master/samples/All.md)


## Installing PowerLine

```posh
Install-Module PowerLine
```

Note that version 2.0.0 is _not entirely compatible_ with version 1 due to some major refactoring of the core classes.

## Doing more with your prompt

That first example is extremely simple, but if you're using the powerline prompt,
it's simple to create even more complicated prompts, with optional parts and more.
Take this example, which is what I'm using on my own box, with [PSGit](https://github.com/PoshCode/PSGit)

```posh
#requires -Module @{ModuleName="PSGit"; ModuleVersion="2.0.4"}, @{ModuleName="PowerLine"; ModuleVersion="2.0.0"}
using module PowerLine
using namespace PowerLine

$PowerLinePrompt = 1,
    (
        $null, # No left-aligned content on this line
        @(
            @{ text = { New-PowerLineBlock (Get-Elapsed) -ErrorBackgroundColor DarkRed -ErrorForegroundColor White -ForegroundColor Black -BackgroundColor DarkGray } }
            @{ bg = "Gray";     fg = "Black"; text = { Get-Date -f "T" } }
        )
    ),  @(
            @{ bg = "Blue";     fg = "White"; text = { $MyInvocation.HistoryId } }
            @{ bg = "Cyan";     fg = "White"; text = { [PowerLine.Prompt]::Gear * $NestedPromptLevel } }
            @{ bg = "Cyan";     fg = "White"; text = { if($pushd = (Get-Location -Stack).count) { "$([char]187)" + $pushd } } }
            @{ bg = "DarkBlue"; fg = "White"; text = { $pwd.Drive.Name } }
            @{ bg = "DarkBlue"; fg = "White"; text = { Split-Path $pwd -leaf } }
            # PSGit is still in early stages, but it has PowerLine support
            @{ text = { Get-GitStatusPowerline } }
        )

Set-PowerLinePrompt -CurrentDirectory -PowerlineFont:(!$SafeCharacters) -Title { "PowerShell - {0} ({1})" -f (Convert-Path $pwd),  $pwd.Provider.Name }

# As a bonus, here are the settings I use for my PSGit prompt:
Set-GitPromptSettings -SeparatorText '' -BeforeText '' -BeforeChangesText '' -AfterChangesText '' -AfterNoChangesText '' `
                      -BranchText "$([PowerLine.Prompt]::Branch) " -BranchForeground White -BranchBackground Cyan `
                      -BehindByText '▼' -BehindByForeground White -BehindByBackground DarkCyan `
                      -AheadByText '▲' -AheadByForeground White -AheadByBackground DarkCyan `
                      -StagedChangesForeground White -StagedChangesBackground DarkBlue `
                      -UnStagedChangesForeground White -UnStagedChangesBackground Blue


```

![Powerline Features](https://github.com/Jaykul/PowerLine/raw/media/powerline_features_psgit.png)

This example shows most of the major features:

1. Prompts have one or more Lines which have one or two Columns, made up of Blocks.
2. You can pass a number as the first value of a Prompt to cause the first `n` lines to be output overlapping the output.
This risks overlapping the output of the previous command, but ...
3. You can have a `$null` column to leave the left side empty.
4. Blocks which occasionally have no output (like the two blocks with `"Cyan"` background in this example),
 will simply vanish when there's no output. They don't mess up the colors of the other blocks.
5. The prompt is automatically anchored at the end of the last **left-aligned** column.
 Anything right-aligned on that prompt line dissapears when you start typing in PSReadLine.
6. You can assign static text, objects, or a scriptblock to the "text" or "content" property of the blocks.
7. There is a special New-PowerLineBlock function which allows you to change the colors based on the success of the last command.
 There is also a Test-Success function if you just want to output something conditionally if there's a failure

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

The PowerLine module provides several classes in a PowerLine namespace. Five classes for use in output, and a helper class.

* Block and BlockFactory
* Column
* Line
* Prompt

The `PowerLine.Prompt` class has a `Lines` property which is a collection of lines,
and has a property `PrefixLines` to control how far _up_ to go before outputting.
The `PowerLine.Line` class has a `Columns` property which is a collection of columns.
The `Powerline.Column` class has a `Blocks` property which is a collection of block factories.
The `Powerline.BlockFactory` class has _default_ foreground/background colors and
  an `Object` property which can be a scriptblock or object or text.
The `PowerLine.Block` class represents text that's ready for output -- you probably won't use this (use BlockFactory, as it supports scriptblocks).
It has foreground/background colors (optionally), and it's `Object` property always returns a string.


NOTE: the `Powerline.Prompt` class has a few important static members used for configuring the separators in output:

* `ColorSeparator` and `Separator`
* `ReverseColorSeparator` and `ReverseSeparator`

These are the separators which are used between blocks. The ColorSeparators are used when the color is changing,
by default they are solid half-blocks, the other separators are little arrows.

To get the output like in the PowerLine scripts, you need to set them to PowerLine characters.
You can do that by passing the `-PowerLineFont` switch to Set-PowerLinePrompt, or by manually setting the characters:

```posh
[PowerLine.Prompt]::ColorSeparator = [char]0xe0b0
[PowerLine.Prompt]::ReverseColorSeparator = [char]0xe0b2
[PowerLine.Prompt]::Separator = [char]0xe0b1
[PowerLine.Prompt]::ReverseSeparator = [char]0xe0b3
```


## Helper classes: ##

* AnsiHelper

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