## Description

<!-- Please include a brief description of your changes. -->

## Checklist

<!--
    Filling in this checklist is mandatory! If you don't, your pull request
    will be rejected without further review. Checklists must be completed
    within 7 days of PR submission.

    Checkboxes in the REQUIRED section must be green. Even if you are only updating
    an existing script, you must follow the REQUIRED steps. Checkboxes in OPTIONAL
    should only be checked if they apply to this PR/your service.

    To check a box in markdown, make sure that it is formatted as [X] (no whitespace).
    Not formatting checkboxes correctly may break automated tools.
-->

### Required

- [ ] The scripts in this pull request were tested on both PowerShell 5.1 and the latest non-preview Powershell. ([Latest PowerShell](https://github.com/PowerShell/PowerShell/releases))
- [ ] The scripts in this pull request were tested with the latest version of the `Az` module. ([Latest version](https://docs.microsoft.com/en-us/powershell/azure/release-notes-azureps))
- [ ] The scripts in this pull request use only `Az` commands.
  - [ ] I have an exemption (explained in the __Optional__ section)
- [ ] These scripts do not contain static passwords or other secret tokens.
- [ ] All prerequisite resources are listed in comments at the top of the scripts.
- [ ] All required imports are at the top of the script, below prerequisites.
- [ ] All user-set variables are at the top of the script, below imports.
- [ ] All identifiers which must be universally unique are guaranteed to be so.
- [ ] All scripts use UNIX-style line endings (LF) ([Instructions](https://help.github.com/en/articles/dealing-with-line-endings))

### Optional
  
- [ ] These scripts require using AzureRM because:
  - [ ] They use a preview module only available for AzureRM (please name preview modules and versions):
  - [ ] They use service(s) not fully supported in Az (please list services):
  - [ ] The service has an exemption from the Az requirement (please list services):
  - [ ] They use the classic deployment model
  - [ ] They use Azure Stack
  - [ ] Other (please explain):

