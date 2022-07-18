using namespace PoshCode
class PowerLineTheme {
    [BlockCaps]$DefaultCapsLeftAligned
    [BlockCaps]$DefaultCapsRightAligned
    [BlockCaps]$DefaultSeparator
    [TerminalBlock[]]$Prompt
    [string]$PSReadLineContinuationPrompt
    [string]$PSReadLineContinuationPromptColor
    [string[]]$PSReadLinePromptText
    [bool]$SetCurrentDirectory
    [scriptblock]$Title
    [int]$DefaultAddIndex = -1
}

Add-MetadataConverter @{
    "PowerLineTheme" = { [PowerLineTheme]$args[0] }
    [PowerLineTheme] = {
"PowerLineTheme @{
    DefaultCapsLeftAligned = '$($_.DefaultCapsLeftAligned.Left)', '$($_.DefaultCapsLeftAligned.Right)'
    DefaultCapsRightAligned = '$($_.DefaultCapsRightAligned.Left)', '$($_.DefaultCapsRightAligned.Right)'
    DefaultSeparator = '$($_.DefaultSeparator.Left)', '$($_.DefaultSeparator.Right)'
    Prompt = @(
        $($_.Prompt.ToPsScript() -join "`n        ")
    )
    PSReadLineContinuationPrompt = '$($_.PSReadLineContinuationPrompt)'
    PSReadLineContinuationPromptColor = '$($_.PSReadLineContinuationPromptColor)'
    PSReadLinePromptText = '$($_.PSReadLinePromptText -join "','")'
    SetCurrentDirectory = $(if ($_.SetCurrentDirectory) { '$true' } else { '$false' })$(
    if (![string]::IsNullOrWhiteSpace($_.Title)) {
        "`n    Title = ScriptBlock @'`n$($_.Title)`n'@"
    })$(
        if ($_.DefaultAddIndex -ge 0) {
        "`n    DefaultAddIndex = $($_.DefaultAddIndex)'@"
    })
}"
    }
}
