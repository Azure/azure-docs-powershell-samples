## Description

<!-- Include a brief description of your changes. -->

## Checklist

<!--
    Filling in this checklist is mandatory! If you don't, your pull request
    will be rejected without further review. Checklists must be completed
    within 7 days of PR submission.

    To check a box in markdown, make sure that it is formatted as [X] (no whitespace).
    Not formatting checkboxes correctly may break automated tools and delay PR processing.
-->

### Required

- [ ] This pull request was tested on __both of__:
  - [ ] PowerShell 5.1 (Windows)
  - [ ] PowerShell 6.x ([Latest PowerShell](https://github.com/PowerShell/PowerShell/releases))
- [ ] The scripts in this pull request use only `Az` commands.
- [ ] Scripts do not contain static passwords or other secret tokens.
- [ ] All Azure resource identifiers which must be universally unique are guaranteed to be so.

### Testing information

<!--
    Each testing environment is a triplet:

        Platform, PowerShell version, Az version

    Copy/paste and fill in the following block for as many combinations of the above as you tested on.
-->

Platform:

Powershell version: `$PSVersionTable.PSVersion`

Az version: `(Get-InstalledModule -Name Az).Version`
