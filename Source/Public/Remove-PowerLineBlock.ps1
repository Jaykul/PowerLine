function Remove-PowerLineBlock {
    <#
        .Synopsis
            Remove text or a ScriptBlock from the $Prompt
        .Description
            This function exists primarily to ensure that modules are able to clean up the prompt easily when they're removed
        .Example
            Remove-PowerLineBlock {
                New-PowerLineBlock { Get-Elapsed } -ForegroundColor White -BackgroundColor DarkBlue -ErrorBackground DarkRed -ElevatedForegroundColor Yellow
            }

            Removes the specified block. Note that it must be _exactly_ the same as when you added it.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueForMandatoryParameter', "Index",
        Justification = 'This rule should ignore parameters that are only mandatory in some parameter sets')]
    [CmdletBinding(DefaultParameterSetName="ByObject")]
    param(
        # The text, object, or scriptblock to show as output
        [Parameter(Position=0, Mandatory, ValueFromPipeline, ParameterSetName = "ByObject")]
        [Alias("Text")]
        $InputObject,

        [Parameter(Mandatory, ParameterSetName = "ByIndex")]
        [int]$Index = -1
    )
    process {
        if ($PSCmdlet.ParameterSetName -eq "ByObject") {
            if ($InputObject -is [PoshCode.TerminalBlock]) {
                $Index = @($Global:Prompt).IndexOf($InputObject)
            }
            if ($Index -ge 0) {
                $InputString = if ($InputObject.Object) {
                    $InputObject.Object.ToString().Trim()
                } else {
                    $InputObject.ToString().Trim()
                }
                $Index = @($Global:Prompt).ForEach{$_.Object.ToString().Trim()}.IndexOf($InputString)
            }
        }

        if ($Index -lt 0) {
            $Index = $Global:Prompt.Count - $Index
        }

        if ($Index -ge 0) {
            $null = $Global:Prompt.RemoveAt($Index)
        }

        if ($Index -lt $Script:PowerLineConfig.DefaultAddIndex) {
            $Script:PowerLineConfig.DefaultAddIndex--
        }
    }
}
