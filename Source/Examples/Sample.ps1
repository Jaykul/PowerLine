Import-module PowerLine


$host.UI.RawUI.ForegroundColor = 'Green'
$host.UI.RawUI.BackgroundColor = 'Black'

if ($env:ConEmuAnsi -or $Host.UI.SupportsVirtualTerminal) {
    
    [System.Collections.Generic.List[ScriptBlock]]$global:Prompt = @(
        {  "`t" }
        {New-PromptText {Get-Elapsed} -ErrorBackgroundColor DarkRed -ErrorForegroundColor White -ForegroundColor Black -BackgroundColor DarkGray  }
        {New-PromptText {Get-Date -f "T"} -ErrorBackgroundColor DarkRed -ErrorForegroundColor White -ForegroundColor Black -BackgroundColor Gray  }
        {  "`n" }
        { if ($Global:IsAdmin) {New-PromptText {"ADMIN"} -BackgroundColor DarkRed -ForegroundColor Yellow}else {""} }
        {New-PromptText {$Env:COMPUTERNAME} -ForegroundColor Red -BackgroundColor Yellow}
        {New-PromptText {$(Convert-Path -Path $(Get-Location))} -ForegroundColor White -BackgroundColor 'DarkBlue'}
    )

    $Script:PowerLinePrompt = $global:Prompt
    Set-PowerLinePrompt -Prompt $global:Prompt -PowerLineFont -Title { "{0} ({1})" -f (Convert-Path $pwd), $pwd.Provider.Name } 

} else {

    function prompt {

        #Write-Host("[$($env:computername)][$(get-location)]")  
        $host.UI.RawUI.WindowTitle = $($env:computername)
        if ($IsAdmin) {  
            Write-Host '[' -NoNewline -ForegroundColor Gray
            Write-Host 'ADMIN' -NoNewline -ForegroundColor Red
            Write-Host ']' -NoNewline -ForegroundColor Gray
        }
  
        Write-Host '[' -NoNewline -ForegroundColor Gray
        Write-Host $($env:computername) -NoNewline -ForegroundColor Yellow
        Write-Host '][' -NoNewline -ForegroundColor Gray
        Write-Host $(Convert-Path -Path $(Get-Location).Path) -NoNewline -ForegroundColor Green
        Write-Host ']' -NoNewline -ForegroundColor Gray

        return "#"
        
    }
}




