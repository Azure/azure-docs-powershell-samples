# you can run anywhere
param(
    [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
    [string] $machineName,
    [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
    [string] $subscriptionId,
    [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
    [string] $resourceGroup,
    [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
    [string] $keyVaultName,
    [string] $apiVersion = '2019-03-18-preview'
)

function Get-AzAccountAccessToken()
{
    if(-not (Get-Module Az)) {
        Import-Module Az
    }

    $audience ="https://management.core.windows.net/"       
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    $token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $audience).AccessToken
    return $token
}

function Set-KeyVaultAccessPolicy {
    [CmdletBinding()]
    param (
       [Parameter(Mandatory=$true)]
       [string] $machineName,
       [Parameter(Mandatory=$true)]
       [string] $subscriptionId,
       [Parameter(Mandatory=$true)]
       [string] $resourceGroup,
       [Parameter(Mandatory=$true)]
       [string] $keyVaultName,
       [Parameter(Mandatory=$true)]
       [string] $apiVersion
    )
    
    $machineUri= "https://management.azure.com/subscriptions/${subscriptionId}/resourcegroups/${resourceGroup}/providers/Microsoft.HybridCompute/machines/${machineName}?api-version=${apiVersion}"

    # get a token for the target audience. It's the ARM management
    $yourtoken= Get-AzAccountAccessToken
  
    # get the principal id of your connected machine
    $response = Invoke-RestMethod -Method Get -Uri $machineUri -Headers @{metadata='True'; Authorization="bearer $yourtoken"} -StatusCodeVariable status
    if ($status -eq '200')
    {
        $objectId = $response.identity.principalId
    }
    else 
    {
        throw  "unexpected response status code: $status"
    }

    # grant the access permission to your connected machine. 
    # Make sure you logon to the subscription where Key Vault resides
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -PermissionsToSecrets Get -ObjectId $objectId
}


Set-KeyVaultAccessPolicy -machineName $machineName -subscriptionId $subscriptionId -resourceGroup $resourceGroup -apiVersion $apiVersion -keyVaultName $keyVaultName
