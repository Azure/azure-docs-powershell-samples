# This sample script gets all Azure AD Proxy applications that have assigned an Azure AD policy (token lifetime) with policy details.
# Reference:
# Configurable token lifetimes in Azure Active Directory (Preview)
# https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-configurable-token-lifetimes
#
# This script requires PowerShell 5.1 (x64) and the following module:
#     AzureADPreview 2.0.2.53
#
# Before you begin:
#    Run Connect-AzureAD to connect to the tenant domain.
#    Required Azure AD role: Global Administrator or Application Administrator
 
Write-Host "Reading service principals. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapServPrinc = Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"}  

Write-Host "Reading Azure AD applications. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$allApps = Get-AzureADApplication -Top 100000 

Write-Host "Displaying Azure AD Application Proxy applications with assigned Azure AD policies" -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " " 

foreach ($item in $aadapServPrinc) { 
 
 $policy=Get-AzureADServicePrincipalPolicy -Id $item.ObjectId 
 
 If (!([string]::IsNullOrEmpty($policy.Id))) {
   
   Write-Host ("")        
 
   $item.DisplayName + " (AppId: " + $item.AppId + ")" 
 
   Write-Host ("") 
   Write-Host ("Policy") 
     
   Get-AzureADPolicy -Id $policy.id | fl 
    
   Write-Host ("") 
 
  } 
}  

Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 
