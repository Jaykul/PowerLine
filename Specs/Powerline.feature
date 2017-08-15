Feature: PowerLine Prompt
    As a PowerShell user
    I want to be able to customize my prompt with colors
    So that I can get the right information

    As a PowerShell Module author
    I want to be able to add information to the user's prompt
    So that my users can automatically get the right information

    Background:
        Given I have imported PowerLine

    Scenario: PowerLine exports a $Prompt variable ArrayList of scripts
        When I have imported PowerLine
        Then the $Prompt variable is an ArrayList

    Scenario: PowerLine exports a $PowerLineColors array of RgbColors
        When I have imported PowerLine
        Then the $PowerLineColors variable is an RgbColor[]

    Scenario: PowerLine defines a prompt function
        When I have imported PowerLine
        Then the prompt function processes the $Prompt blocks
        And the prompt function returns a string
