# Azure Container Registry

## PowerShell sample scripts

The scripts in this directory demonstrate working with [Azure Container Registry][acr-home] using the [Azure PowerShell][azure-psh] cmdlets.

| Script | Description |
| ------ | ----------- |
|[service-principal-assign-role.ps1][sp-assign]| Assigns a role to an existing Azure Active Directory service principal, granting the service principal access to an Azure Container Registry. |
|[service-principal-create.ps1][sp-create]| Creates a new Azure Active Directory service principal with permissions to an Azure Container Registry. |

<!-- SCRIPTS -->
[sp-assign]: ./service-principal-assign-role/service-principal-assign-role.ps1
[sp-create]: ./service-principal-create/service-principal-create.ps1

<!-- EXTERNAL -->
[acr-home]: https://azure.microsoft.com/services/container-registry/
[azure-psh]: https://docs.microsoft.com/powershell/azure/overview