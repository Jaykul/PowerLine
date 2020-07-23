if (Get-Module EzTheme -ErrorAction SilentlyContinue) {
    Get-ModuleTheme | Set-PowerLineTheme
}
