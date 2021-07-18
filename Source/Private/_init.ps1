#!/usr/bin/env powershell
using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace PoshCode.Pansies

# Ensure the global prompt variable exists and is typed the way we expect
[System.Collections.Generic.List[ScriptBlock]]$Global:Prompt = [ScriptBlock[]]@(
    if(Test-Path Variable:Prompt) {
        $Prompt | ForEach-Object { $_ }
    }
)

Add-MetadataConverter @{ [char] = { "'$_'" } }


# [Entities]::ExtendedCharacters['FileSystem'] = [PoshCode.Pansies.Entities]::Decode("$fg:DarkGoldenrod1&nf-custom-folder_open;$fg:Clear")
# [Entities]::ExtendedCharacters['RgbColor'] = [PoshCode.Pansies.Entities]::Decode("$fg:Violet&nf-fae-palette_color;$fg:Clear")
# [Entities]::ExtendedCharacters['WSMan'] = [PoshCode.Pansies.Entities]::Decode("$fg:DodgerBlue4&nf-custom-folder_config;$fg:Clear")
# [Entities]::ExtendedCharacters['Certificate'] = [PoshCode.Pansies.Entities]::Decode("$fg:BlueViolet&nf-mdi-certificate;$fg:Clear")
# [Entities]::ExtendedCharacters['Alias'] = [PoshCode.Pansies.Entities]::Decode("&nf-mdi-guy_fawkes_mask;")
# [Entities]::ExtendedCharacters['Variable'] = [PoshCode.Pansies.Entities]::Decode("$fg:Green4&nf-fa-dollar;$fg:Clear")
# [Entities]::ExtendedCharacters['Function'] = [PoshCode.Pansies.Entities]::Decode("$fg:DeepPink3&nf-mdi-function;$fg:Clear")
# [Entities]::ExtendedCharacters['Registry'] = [PoshCode.Pansies.Entities]::Decode("$fg:Aquamarine4&nf-ple-pixelated_squares_big;$fg:Clear")
# [Entities]::ExtendedCharacters['Environment'] = [PoshCode.Pansies.Entities]::Decode("$fg:DodgerBlue4&nf-dev-terminal;$fg:Clear")
