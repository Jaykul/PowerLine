function InitializeColor {
    [CmdletBinding()]
    param(
        [List[ScriptBlock]]$Prompt = $Global:Prompt,

        [List[RgbColor]]$Colors = $Global:Prompt.Colors,

        [switch]$Passthru
    )

    if(!$PSBoundParameters.ContainsKey("Colors")){
        [List[RgbColor]]$Colors = if($Script:PowerLinePrompt.Colors) {
            $Script:PowerLinePrompt.Colors
        } else {
            "Cyan","DarkCyan","Gray","DarkGray","Gray"
        }
    }
    if($Passthru) {
        $Colors
    }

    if(!(Get-Member -InputObject $Local:Prompt -Name Colors)) {
        Add-Member -InputObject $Local:Prompt -MemberType NoteProperty -Name Colors -Value $Colors
    } else {
        $Local:Prompt.Colors = $Colors
    }
}