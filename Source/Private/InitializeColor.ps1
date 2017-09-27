function InitializeColor {
    [CmdletBinding()]
    param(
        [List[ScriptBlock]]$Prompt = $Global:Prompt,

        [List[RgbColor]]$Colors = $Global:Prompt.Colors
    )

    if(!$PSBoundParameters.ContainsKey("Colors")){
        [List[RgbColor]]$Colors = if($Script:PowerlineColors) {
            $Script:PowerlineColors
        } else {
            "xt45","xt39","xt33","xt27","xt12"
        }
    }
    $Script:PowerlineColors = $Colors

    if(!(Get-Member -InputObject $Local:Prompt -Name Colors)) {
        Add-Member -InputObject $Local:Prompt -MemberType NoteProperty -Name Colors -Value $Colors
    } else {
        $Local:Prompt.Colors = $Colors
    }
}

InitializeColor