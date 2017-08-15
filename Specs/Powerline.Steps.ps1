Given 'I have imported (?<ModuleName>\S+)' {
    param($ModuleName)
    Import-Module $ModuleName -Scope Global
}

Then 'the \$(?<VariableName>\S+) variable is an (?<Type>\S+)' {
    param($VariableName, $Type)
    (Get-Variable $VariableName -ValueOnly).PSTypeNames | Must -Any -Match "$Type|.*\.$Type"
}

Then 'the prompt function processes the \$Prompt blocks' {
    Set-TestInconclusive
}

Then 'the prompt function returns a string' {
    Set-TestInconclusive
}