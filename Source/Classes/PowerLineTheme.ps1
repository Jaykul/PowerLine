using namespace PoshCode
class PowerLineTheme {
    [TerminalBlock[]]$Prompt
    [BlockCaps]$DefaultCaps
    [string]$DefaultSeparator
    [scriptblock]$Title
    [bool]$SetCurrentDirectory
    [bool]$HideErrors
    [string]$RepeatPrompt
    [RgbColor[]]$PSReadLineErrorColor
    [string]$PSReadLineContinuationPrompt
    [string]$PSReadLineContinuationPromptColor
    [string[]]$PSReadLinePromptText
    [int]$DefaultAddIndex = -1
}

Add-MetadataConverter @{
    [PowerLineTheme] = { "PSObject @{
    DefaultCaps = '$($_.DefaultCaps.Left)', '$($_.DefaultCaps.Right)'
    DefaultSeparator = '$($_.DefaultSeparator)'
    Prompt = @(
        $($_.Prompt.ToPSMetadata() -join "`n        ")
    )
    PSReadLineContinuationPrompt = '$($_.PSReadLineContinuationPrompt)'
    PSReadLineContinuationPromptColor = '$($_.PSReadLineContinuationPromptColor)'
    $(if ($_.PSReadLineErrorColor) {
        "PSReadLineErrorColor = '$($_.PSReadLineErrorColor -join "','")'"
    })
    HideErrors = $(if ($_.HideErrors) { '$true' } else { '$false' })
    RepeatPrompt = '$(if ($_.RepeatPrompt) { $_.RepeatPrompt } else { 'CachedPrompt' })'
    SetCurrentDirectory = $(if ($_.SetCurrentDirectory) { '$true' } else { '$false' })$(
    if (![string]::IsNullOrWhiteSpace($_.Title)) {
        "`n    Title = ScriptBlock @'`n$($_.Title)`n'@"
    })$(
        if ($_.DefaultAddIndex -ge 0) {
        "`n    DefaultAddIndex = $($_.DefaultAddIndex)"
    })
}"
    }
}
