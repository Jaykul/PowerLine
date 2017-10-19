# These are not really steps!
# This is the deffinition of the Must assertion for Pester tests.

function Must {
    [CmdletBinding(DefaultParameterSetName='equal', HelpUri='http://go.microsoft.com/fwlink/?LinkID=113423', RemotingCapability='None')]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [psobject]
        ${InputObject},

        [Switch]
        $Not,

        [Switch]
        $All,

        [Switch]
        $Any,

        [Parameter(Position=0)]
        [AllowEmptyString()][AllowNull()]
        [System.Object]
        ${Property},

        [Parameter(Position=1)]
        [AllowEmptyString()][AllowNull()]
        [System.Object]
        ${Value},

        [Parameter(ParameterSetName='equal', Mandatory=$true)]
        [Alias('IEQ','BeEqualTo','Equal')]
        [switch]
        ${EQ} ,

        [Parameter(ParameterSetName='equal (case-sensitive)', Mandatory=$true)]
        [Alias('BeExactlyEqualTo','EqualExactly')]
        [switch]
        ${CEQ},

        [Parameter(ParameterSetName='not equal', Mandatory=$true)]
        [Alias('INE','NotBeEqualTo','NotEqual')]
        [switch]
        ${NE},

        [Parameter(ParameterSetName='not equal (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeExactlyEqualTo','NotExactlyEqual')]
        [switch]
        ${CNE},

        [Parameter(ParameterSetName='be greater than', Mandatory=$true)]
        [Alias('IGT','BeGreaterThan')]
        [switch]
        ${GT},

        [Parameter(ParameterSetName='be greater than (case-sensitive)', Mandatory=$true)]
        [switch]
        [Alias('BeExactlyGreaterThan')]
        ${CGT},

        [Parameter(ParameterSetName='be less than', Mandatory=$true)]
        [Alias('ILT','BeLessThan')]
        [switch]
        ${LT},

        [Parameter(ParameterSetName='be less than (case-sensitive)', Mandatory=$true)]
        [Alias('BeExactlyLessThan')]
        [switch]
        ${CLT},

        [Parameter(ParameterSetName='not be less than', Mandatory=$true)]
        [Alias('NotBeLessThan','IGE')]
        [switch]
        ${GE},

        [Parameter(ParameterSetName='not be less than (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeExactlyLessThan')]
        [switch]
        ${CGE},

        [Parameter(ParameterSetName='not be greater than', Mandatory=$true)]
        [Alias('ILE','NotBeGreaterThan')]
        [switch]
        ${LE},

        [Parameter(ParameterSetName='not be greater than (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeExactlyGreaterThan')]
        [switch]
        ${CLE},

        [Parameter(ParameterSetName='be like', Mandatory=$true)]
        [Alias('ILike','BeLike')]
        [switch]
        ${Like},

        [Parameter(ParameterSetName='be like (case-sensitive)', Mandatory=$true)]
        [Alias('BeExactlyLike')]
        [switch]
        ${CLike},

        [Parameter(ParameterSetName='not be like', Mandatory=$true)]
        [Alias('NotBeLike','INotLike')]
        [switch]
        ${NotLike},

        [Parameter(ParameterSetName='not be like (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeExactlyLike')]
        [switch]
        ${CNotLike},

        [Parameter(ParameterSetName='match', Mandatory=$true)]
        [Alias('IMatch')]
        [switch]
        ${Match},

        [Parameter(ParameterSetName='match (case-sensitive)', Mandatory=$true)]
        [Alias('MatchExactly')]
        [switch]
        ${CMatch},

        [Parameter(ParameterSetName='not match', Mandatory=$true)]
        [Alias('INotMatch')]
        [switch]
        ${NotMatch},

        [Parameter(ParameterSetName='not match (case-sensitive)', Mandatory=$true)]
        [Alias('NotMatchExactly')]
        [switch]
        ${CNotMatch},

        [Parameter(ParameterSetName='contain', Mandatory=$true)]
        [Alias('IContains')]
        [switch]
        ${Contains},

        [Parameter(ParameterSetName='contain (case-sensitive)', Mandatory=$true)]
        [Alias('ContainsExactly','ContainExactly')]
        [switch]
        ${CContains},

        [Parameter(ParameterSetName='not contain', Mandatory=$true)]
        [Alias('INotContains')]
        [switch]
        ${NotContains},

        [Parameter(ParameterSetName='not contain (case-sensitive)', Mandatory=$true)]
        [Alias('NotContainsExactly','NotContainExactly')]
        [switch]
        ${CNotContains},

        [Parameter(ParameterSetName='be in', Mandatory=$true)]
        [Alias('IIn','BeIn')]
        [switch]
        ${In},

        [Parameter(ParameterSetName='be in (case-sensitive)', Mandatory=$true)]
        [Alias('BeInExactly')]
        [switch]
        ${CIn},

        [Parameter(ParameterSetName='not be in', Mandatory=$true)]
        [Alias('INotIn','NotBeIn')]
        [switch]
        ${NotIn},

        [Parameter(ParameterSetName='not be in (case-sensitive)', Mandatory=$true)]
        [Alias('NotBeInExactly')]
        [switch]
        ${CNotIn},

        [Parameter(ParameterSetName='be of type', Mandatory=$true)]
        [Alias('BeOfType')]
        [switch]
        ${Is},

        [Parameter(ParameterSetName='not be of type', Mandatory=$true)]
        [Alias('NotBeOfType')]
        [switch]
        ${IsNot},

        [Parameter(ParameterSetName='be null or empty', Mandatory=$true)]
        [switch]
        ${BeNullOrEmpty}
    )
begin
{
    $NoProperty = $False

    try {

        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }

        $null = $PSBoundParameters.Remove("Not")
        $null = $PSBoundParameters.Remove("All")
        $null = $PSBoundParameters.Remove("Any")

        $ForEachObjectCommand = $ExecutionContext.InvokeCommand.GetCommand('ForEach-Object', [System.Management.Automation.CommandTypes]::Cmdlet)

        if (!$PSBoundParameters.ContainsKey('Value'))
        {
            $NoProperty = $True
            if($PSBoundParameters.ContainsKey('BeNullOrEmpty')) {
                $Property = "Value"
            } else {
                $Value = $PSBoundParameters['Value'] = $PSBoundParameters['Property']
                $Property = $PSBoundParameters['Property'] = "Value"
            }

            # if($PSBoundParameters.ContainsKey('InputObject'))
            # {
            #     $InputObject = $PSBoundParameters['InputObject'] = @{ "Value" = $InputObject }
            # }
        }

        $Cmdlet = $PSCmdlet
        function Throw-Failure {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
                [bool]$Result,

                [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
                [AllowNull()]
                [AllowEmptyString()]
                [Alias("Value")]
                $InputValue = $InputObject,

                [Parameter()]
                [String]$Operator = $Cmdlet.ParameterSetName,

                [Switch]
                $Not,

                [Switch]
                $All,

                [Switch]
                $Any,

                [Switch]
                $BeNullOrEmpty
            )
            begin {
                $TestResults = @()
                $FailedValues = @()
                $PassedValues = @()
            }
            process {
                Write-Verbose "Tested $($InputValue.$Property), Result: $Result "
                $TestResults += $Result
                if(!$Result) {
                    $FailedValues += $InputValue.$Property
                } else {
                    $PassedValues += $InputValue.$Property                    
                }
            } 
            end  {
                $TestResult = if($BeNullOrEmpty -and 0 -eq $TestResults.Count) {
                    Write-Verbose "EMPTY!"
                    $True
                } elseif($All) {
                    $TestResults -NotContains $False
                } elseif($Any) {
                    $TestResults -Contains $True
                } else {
                    $TestResults -NotContains $False
                }

                Write-Verbose "Result: $(if($NOT){"NOT "})$TestResult"

                if($Not) {
                    $FailedValues, $PassedValues = $PassedValues, $FailedValues
                    $TestResult = !$TestResult
                }
                Write-Verbose "Passed: {$( $PassedValues  -join ", ")} | Failed: {$( $FailedValues  -join ", ")} | Result: $TestResult"

                if(!$TestResult) {
                    $message = @("TestObject", $Property, "must")
                    $message += if($Not) { "not" }
                    $message += if($All) { "all" }
                    $message += if($Any) { "any" }
                    $message += $Operator
                    if(!$BeNullOrEmpty) {
                        $message += "'$($Value -join "','")'"
                    }
                    $message += if($null -eq $FailedValues) {
                                    '-- Actual: $null'
                                } elseif(0 -eq $FailedValues.Count) {
                                    '-- Actual: {}'
                                } elseif(1 -le $FailedValues.Count) {
                                    "-- Actual: {" + ( $FailedValues  -join ", ") + "}"
                                } elseif($null -eq $FailedValues[0]) {
                                    '-- Actual: $null'
                                } elseif($FailedValues[0].ToString() -eq $FailedValues[0].GetType().FullName ) {
                                    "-- Actual: '" + ( $FailedValues | Out-String ) + "'"
                                } else {
                                    "-- Actual: '" + $FailedValues[0] + "'"
                                }

                    $exception = New-Object AggregateException ($message -join " ")
                    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, "FailedMust", "LimitsExceeded", $message
                    $Cmdlet.ThrowTerminatingError($errorRecord)
                }                
            }
        }

        $Parameters = @{} + $PSBoundParameters
        $null = $Parameters.Remove("InputObject")

        if($Parameters.ContainsKey('BeNullOrEmpty')) {
            Write-Verbose "Testing $Property to See if it's null or empty"
            Write-Verbose "InputObject $InputObject"
            $InputObject | ft | out-string | % Trim | Write-Verbose
            $scriptCmd = {& $ForEachObjectCommand {
                                [PSCustomObject]@{ 
                                    Result = if($null -eq $InputObject){
                                                Write-Verbose "NULL Object, no $Property to look at"
                                                $false
                                             } elseif($InputObject.$Property -is [System.Collections.IList]) {
                                                Write-Verbose "List $Property"
                                                0 -eq ($InputObject.$Property).Count
                                             } elseif($InputObject.$Property -is [string] ) {
                                                Write-Verbose "String $Property"
                                                [string]::IsNullOrEmpty($InputObject.$Property)
                                             } else {
                                                # Write-Verbose "Is NULL? OBJECT"
                                                # Write-Debug ($InputObject.PSTypeNames -join "`n")
                                                Write-Verbose "Is NULL? PROPERTY: $Property"
                                                # Write-Debug ($InputObject."$Property".PSTypeNames -join "`n")
                                                 
                                                $null -eq $InputObject."$Property"
                                                Write-Verbose "Is NULL? PROPERTY: $Property"
                                             }  
                                    Value = $InputObject
                                } 
                            } | Throw-Failure -Operator $PSCmdlet.ParameterSetName -Any:$Any -All:$All -Not:$Not -BeNullOrEmpty:$BeNullOrEmpty
                         }
        } else {

            $scriptCmd = {& $ForEachObjectCommand {
                                Write-Verbose "Input Object is a $($InputObject.GetType().FullName)"
                                Write-Verbose "Parameters: `n$($Parameters | Out-String)"
                                [PSCustomObject]@{ 
                                    Result = ($null -ne (Where-Object -Input $InputObject @Parameters))
                                    Value = $InputObject
                                }
                            } | Throw-Failure -Operator $PSCmdlet.ParameterSetName -Any:$Any -All:$All -Not:$Not -BeNullOrEmpty:$BeNullOrEmpty
                         }
        }

        $NeedPipelineInput = $PSCmdlet.MyInvocation.ExpectingInput
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
        $NeedPipelineInput = $False
        if($NoProperty) {
            Write-Verbose "NoProperty. Packing InputObject"
            $InputObject = @{ "Value" = $InputObject }
        }
        $steppablePipeline.Process($InputObject)

    } catch {
        throw
    }
}
end
{
    try {
        if($NeedPipelineInput -and !${BeNullOrEmpty} -and !$Not) {
            Write-Verbose "Was ExpectingInput and got none"
            ForEach-Object $ThrowMessage -Input $Null
        }
        $steppablePipeline.End()
    } catch {
        throw
    }
}
<#
.ForwardHelpTargetName Where-Object
.ForwardHelpCategory Cmdlet
#>
}
