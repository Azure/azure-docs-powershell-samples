# GitHub repo

## What's the issue and its impact?

Microsoft recently mitigated an information-disclosure issue, [CVE-2021-42306](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-42306), to prevent private key data from being stored by some Azure services in the [keyCredentials](/graph/api/resources/keycredential?view=graph-rest-1.0) property of the Azure Active Directory (Azure AD) [Application](/graph/api/resources/application?view=graph-rest-1.0) and/or [Service Principal](/graph/api/resources/serviceprincipal?view=graph-rest-1.0), and prevent reading of private key data previously stored in the keyCredentials property.

The `keyCredentials` property is used to configure an application’s authentication credentials. It's accessible to any user/service in the organization’s Azure AD tenant with read access to application metadata.

The property is designed to accept a certificate with public key for use in authentication, but certificates with private key data might also get incorrectly stored in the property. Access to private key data can lead to an elevation of privilege attack by allowing a user to impersonate the impacted Application or Service Principal.

This resulted in storing  **Unprotected Private Key** (UPK) with the certificate attached to the Azure AD applications created by Azure Migrate. Any user could use the exposed private key information in the tenant to impersonate as Azure Migrate appliance software and gain access to a subset of metadata (collected by the appliance) and the replication log storage account.

## What actions am I required to take?

Azure Migrate appliances that were registered after **11/02/2021 9:55 AM UTC** and had [Appliance configuration manager version 6.1.220.1 and above](/azure/migrate/migrate-appliance#check-the-appliance-services-version) are **not** impacted and do **not** require further action.

For Azure Migrate appliances registered prior to 11/02/2021 9:55 AM UTC or appliances where auto-update was disabled and registered after 11/02/2021 9:55 AM UTC, we recommend you execute the assessment script mentioned below to identify any impacted Azure AD applications and then perform the mitigation steps.

### Assessment script

The assessment script can help identify any impacted Azure AD applications associated with Azure Migrate within the tenant. Before executing the script, ensure the following prerequisites are met:

> [!NOTE]
>  You can run the script from any Windows server with internet connectivity.

### Prerequisites
1. Windows PowerShell version 5.1 or later installed.
1. .NET framework 4.7.2 or later installed.
1. The following URLs are accessible from the server:
   **Azure public cloud URLs**  
    - *.powershellgallery.com
    - login.microsoftonline.com
    - graph.windows.net
    - management.azure.com
    - *.azureedge.net
    - aadcdn.msftauth.net
    - aadcdn.msftauthimages.net
    - dc.services.visualstudio.com
    - aka.ms\*
    - download.microsoft.com/download
    - go.microsoft.com/*

> [!NOTE]
>  If there is a proxy server blocking access to these URLs, then update the proxy details to the system configuration before executing the script.

1. You need the following permissions on the Azure user account:

-  **Application.Read.All** permission at tenant level to enumerate the impacted Azure AD applications.
-  **Contributor** access on the Azure subscription(s) to enumerate the Azure Migrate resources associated with the impacted Azure AD applications.

### Execution instructions

1. Log in to any Windows server with the internet connectivity.
1. Download the .zip file with [assessment script](/azure/migrate/migrate-appliance#check-the-appliance-services-version) on the server.
1. Extract the contents from the .zip file and open Windows PowerShell as an Administrator.
1. Change the folder path to the location where the file was extracted.
1. Execute the script by running the following command:
`.\ AssessAzMigrateApps.ps1 -TenantID <provide your tenant ID>`
1. When prompted, log in to your Azure user account. The user account should have permissions listed in prerequisites above.
1. The script generates an assessment report with the details of the impacted Azure AD applications and associated Azure Migrate resources.

### What the assessments script does?

1. Connects to the tenant ID provided in the command using the Azure account; user provides to log in through the script.
1. Scans and finds all the impacted Azure AD applications with the unprotected private key.
1. Identifies the impacted Azure AD applications, associated with Azure Migrate.
1. Finds the Azure Migrate resources accessible to the currently logged in user across subscriptions within the tenant.
1. Maps the impacted Azure Migrate resources information to the impacted Azure AD applications found in Step 3.
1. Generates an assessment report with the information of the impacted Azure AD applications with the details of the associated Azure Migrate resources.

## Assessment report

The assessment report generated by the script contains the following columns:

**No** | **Column name** | **Description** |
--- | --- | ---|
1 |Azure AD application name | The names of the impacted Azure AD applications associated with Azure Migrate, containing one of the following suffixes: </br> -  resourceaccessaadapp </br> - agentauthaadapp </br>  -  authandaccessaadapp
2 |Azure AD application ID | The ID of the impacted Azure AD applications.
3 |User access to associated Migrate resources | Shows if the currently logged- in user has access to the associated Azure Migrate resources across subscriptions in the tenant.
4 |Subscription ID | The IDs of subscriptions where the currently logged in user could access the Azure Migrate resources.
5 |Resource Group | The name of the Resource Group where the Azure Migrate resources were created.
6 |Azure Migrate project name | The name of the Azure Migrate project where the Azure Migrate appliance(s) were registered.
7 |Azure Migrate appliance name | The name of the Azure Migrate appliance which created the impacted Azure AD application during its registration.
8 |Scenario | The scenario of the appliance deployed-VMware/Hyper-V/Physical or other clouds.
9 |Appliance activity status (last 30 days) | The information on whether the appliance was active in the last 30 days *(agents sent heartbeat to Azure Migrate services)*
10 |Appliance server hostname | The hostname of the server where the appliance was deployed.</br> *(This may have changed over time in your on-premises environment)*

### Recommendations

Based on the information you have from the script in the context of the currently logged in user. We recommend you take one of the following actions:

1. For rows, where column 3 (User access to associated Migrate resources) shows *Not accessible*, you can get the required permissions *(as stated in prerequisites above)* to enumerate missing information for Azure Migrate resources associated with the impacted Azure AD applications.
1. For inactive Azure Migrate projects and appliances that you don't intend to use in future, you can delete the impacted Azure AD applications.
1. For active Azure Migrate projects and appliances that you intend to use in future, you need to rotate the certificates on the impacted Azure AD applications using the mitigation script provided below.

## Mitigation script

After assessing the impacted Azure AD applications, you need to **execute the mitigation script on each Azure Migrate appliance in your organization's environment** *(check if you have Azure Migrate appliances in your environment from #github-repo)*. Before executing the script, ensure you have met the following prerequisites:

### Prerequisites

1. Windows PowerShell version 5.1 or later installed
1. Windows PowerShell running 64-bit version
1. .NET framework 4.7.2 or later installed.
1. The following URLs accessible from the server (In addition to the other [URLs](/azure/migrate/migrate-appliance#public-cloud-urls) you have already allowlisted for the appliance registration):
   **Azure public cloud URLs
   -  *.powershellgallery.com
   -  *.azureedge.net
   -  aadcdn.msftauthimages.net

> [!NOTE]
> If there is a proxy server configured on the appliance configuration manager, then update the proxy details to the system configuration before executing the script.*

1. You need the following permissions on the Azure user account:
   -  *Contributor’*access on the Azure subscription that has the Azure Migrate project the appliance is registered to.
   -  Owner permissions on the impacted Azure AD Application(s).
1. For appliances deployed to perform agentless replication of VMware VMs, if you have started replication for the first time in the project from Azure portal, we recommend you to wait for five minutes for the *Associate replication policy* job to complete before you can execute the script.

### Run the script

1. To run the script, you need to log in to the server hosting the Azure Migrate appliance.
1. Download the .zip file with [mitigation script]/azure/migrate/migrate-appliance#public-cloud-urls) on the appliance server.
1. Extract the contents from the .zip file and open Windows PowerShell as an Administrator.
1. Change the folder path to the location where the file was extracted.
1. Execute the script by running the following command:
`.\ AzureMigrateRotateCertificate.ps1`
1. When prompted, log in to your Azure user account. The user account should have permissions listed in prerequisites.
1. Wait for the script to execute success.

> [!NOTE]
>  After executing the mitigation script in all the appliances in your organization's environment, you can re-run the assessment script to confirm if you have mitigated all the impacted Azure AD applications.

### What the mitigation script does?

1. Fetches Key Vault name, certificate name and Azure AD App ID from Azure Migrate zip file Hub/configuration files on appliance server.
1. Deletes old certificate present in Key Vault and creates a new certificate with the same name.
1. Imports the certificate to appliance server in PFX format.
1. Deletes the old certificate in the impacted Azure AD App that removes the vulnerability of the private key misuse.
1. Attaches the public key of the certificate in CER format (that was generated in Step 2) to the Azure AD application.
1. Updates the Azure Migrate appliance software configuration files on appliance to use the new certificate and restarts the Azure Migrate appliance agents.

> ![NOTE]
>  If case of any issues during the execution of the above scripts, request assistance from Microsoft support. While creating support request follow the steps below:

1.	In the Summary field, provide the details as follows: [CVE-2021-42306](https://msrc.microsoft.com/update-guide/vulnerability/CVE-2021-42306) : <Issue summary>
1. Problem type: “Discovery and assessment”
1. Problem subtype: any one of the following
   -  Deployment issues with Azure Migrate appliance for VMware
   -  Deployment issues with Azure Migrate appliance for Hyper-V
   -  Deployment issues with Azure Migrate appliance for Physical
1. In the additional details section include whether issue is related to **Assessment script** or **Mitigation script**.
1. In case of an issue with script execution, please share the screenshot of the error.