function InitializeColor {
    [CmdletBinding()]
    param(
        [List[ScriptBlock]]$Prompt = $Global:Prompt,

        [List[RgbColor]]$Colors = $Global:Prompt.Colors
    )

    if(!$PSBoundParameters.ContainsKey("Colors")){
        [List[RgbColor]]$Colors = "xt45","xt39","xt33","xt27","xt12"
    }

    if(!(Get-Member -InputObject $Prompt -Name Colors)) {
        Add-Member -InputObject $Prompt -MemberType NoteProperty -Name Colors -Value $Colors
    } else {
        $Prompt.Colors = $Colors
    }
}

InitializeColor