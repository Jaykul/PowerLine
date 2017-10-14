@{

# Script module or binary module file associated with this manifest.
RootModule = 'PowerLine.psm1'

# Version number of this module.
ModuleVersion = '3.0.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'bf97d03d-439c-4b5d-bab1-0024461a7a70'

# Author of this module
Author = 'Joel Bennett'

# Company or vendor of this module
CompanyName = 'HuddledMasses.org'

# Copyright statement for this module
Copyright = '(c) 2016 Joel Bennett. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Classes for richer output and prompts'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.0.0'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @("PowerLine.types.ps1xml")

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

RequiredModules = @(
    @{ModuleName="Pansies"; ModuleVersion="1.2.1"}
    @{ModuleName="Configuration"; ModuleVersion="1.0.4"}
)
# RequiredAssemblies = "lib\PowerLine.dll"

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Set-PowerLinePrompt', 'Add-PowerLineBlock', 'Remove-PowerLineblock', 'New-PromptText', 'Get-Elapsed', 'Get-SegmentedPath', 'Get-ShortenedPath', 'Test-Success', 'Test-Elevation'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
# CmdletsToExport = '*'

# Variables to export from this module
# VariablesToExport = 'PowerLineColors'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = 'New-PowerLineBlock'

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{
    PSData = @{
        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("Prompt","ANSI","VirtualTerminal")

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/Jaykul/PowerLine/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/Jaykul/PowerLine'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '
        3.0.0: Total refactor to simplify the array.
            Add a dependency on the Configuration module
            Uses $Prompt (an array of ScriptBlock)
            Uses $Prompt.Colors (an array of PoshCode.Pansies.RgbColor)
            Removed -UseAnsiEscapes -- with Pansies, we always use Ansi escape sequences
            Added -FullColor -- by default, use only 16 Colors [System.ConsoleColor]
            Support storing prompt options so we can restore the prompt upon import
        2.3.1: Fixed the missing New-PowerLineBlock alias for backward compatibility with 2.2.0
        2.3.0: Switch to using Pansies to get support for full RGBColor with css style colors, like: #336699
        2.2.0: Add -RestoreVirtualTerminal switch for controlling if the prompt should reenable VT processing after each command
        2.1.0: Add -UseAnsiEscapes switch for controlling the use of VT escape sequences (in preparation for adding a Write-Host adapter)
        Add pre-compiled assembly for .Net Core
        '
    } # End of PSData hashtable
} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

