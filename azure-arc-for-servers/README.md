# Managing Credentials on Azure Arc for Servers

Azure Arc, announced at [Microsoft Ignite 2019][Ignite], extends the Azure management capabilities to infrastructures across on-premises, multi-cloud, and edge devices.
Azure Arc for Servers is one of Azure Arc technologies that enable you to manage your on-prem servers through a unified Azure control plane such as Azure Portal, PowerShell cmdlet, REST API as if they were running in Azure IaaS.
For more information, see [What is Azure Arc for Servers][overview].

## Connecting Your Machine to Azure

You need to download the agent package and install it on your machine, which can be your desktop, laptop, or virtual machines. It works on Windows or Linux OSs.
Please see [this QuickStart guidance for the setup][quickstart].
After connect your machine to Azure (_called connected machine_ here),
you can perform management tasks as described in the [Azure Arc document][scenario] including assigning Azure policies for security compliance, monitoring your machine using Log Analysis, tagging your machines, etc.
Apart from that, you may want to develop an application that runs on the connected machines but needs to connect to your Azure services. As we know, one of the challenges while building cloud applications is to manage the credentials because they cannot be checked-in as a part of your code or stored in your dev box. Fortunately, Azure Arc for Servers makes it easy for you.

## Prerequisites

* Connect your machine to Azure as [mentioned above](#Connecting-Your-Machine-to-Azure)

  After connected to Azure, you can check the status by using the following command on your connected machine. The output will look like below.

  ```powershell
  /home/test> azcmagent show
  Resource Name          : myMachine
  Resource Group Name    : myRG
  Subscription ID        : 93d0692b-ec73-44c8-9d98-7bfba59c0316
  Tenant ID              : 72f988bf-86f1-41af-91ab-2d7cd011db47
  VM ID                  : 149672e9-6db8-4b33-a219-dda50ff88d64
  Location               : westeurope
  Agent Version          : 0.4.19305.023
  Agent Logfile          : /var/opt/azcmagent/log/himds.log
  Agent Status           : Connected
  Agent Last Heartbeat   : 05 Dec 19 01:36 UTC
  ```

  As you can see, the machine should be in the **Connected** state.

* Install [the PowerShell 7 Preview 6][ps7]

  This is mainly for leveraging the cool feature: SkipHttpErrorCheck in Web Cmdlets.

## Acquiring Azure Access Token

On the connected machine, you can request _Azure Hybrid Instance Metadata Service (himds)_ for Azure access token.
Once your app gets a token, it can be connected to your Azure services by passing the token in the Authorization header using the Bearer scheme as if from an Azure VM.
For example, assuming your app needs to connect to your Azure Cosmos DB, first you need to retrieve the connection string and other secrets stored in Azure Key Vault. The [sample code][kv] illustrates how to retrieve Azure access token from on Arc servers.

When you run the sample code, you may get the **AccessDenied** error.
This is because after you connect your machine to Azure, there is an identity created representing your machine, but you have not granted any permissions to your machine yet.
Therefore, even though you successfully retrieve the token, this token can do nothing.

## Grant Permissions to Connected Machines

Next you need to grant your connected machine for a read permission to access to your Key Vault using Azure RBAC.
You can manage this access control through Azure portal, Azure CloudShell, or run the [sample code][permission] on your laptop, desktop or any of your machines.
Please note changing RBAC roles require you to be the owner or administer of your subscription.

## Retrieve Secrets from Azure Key Vault

Now you have completed the role assignment. You should be able to get the secrets stored in your Key Vault. With your Azure Cosmos DB Connection string, your app can start performing your business logic.

Other than getting Azure access token, you can get the metadata information including subscription, resourceGroup, location, etc., where your  machine connected to using the REST API, just like on Azure VMs, for example,

```powershell
Invoke-WebRequest -Uri http://localhost:40342/metadata/instance?api-version=2019-11-01 -Headers @{Metadata="True"}
```

## Feedback

Give it a try and welcome your feedback, bugs and feature requests for Azure Arc for Servers [through the Azure Arc forum][uv]!

[Ignite]:https://youtu.be/jnUiJi4hts4?t=869
[overview]:https://docs.microsoft.com/azure/azure-arc/servers/overview
[quickstart]:https://docs.microsoft.com/azure/azure-arc/servers/quickstart-onboard-powershell
[scenario]:https://docs.microsoft.com/azure/azure-arc/servers/overview#supported-scenarios
[kv]:./get-kvsecrets-from-arc-servers.ps1
[ps7]:https://devblogs.microsoft.com/powershell/powershell-7-preview-6/
[permission]:./grant-permission.ps1
[uv]:https://feedback.azure.com/forums/925690-azure-arc
