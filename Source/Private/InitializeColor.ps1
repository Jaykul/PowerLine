function InitializeColor {
    [CmdletBinding()]
    param(
        [System.Collections.Generic.List[ScriptBlock]]$Prompt = $(@($Global:Prompt)),

        [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$Colors = $Global:Prompt.Colors,

        [switch]$Passthru
    )

    if(!$PSBoundParameters.ContainsKey("Colors")){
        [System.Collections.Generic.List[PoshCode.Pansies.RgbColor]]$Colors = if($global:Prompt.Colors) {
            $global:Prompt.Colors
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