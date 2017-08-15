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

$script:PowerLineRoot = $PSScriptRoot


[List[ScriptBlock]]$Global:Prompt = if(Test-Path Variable:Prompt) {
    $Prompt | ForEach-Object { $_ }
} else {
    { $MyInvocation.HistoryId }, { Get-SegmentedPath }
}

if(!(Test-Path Variable:PowerLineColors)) {
    [RgbColor[]]$Script:PowerLineColors = "xt39","xt75","xt32","xt26","xt33","xt12","xt20","xt19"

    $Prompt.Add({"`n"})
    $Prompt.Add({[Text]@{Text= "I `e[32m&hearts;`e[30m PS"; Bg = "White"; Fg = "Black"}})
}
