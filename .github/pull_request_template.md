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
    Not formatting checkboxes correctly may break automated tools and delay PR processing.
-->

### Required

- [ ] This pull request was tested on __both of__:
  - [ ] PowerShell 5.1 (Windows)
  - [ ] The latest non-preview Powershell. ([Latest PowerShell](https://github.com/PowerShell/PowerShell/releases))
    - __PowerShell version__ (`$PSVersionTable.PSVersion`):
- [ ] This pull request was tested with the latest version of the `Az` module. ([Latest version](https://docs.microsoft.com/powershell/azure/release-notes-azureps))
  - __Az module version__ (`(Get-InstalledModule -Name Az).Version`): 
- [ ] The scripts in this pull request use only `Az` commands.
  - [ ] I have an exemption (explained in the __Optional__ section)
- [ ] Scripts do not contain static passwords or other secret tokens.
  - [ ] New passwords are automatically generated (by `New-Guid` or another secure RNG method)
  - [ ] Existing secrets are user-supplied
- [ ] All prerequisite resources are listed in comments at the top of the scripts.
- [ ] All required imports are at the top of scripts, below prerequisites.
- [ ] All user-set variables are at the top of scripts, below imports.
- [ ] All identifiers which must be universally unique are guaranteed to be so.
- [ ] All scripts use UNIX-style line endings (LF) ([Instructions](https://help.github.com/articles/dealing-with-line-endings))

### Optional

- [ ] User-set variables have initial values guaranteed to cause the script to fail.  
- [ ] This PR requires AzureRM because:
  - [ ] Scripts use a preview module only available for AzureRM
    - __List of preview modules and versions__:
  - [ ] Scripts use service(s) not fully supported in Az
    - __List of services__:
  - [ ] Touches services which have an exemption from the Az requirement
    - __List of services__:
  - [ ] Scripts use the classic deployment model
  - [ ] Scripts use Azure Stack
  - [ ] Other (please explain):

