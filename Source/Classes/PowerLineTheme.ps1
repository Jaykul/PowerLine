using namespace PoshCode
class PowerLineTheme {
    [BlockCaps]$DefaultCaps
    [string]$DefaultSeparator
    [TerminalBlock[]]$Prompt
    [string]$PSReadLineContinuationPrompt
    [string]$PSReadLineContinuationPromptColor
    [string[]]$PSReadLinePromptText
    [bool]$SetCurrentDirectory
    [bool]$HideErrors
    [bool]$SimpleTransient
    [bool]$NoCache
    [scriptblock]$Title
    [int]$DefaultAddIndex = -1
}

Add-MetadataConverter @{
    [PowerLineTheme] = { "PSObject @{
    DefaultCaps = '$($_.DefaultCaps.Left)', '$($_.DefaultCaps.Right)'
    DefaultSeparator = '$($_.DefaultSeparator)'
    Prompt = @(
        $($_.Prompt.ToPsScript() -join "`n        ")
    )
    PSReadLineContinuationPrompt = '$($_.PSReadLineContinuationPrompt)'
    PSReadLineContinuationPromptColor = '$($_.PSReadLineContinuationPromptColor)'
    PSReadLinePromptText = '$($_.PSReadLinePromptText -join "','")'
    HideErrors = $(if ($_.HideErrors) { '$true' } else { '$false' })
    SimpleTransient = $(if ($_.SimpleTransient) { '$true' } else { '$false' })
    NoCache = $(if ($_.NoCache) { '$true' } else { '$false' })
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
