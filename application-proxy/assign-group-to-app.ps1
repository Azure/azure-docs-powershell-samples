# This sample script assigns a group to a specific Azure AD Application Proxy application.
#
# .\assign-group-to-app.ps1 -ServicePrincipalObjectId <ObjectId of the Azure AD Application Proxy application service principal> -GroupObjectId <ObjectId of the group>
#
# Tip: You can identify the parameters by using the following PS commands:
#    ServicePrincipalObjectId - Get-AzureADServicePrincipal -SearchString "<display name of the app>"
#    GroupObjectId - Get-AzureADGroup -SearchString "<name of the group>"
#
# This script requires PowerShell 5.1 (x64) and one of the following modules:
#     AzureAD 2.0.2.52
#     AzureADPreview 2.0.2.53
#
# Before you begin:
#    Run Connect-AzureAD to connect to the tenant domain.
#    Required Azure AD role: Global Administrator

param(
[string] $ServicePrincipalObjectId = "null",
[string] $GroupObjectId = "null"
)

$servicePrincipalObjectId = $ServicePrincipalObjectId
$groupObjectId = $GroupObjectId

If (($servicePrincipalObjectId -eq "null") -or ($groupObjectId -eq "null")) {

    Write-Host "Parameter is missing." -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host ".\assign-group-to-app.ps1 -ServicePrincipalObjectId <ObjectId of the Azure AD Application Proxy application service principal> -GroupObjectId <ObjectId of the group>" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host "Hints:" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host "You can easily identify the parameters by using the following PS commands:" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host "ServicePrincipalObjectId - Get-AzureADServicePrincipal -SearchString ""<display name of the app>"" " -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host "GroupObjectId - Get-AzureADGroup -SearchString ""<name of the group>""" -BackgroundColor "Black" -ForegroundColor "Green"

    Exit
}


New-AzureADGroupAppRoleAssignment -ObjectId $groupObjectId -PrincipalId $groupObjectId -ResourceId $servicePrincipalObjectId -Id 18d14569-c3bd-439b-9a66-3a2aee01d14f  

Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 