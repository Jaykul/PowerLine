function WriteExceptions {
    [CmdletBinding()]
    param(
        # A dictionary mapping script blocks to the exceptions which threw them
        [System.Collections.Specialized.OrderedDictionary]$ScriptExceptions
    )
    $ErrorString = ""

    if ($PromptErrors.Count -gt 0) {
        $global:PromptErrors = [ordered]@{} + $ScriptExceptions
        Write-Warning "$($global:PromptErrors.Count) error(s) in prompt. Check `$PromptErrors for details. To ignore, Set-PowerLinePrompt -HideError"
        if ((Test-Path Variable:\PSStyle) -and $PSStyle.Formatting.Error) {
            foreach ($e in $ScriptExceptions.Values) {
                $ErrorString += $PSStyle.Formatting.Error + "$e" + $PSStyle.Reset + "`n"
            }
        } elseif (@($Host.PrivateData.PSTypeNames)[0] -eq "Microsoft.PowerShell.ConsoleHost+ConsoleColorProxy") {
            foreach ($e in $ScriptExceptions.Values) {
                $ErrorString += [PoshCode.Pansies.Text]@{
                    ForegroundColor = $Host.PrivateData.ErrorForegroundColor
                    BackgroundColor = $Host.PrivateData.ErrorBackgroundColor
                    Object = $e
                }
                $ErrorString += "`n"
            }
        } else {
            foreach ($e in $ScriptExceptions) {
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
