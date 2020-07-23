# Use this file to override the default parameter values used by the `Build-Module`
# command when building the module (see `Get-Help Build-Module -Full` for details).
@{
    ModuleManifest           = "Source/PowerLine.psd1"
    OutputDirectory          = "../"
    VersionedOutputDirectory = $true
    CopyDirectories          = @('Examples','PowerLine.format.ps1xml','Configuration.psd1')
    Postfix                  = "postfix.ps1"
}
