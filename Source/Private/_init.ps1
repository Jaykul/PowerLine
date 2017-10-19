#!/usr/bin/env powershell
using namespace System.Management.Automation
using namespace System.Collections.Generic
using namespace PoshCode.Pansies

Add-Type @'
using System;
using System.Management.Automation;
public class EmptyStringAsNullAttribute : ArgumentTransformationAttribute
{
    public override object Transform(EngineIntrinsics engineIntrinsics, object inputData)
    {
        if (inputData is string && ((string)inputData).Length == 0)
        {
            return null;
        }
        else
        {
            return inputData;
        }
    }
}
'@

# Ensure the global prompt variable exists and is typed the way we expect
[System.Collections.Generic.List[ScriptBlock]]$Global:Prompt = [ScriptBlock[]]@(
    if(Test-Path Variable:Prompt) {
        $Prompt | ForEach-Object { $_ }
    }
)

Add-MetadataConverter @{ [char] = { "'$_'" } }
