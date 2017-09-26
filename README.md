> Currently in PowerShell, the prompt is a function that _must_ return a string. Modules that want to add information to your prompt typically don't even try if you have customized your prompt (see Posh-Git, for example). We want to have beautiful custom prompts **and** let modules add information easily.

# NOTE: PowerLine 3 is NOT backward compatible

Almost all the old features are here, but with a *much* simpler interface. Existing users will need to change to use the simple lists in `$Prompt` and `$PowerLineColors`, but it's for a good cause:

# Prompts as arrays

The core argument of PowerLine 3 is that PowerShell should change it's built-in prompt to use a `$Prompt` variable that's a list of scriptblocks like this:

```posh
using namespace System.Collections.Generic

[List[ScriptBlock]]$Prompt = @(
    { "PS " }
    { $executionContext.SessionState.Path.CurrentLocation }
    { '>' * ($nestedPromptLevel + 1) }
)
```

And then use a default `prompt` function which invokes those scripts, something like this:

```posh
function prompt {
    -join $prompt.Invoke()
}
```

This change would produce _the same output_ as before, and would have _no impact_ on users who already overwrite the default prompt.

Of course, that means **you** can switch to this model right now, by just putting those two blocks in your profile.

# Why Lists of ScriptBlocks?

A few months ago I realized that while the first version of my PowerLine prompt had made my prompt prettier, it had also made it harder for me to change on the fly, and made it nearly impossible for modules to modify it. So I wrote these requirements:

```gherkin
As a PowerShell user
I want to be able to customize my prompt
So that I can get the right information

As a PowerShell module author
I want to be able to add information to the user's prompt
So users can automatically get the right information

As an alpha geek
I want to be have a cool prompt
So that others will copy it
```

By converting the prompt to a List:

1. The user can easily add or remove information on the fly.
2. Modules can add (and remove) information as they're imported.
3. We can customize the look separate from the content.

## For users:

It's suddenly easy to tweak the prompt. I can remove the unecessary "PS " from the front of my prompt by just running
`$Prompt = $Prompt | Select -Skip 1`. Or if I wanted to print the current command's `HistoryId` instead of the "PS",
I could just replace that first part: `$Prompt[0] = { "$($MyInvocation.HistoryId) " }`.

## For module authors:

Modules can modify your prompt just as easily. Adding to a list is _**a lot** simpler_ for module authors, and it makes
it easier for users to re-order the changes afterward. Modules no longer have to modify an existing function, and users
still end up with better control, and a prompt they can understand.

For instance, posh-git can just do this: `$Prompt.Add({Write-VcsStatus})` and their new prompt function (which returns
a string, instead of using Write-Host), is added within your prompt. Not only that, the user can then re-order the prompt
by doing something like: `$Prompt = $Prompt[0,1,3,2]`

## For power users:

The best part, in my opinion, is that we can then make your prompt look cooler. You can go from simple to elegant with a single command from the PowerLine module, and then you can tweak the colors by setting the $Prompt.Colors variable to a list of colors, perhaps using `Get-Gradient -Flatten`...

```posh
Set-PowerLinePrompt -Newline -PowerLineFont
```
<!--
![Set-PowerLine](https://github.com/Jaykul/PowerLine/raw/media/powerline_features_psgit.png)
-->

Of course, you could get some of that look by manually writing ANSI sequences, but that's a lot more complicated:

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

# PowerLine's Fancy Features

In addition the the obvious color features, if you install a [PowerLine font](https://github.com/PowerLine/fonts), you get
nice angled separators. There are a lot of monospaced fonts to choose from, and you can even install them all by just
cloning the repository and running the `install.ps1` script, or you can just pick one and download and install that.
There are [screenshots of all of them](https://github.com/powerline/fonts/blob/master/samples/All.md).

On top of that, there are a couple of somewhat hidden features.

## PowerLine supports right-aligned text.

Obviously, if you add a scriptblock that outputs a new line, you get a multi-line prompt. PowerLine explicitly supports
blocks that consist of nothing but the newline character, like  `{ "``n" }` and in addition, supports having right-aligned
blocks. If you add a scriptblock that outputs a tab `{ "``t" }`, everything from there to the next block which is just a
newline will be right aligned.

PowerLine cleans up empty blocks -- because we add separator characters, and you don't want to end up with a string of
separaters.

PowerLine supports blocks which output arrays -- by default each block gets a new color (and is separated from other blocks
with a "ColorSeparator," as specified in `[PoshCode.Pansies.Entities]::ExtendedCharacters`) but if a block outputs an array,
the elements of the array will be separated with the alternate "Separator" instead. Note that right-aligned blocks use the
"ReverseColorSeparator" and "ReverseSeparator" instead.

## Helpers for module authors

PowerLine also provides some additional functions for adding and removing from the prompt list so that modules can add without worrying about doubling up. If Posh-git was to actually adopt the code I mentioned earlier, every time you imported it, they would append to your prompt -- and since they're not cleaning up when you remove the module, they would get re-imported automatically whenever you removed the module.

PowerLine gives you an `Add-PowerLineBlock` which lets you pass in a `ScriptBlock` and have it added to the prompt only if it's not already there -- which means the user can move it around, and re-import the module without having it show up twice. It even has an `-AutoRemove` switch which can be used when adding to the PowerLine from a module to automatically remove that block if the module is removed by the user. And of course, there's a `Remove-PowerLineBlock` which lets you clean up manually.

There is a `New-PromptText` function which allows you to change the colors based on elevation, or the success of the last command.

Finally, there are separate `Test-Success` and `Test-Elevation` functions (which are used by New-PromptText), if you just want to output something conditionally, or deal with it on your own.

# Future Plans

If you have any questions, [please ask](https://github.com/jaykul/PowerLine/issues),
and feel free to send me pull requests with additional escape sequences, or whatever.

PowerLine now depends on [Pansies](https://github.com/PoshCode/Pansies) for color, special characters, etc.
