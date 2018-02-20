# Modify for your environment. The 'registryName' is the name of your Azure
# Container Registry, the 'resourceGroup' is the name of the resource group
# in which your registry resides, and the 'servicePrincipalName' is the
# service principal's 'ApplicationId' or one of its 'servicePrincipalNames'.
$registryName = "<container-registry-name>"
$resourceGroup = "<resource-group-name>"
$servicePrincipalName = "<service-principal-name>"

# Get a reference to the container registry; need its fully qualified ID
# when assigning the role to the principal in a subsequent command.
$registry = Get-AzureRmContainerRegistry -ResourceGroupName $resourceGroup -Name $registryName

# Get the existing service principal
$sp = Get-AzureRmADServicePrincipal -ServicePrincipalName $servicePrincipalName

# Assign the role to the service principal. Default permissions are for docker
# pull access. Modify the 'RoleDefinitionName' argument value as desired:
# Reader:      pull only
# Contributor: push and pull
# Owner:       push, pull, and assign roles
$role = New-AzureRmRoleAssignment -ObjectId $sp.Id -RoleDefinitionName Reader -Scope $registry.Id
