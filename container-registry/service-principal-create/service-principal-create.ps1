# This sample requires the Az PowerShell module version 7.x or higher.

# Modify for your environment. The 'registryName' is the name of your Azure
# Container Registry, the 'resourceGroup' is the name of the resource group
# in which your registry resides, and the 'servicePrincipalName' can be any
# unique name within your subscription (you can use the default below).
$registryName = '<container-registry-name>'
$resourceGroup = '<resource-group-name>'
$servicePrincipalName = 'acr-service-principal'

# Get a reference to the container registry; need its fully qualified ID
# when assigning the role to the principal in a subsequent command.
$registry = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $registryName

# Create the service principal
$sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName

# Sleep a few seconds to allow the service principal to propagate throughout
# Azure Active Directory
Start-Sleep -Seconds 30

# Assign the role to the service principal. Default permissions are for docker
# pull access. Modify the 'RoleDefinitionName' argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# Owner:       push, pull, and assign roles
New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName acrpull -Scope $registry.Id

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
Write-Output "Service principal App ID: $($sp.AppId)"
Write-Output "Service principal password: $($sp.PasswordCredentials.SecretText)"
