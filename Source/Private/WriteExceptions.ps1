function WriteExceptions {
    [CmdletBinding()]
    param(
        # A dictionary mapping script blocks to the exceptions which threw them
        [System.Collections.Specialized.OrderedDictionary]$ScriptExceptions
    )
    $ErrorString = ""

    if($PromptErrors.Count -gt 0) {
        $global:PromptErrors = [ordered]@{} + $ScriptExceptions
        Write-Warning "Exception thrown from prompt block. Check `$PromptErrors"
        #$PromptErrors.Insert(0, "0 Preview","Exception thrown from prompt block. Check `$PromptErrors:`n")
        if(@($Host.PrivateData.PSTypeNames)[0] -eq "Microsoft.PowerShell.ConsoleHost+ConsoleColorProxy") {
            foreach($e in $ScriptExceptions.Values) {
                $ErrorString += [PoshCode.Pansies.Text]@{
                    ForegroundColor = $Host.PrivateData.ErrorForegroundColor
                    BackgroundColor = $Host.PrivateData.ErrorBackgroundColor
                    Object = $e
                }
                $ErrorString += "`n"
            }
        } else {
            foreach($e in $ScriptExceptions) {
                $ErrorString += [PoshCode.Pansies.Text]@{
                    ForegroundColor = "Red"
                    BackgroundColor = "Black"
                    Object = $e
                }
                $ErrorString += "`n"
            }
        }
    }

    $ErrorString
}