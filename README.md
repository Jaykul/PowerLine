> Currently in PowerShell, your prompt is a function that _must_ return a string. Modules that want to add information to your prompt typically don't even try if you have customized your prompt (see Posh-Git, for example). We want to have beautiful custom prompts **and** let modules add information easily.

# Prompts as arrays

The core suggestion of this module is that PowerShell should change it's built-in prompt to use a `$Prompt` variable that's an array of scriptblocks like this:

```posh
using namespace System.Collections.Generic

[List[ScriptBlock]]$Prompt = @(
    { "PS " }
    { $executionContext.SessionState.Path.CurrentLocation }
    { '>' * $nestedPromptLevel }
)
```

And then use a default `prompt` function which invokes those scripts like this:

```posh
function prompt {
    -join $prompt.Invoke()
}
```

Or if `$Host.UI.SupportsVirtualTerminal` like this (to clear any escape sequences):

```posh
function prompt {
    ($prompt.Invoke() -join " ") + "`e[0m>"
}
```

Obviously this change won't have *any* impact on users who already overwrite the default prompt, and will produce the same output as before by default.

# Simple, but amazing

```gherkin
As a PowerShell user
I want to be able to customize my prompt
So that I can get the right information

As a PowerShell Module author
I want to be able to add information to the user's prompt
So users can automatically get the right information
```

With the prompt as an ArrayList, the user can still customize it easily.
For instance, if I wanted to print the current command's history ID instead of the "PS",
I could replace the first part of the prompt without rewriting the function:
`$Prompt[0] = { "$($MyInvocation.HistoryId) " }`

The big difference is that *modules* that want to add information to the prompt
can _simply_ insert into or append to the array, _and_ users can then tweak the order,
without having to manually rewrite their prompt. For instance, posh-git can just do this:
`$Prompt.Add({Write-VcsStatus})` and _if their function just returned a string_,
the user can easily re-order the prompt by just doing something like:
`$Prompt = $Prompt[3,1,0,2]`

### But the cool thing is...

Let's say you wanted to make your prompt look cooler. You could just import PowerLine and go from this:

![Simple Powerline](https://github.com/Jaykul/PowerLine/raw/media/git.png)

To this:


Or you could write some custom ANSI sequences:

```posh
function prompt {
    $Color = 21
    $E = "$([char]27)"
    $F = "$E[38;5"
    $B = "$E[48;5"

    "$B;${Color}m" + $(
        $Prompt.Invoke().ForEach{
            # Cycle colors
            "$_$F;${Color}m$B;$(($Color+=6))m"
        } -join "$([char]0xe0b0)$E[39m"
    ) +
    # I HEART PS >
    "`n$B;15m$F;0mI $F;9m$([char]9829)$F;0m PS$B;0m$F;15m$([char]0xe0b0)$E[0m"
}
```


![Simple Powerline](https://github.com/Jaykul/PowerLine/raw/media/simple_powerline.png)

When you import Posh-Git, it's prompt modifications will just clash.


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
    @{ bg = "#336699"; fg = "#eeee00"; text = { $MyInvocation.HistoryId } }
    @{ bg = "DarkBlue"; fg = "White"; text = { Get-SegmentedPath } }
)

Set-PowerLinePrompt -PowerLineFont
```


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

## New-PowerLineBlock

There is a `New-PowerLineBlock` function which allows you to change the colors based on elevation, or the success of the last command.
There are also `Test-Success` and `Test-Elevation` function if you just want to output something conditionally, or deal with it on your own.

### Future Plans

If you have any questions, [please ask](https://github.com/jaykul/PowerLine/issues),
and feel free to send me pull requests with additional escape sequences, or whatever.

I would love help with a couple of things in particular:

Currently my methods require the use of a `[RgbColor]`, and since those colors
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
[PowerLine.AnsiHelper]::GetCode( [RgbColor]$Color, [bool]$ForBackground )
```

You call this with a color to get the ANSI escape sequence for it. Optionally, pass $true to get back background color code. You would need to use the output of that in text output to the console for it to do anything.

#### WriteAnsi

```posh
[PowerLine.AnsiHelper]::WriteAnsi( [RgbColor]$foreground, [RgbColor]$background, [object]$value, [bool]$clear )
```

This method takes a foreground and background color, an object to output,
and a boolean to indicate whether to clear the color codes back to default at the end of the string.
This is basically Write-Host, but using ANSI escape sequences, so you'll probably never need it...

#### EscapeCodes

The `[PowerLine.AnsiHelper]::Foreground` and `[PowerLine.AnsiHelper]::Background` are dictionaries
which each contain all 16 of the console colors plus a "Clear" value as ANSI escape sequences.
Additionally, there's a `[PowerLine.AnsiHelper+EscapeCodes]` class which has a few raw
escape sequences on it which I find useful to keep code readable...