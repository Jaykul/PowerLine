function Remove-PowerLineBlock {
    <#
        .Synopsis
            Remove text or a ScriptBlock from the $Prompt
        .Description
            This function exists primarily to ensure that modules are able to clean up the prompt easily when they're removed
        .Example
            $Prompt[-1] | Remove

            Removes the last block from the prompt
        .Example
            Show-ElapsedTime | Add-PowerLineBlock

            Remove-PowerLineBlock { Show-ElapsedTime }

            Removes the Show-ElapsedTime block from the prompt
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
        # We always remove by index so we can adjust the DefaultAddIndex
        if ($PSCmdlet.ParameterSetName -eq "ByObject") {
            if ($InputObject -is [PoshCode.TerminalBlock]) {
                $Index = @($Global:Prompt).IndexOf($InputObject)
                if ($Index -lt 0) {
                    $InputObject = $InputObject.Content
                }
            }

            if ($Index -lt 0) {
                $Index = @($Global:Prompt).ForEach("Content").IndexOf($InputObject)
            }

            if ($Index -lt 0) {
                $InputString = $InputObject.ToString().Trim()
                $Index = @($Global:Prompt).ForEach{ $_.Content.ToString().Trim() }.IndexOf($InputString)
                if ($Index -ge 0) {
                    Write-Warning "Removing `$Prompt[$Index] from the prompt with partial match."
                }
            }
        } elseif ($Index -lt 0) {
            $Index = $Global:Prompt.Count - $Index
        }

        if ($Index -ge 0) {
            $null = $Global:Prompt.RemoveAt($Index)
            if ($Index -lt $Script:PowerLineConfig.DefaultAddIndex) {
                $Script:PowerLineConfig.DefaultAddIndex--
            }
        } else {
            Write-Error "Could not find $InputObject to remove from the prompt."
        }

    }
}
