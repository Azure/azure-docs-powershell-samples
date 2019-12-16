# This sample script assigns a user to a specific Azure AD Application Proxy application.
#
# .\assign-user-to-app.ps1 -ServicePrincipalObjectId <ObjectId of the Azure AD Application Proxy application service principal> -GroupObjectId <ObjectId of the user>
#
# Tip: You can identify the parameters by using the following PS commands:
#    ServicePrincipalObjectId - Get-AzureADServicePrincipal -SearchString "<display name of the app>"
#    UserObjectId - Get-AzureADGroup -SearchString "<name of the group>"
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
[string] $UserObjectId = "null"
)

$servicePrincipalObjectId = $ServicePrincipalObjectId
$userObjectId = $UserObjectId

If (($servicePrincipalObjectId -eq "null") -or ($userObjectId -eq "null")) {

    Write-Host "Parameter is missing." -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host ".\assign-user-to-app.ps1 -ServicePrincipalObjectId <ObjectId of the Azure AD Application Proxy application service principal> -UserObjectId <ObjectId of the User>" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host "Hints:" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host "You can easily identify the parameters by using the following PS commands:" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host "ServicePrincipalObjectId - Get-AzureADServicePrincipal -SearchString ""<display name of the app>"" " -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host "UserObjectId - Get-AzureADUser -SearchString ""<name of the user>""" -BackgroundColor "Black" -ForegroundColor "Green"

    Exit
}

New-AzureADUserAppRoleAssignment -ObjectId $userObjectId -PrincipalId $userObjectId -ResourceId $servicePrincipalObjectId -Id 18d14569-c3bd-439b-9a66-3a2aee01d14f 

Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 