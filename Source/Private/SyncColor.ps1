function SyncColor {
    <#
        .SYNOPSIS
            Synchonize the Script:Colors and Gobal:Prompt.Colors
    #>
    [CmdletBinding()]
    param(
        [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$Colors,

        [switch]$Passthru
    )

    [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$script:Colors =
        # If you pass in colors, those win
        if ($PSBoundParameters.ContainsKey("Colors")){
            $Colors
        # If the prompt colors are set, those win (because they're user-settable)
        } elseif($global:Prompt.Colors) {
            $global:Prompt.Colors
        # Otherwise, if the script colors are set (they're our cache), use those
        } elseif ($script:Colors) {
            $script:Colors
        } else {
            # Finally, here's some fallback colors
            "Cyan","DarkCyan","Gray","DarkGray","Gray"
        }

    if ($Passthru) {
        $script:Colors
    }

    # Update Prompt.Colors
    if (!(Get-Member -InputObject $Global:Prompt -Name Colors)) {
        Add-Member -InputObject $Global:Prompt -MemberType NoteProperty -Name Colors -Value $script:Colors
    } else {
        $Global:Prompt.Colors = $script:Colors
    }
}
