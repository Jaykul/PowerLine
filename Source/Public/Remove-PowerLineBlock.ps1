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
    [CmdletBinding(DefaultParameterSetName="Error")]
    param(
        # The text, object, or scriptblock to show as output
        [Parameter(Position=0, Mandatory, ValueFromPipeline)]
        [Alias("Text")]
        $InputObject
    )
    process {
        # TODO: Make sure this works
        $Index = @($Global:Prompt).ForEach{$_.ToString().Trim()}.IndexOf($InputObject.ToString().Trim())
        if($Index -ge 0) {
            $null = $Global:Prompt.RemoveAt($Index)
        }
        if($Index -lt $Script:PowerLineConfig.DefaultAddIndex) {
            $Script:PowerLineConfig.DefaultAddIndex--
        }
    }
}
