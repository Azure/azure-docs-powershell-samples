# Modify for your environment. The 'registryName' is the name of your Azure
# Container Registry, the 'resourceGroup' is the name of the resource group
# in which your registry resides, and the 'servicePrincipalId' is the
# service principal's 'ApplicationId' or one of its 'servicePrincipalNames'.
$registryName = "<container-registry-name>"
$resourceGroup = "<resource-group-name>"
$servicePrincipalId = "<service-principal-id>"

# Get a reference to the container registry; need its fully qualified ID
# when assigning the role to the principal in a subsequent command.
$registry = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $registryName

# Get the existing service principal; need its 'ObjectId' value
# when assigning the role to the principal in a subsequent command.
$sp = Get-AzADServicePrincipal -ServicePrincipalName $servicePrincipalId

# Assign the role to the service principal, identified using 'ObjectId'. Default permissions are for docker
# pull access. Modify the 'RoleDefinitionName' argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# Owner:       push, pull, and assign roles
$role = New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName acrpull -Scope $registry.Id
