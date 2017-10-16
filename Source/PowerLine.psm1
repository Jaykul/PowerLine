$script:PowerLineRoot = $PSScriptRoot

(Join-Path $PSScriptRoot Private\*.ps1 -Resolve -ErrorAction SilentlyContinue).ForEach{ . $_ }
(Join-Path $PSScriptRoot Public\*.ps1 -Resolve).ForEach{ . $_  }

Export-ModuleMember -Function "*-*"