using namespace System.Collections.Generic

Given 'I have imported (?<ModuleName>\S+)' {
    param($ModuleName)
    Import-Module $ModuleName -Scope Global
}

Then '\$(?<VariableName>\S+) is an? (?<Type>\S+)' {
    param($VariableName, $Type)
    Get-Variable $VariableName -ValueOnly | Must -BeOfType $Type
}

Then '\$(?<VariableName>[a-zA-Z]+)(?:\.(?<Property>\S+))? has a (?<Type>\S+)' {
    param($VariableName, $Property, $Type)
    Must -Input (Get-Variable $VariableName -ValueOnly).($Property) -BeOfType $Type
}

Then 'the prompt function processes the \$Prompt blocks' {
    $Something = $Prompt
    $Global:Prompt = { [int]::MaxValue }, { [int]::MinValue }
    $result = prompt
    $Global:Prompt = $Something
    $result | Must -match "$([int]::MaxValue).*$([int]::MinValue)"
}

Then 'the prompt function returns a string' {
    $Something = $Prompt
    $Global:Prompt = { Get-Random -Min 1000000 -Max 1000001 }
    $result = prompt
    $Global:Prompt = $Something
    $result | Must -BeOfType [string]
}
