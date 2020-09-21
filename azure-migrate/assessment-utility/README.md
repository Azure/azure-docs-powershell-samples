
# AssessmentUtility

1. A prototype PowerShell script (AzureMigrateAssessmentCreationUtility.ps1) used to automate assessment creation in Azure Migrate: Server Assessment tool.
2. A PowerBI template to visualize and compare cost estimates of moving to Azure VMs

## Overview

[Azure Migrate: Server Assessment](https://docs.microsoft.com/en-us/azure/migrate/migrate-services-overview#azure-migrate-server-assessment-tool) is a Microsoft solution used to discover and assesses on-premises VMware VMs, Hyper-V VMs, and physical servers for migration to Azure.

Currently, users use the Azure Portal to [create a group of machines](https://docs.microsoft.com/en-us/azure/migrate/how-to-create-a-group#create-a-group-manually), and [create assessments on the group](https://docs.microsoft.com/en-us/azure/migrate/how-to-create-assessment). To compare cost estimates in Azure using combinations of sizing criteria, Reserved Instances and Hybrid benefits, users need to create and compare across multiple assessments. This utility helps automate these activities.

## How to Use

### Requirements

To use this utility the following are required:

1. **Azure Migrate Project:** An Azure Migrate project must already have been created.
    - If you are using the Azure Migrate appliance as a discovery source, the appliance should be deployed and successfully collecting data.
    - If you are using the CSV Import as a discovery source, the import should already be successfully done. 
2. **Azure User Account:** The powershell script uses the Azure Migrate REST APIs. To authorize the API calls, you need to make sure that you are connected to Azure with a user account that can access your Azure Migrate project.
3. **PowerShell Version:** It's strongly recommended you install the [latest version of PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) available for your operating system.
4. **Azure PowerShell Module:** The script relies on basic [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.3.0) functionality to connect to your subscription. It checks for the presence of an up-to-date install of the standard Azure PowerShell module to do this.
> Azure [Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) is a convenient alternative to installing and maintaining the required software on a local machine.

### Download the Utility

- Go to: <https://github.com/rajosh/AssessmentUtility>
- Click **Code** and then click **Download ZIP.**
- Extract the contents of the ZIP file to the directory you want to work in.

### Use the Utility

Start a PowerShell terminal, and connect to your Azure account with access to the Azure Migrate project:

```powershell
Connect-AzAccount
```

Navigate to the folder where you extracted the ZIP file and access the script:

```powershell
. .\AzureMigrateAssessmentCreationUtility.ps1
```

You are all ready to get started. If you already have discovered servers in your Azure Migrate project, type the following cmdlet to know the Azure Migrate assessment project name
```powershell
Get-AzureMigrateAssessmentProject -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName
```

Type the following cmdlet to create multiple assessments:

```powershell
New-AssessmentCreation -subscriptionId "4bd2aa0f-2bd2-4d67-91a8-5a4533d58600" -resourceGroupName "rajosh-rg" -assessmentProjectName "rajoshSelfHost-Physical92c3project" -discoverySource "Appliance"

$subscriptionId = "<your subscription ID>"
$resourceGroupName = "<your resource group name>"
$assessmentProjectName = "<your assessment project name>"
$discoverySource = "<the discovery source you used to discover servers in the project- Appliance or Import>"
```
> If you're unsure what the subscription ID and resource group values should be, navigate to the Azure portal, browse to your Azure Migrate project, click through to server assessment and expand the "essentials" section. You'll see both listed there.

Other cmdlets available in the script:
```powershell
# Create a new Group and all all machines in the project
$group = New-Group-Add-Machines -token $token -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -assessmentProjectName $assessmentProjectName -discoverySource $discoverySource -groupName $groupName

# Get status of an update operation to group
$group = Get-GroupStatus -token $token -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -assessmentProjectName $assessmentProjectName -groupName $groupName

# Get group details
$group = Get-Group token $token -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -assessmentProjectName $assessmentProjectName -groupName $groupName

# Export Assessments in local .xlsx files
Export-Assessment -token $token -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -assessmentProjectName $assessmentProjectName -groupName $group.name -assessmentName $assessmentName

# Get Authentication token
Get-AccessToken
```

### Modify the Utility
There are two .json files that are used for configuring the utility:
-**CommonAssessmentProperties.json**: 
 This file has all the common assessment properties that will be used to create the assessments and you can change these to configure the assessments.

-**AssessmentCombinations.json**:
 This file has all the assessment properties for which multiple assessments will be created. Currently it is configured for 12 different combinations of Reserved instances, Azure Hybrid Benefit and Sizing critera.

### Use the PowerBI template


## Known Issues / Troubleshooting

- **Token expiry:** If you receive issues related to token expiry, run the Connect-AzAccount command to login to Azure again or run the Get-AccessToken command to get a fresh token.
- **Assessment properties dependencies:** If you receive invalid parameters because of Assessment properties, please ensure that you are using  the valid combinations as in the Azure portal.
- **Time taken to create a new group and add all machines:** This function might take a little longer at times if you are running it on a project with more than 10000 machines.
- **Method Not Allowed:** If you are getting an error with Status code 405 while creating assessment, please check the status on the portal for these assessments. You can get this when you are trying to call the assessment creation function and the status of a pre existing assessment with the same name is not Ready. Please wait till the assessment status is ready before calling the New-AssessmentCreation function.
- **Assessment Export failing:** First, please check the status on the portal for these assessments. If teh export is being attempted when the assessment is not ready, the export function might not work as expected. Please wait till the assessment status is ready before calling the Export-Assessment function.

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit <https://cla.microsoft.com>.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Legal Notices

Microsoft and any contributors grant you a license to the Microsoft documentation and other content in this repository under the [Creative Commons Attribution 4.0 International Public License](https://creativecommons.org/licenses/by/4.0/legalcode), see the [LICENSE](LICENSE) file, and grant you a license to any code in the repository under the [MIT License](https://opensource.org/licenses/MIT), see the [LICENSE-CODE](LICENSE-CODE) file.

Microsoft, Windows, Microsoft Azure and/or other Microsoft products and services referenced in the documentation may be either trademarks or registered trademarks of Microsoft in the United States and/or other countries. The licenses for this project do not grant you rights to use any Microsoft names, logos, or trademarks. Microsoft's general trademark guidelines can be found at <http://go.microsoft.com/fwlink/?LinkID=254653>.

Privacy information can be found at <https://privacy.microsoft.com/en-us/>

Microsoft and any contributors reserve all others rights, whether under their respective copyrights, patents, or trademarks, whether by implication, estoppel or otherwise.

## Disclaimer

The sample scripts are not supported under any Microsoft standard support program or service. The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
