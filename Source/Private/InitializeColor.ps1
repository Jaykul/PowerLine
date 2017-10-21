function InitializeColor {
    [CmdletBinding()]
    param(
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

    if(!(Get-Member -InputObject $Global:Prompt -Name Colors)) {
        Add-Member -InputObject $Global:Prompt -MemberType NoteProperty -Name Colors -Value $Colors
    } else {
        $Global:Prompt.Colors = $Colors
    }
}