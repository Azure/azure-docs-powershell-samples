# you can run anywhere

function Get-AzAccountAccessToken()
{
    if(-not (Get-Module Az.Accounts)) {
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
       [string] $apiVersion ="2019-08-15"
    )
    
    $machineUri= "https://management.azure.com/subscriptions/${subscriptionId}/resourcegroups/${resourceGroup}/providers/Microsoft.HybridCompute/machines/${machineName}?api-version=${apiVersion}"

    # get a token for the target audience. It's the ARM management
    $yourtoken= Get-AzAccountAccessToken
  
    # get the principal id of your connected machine
    $response1= Invoke-WebRequest -Method GET -Uri $machineUri -UseBasicParsing -Headers @{Metadata="True"; Authorization="bearer $yourtoken"}
    $objectId = ($response1 | ConvertFrom-Json).identity.principalId

    # grant the access permission to your connected machine. 
    # Make sure you logon to the subscription where Key Vault resides
    Set-AzKeyVaultAccessPolicy -VaultName $keyVaultName -PermissionsToSecrets Get  -ObjectId $objectId
}

Set-KeyVaultAccessPolicy -machineName '<yourConnectedMachineName>' -subscriptionId '<yourSubscriptionId>' -resourceGroup '<yourRG>' -apiVersion '2019-03-18-preview' -keyVaultName '<yourKeyVault>'