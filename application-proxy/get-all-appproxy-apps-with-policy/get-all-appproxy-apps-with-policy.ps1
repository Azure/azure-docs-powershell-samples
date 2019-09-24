# Get all Azure AD Proxy applications that have assigned an Azure AD policy (token lifetime) with policy details. (AzureADPreview module required) 
 
$AADAPServPrinc=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$allApps=Get-AzureADApplication -Top 100000  
 
foreach ($item in $AADAPServPrinc)  
{     
 
 $policy=AzureADServicePrincipalPolicy -Id $item.ObjectId 
 
 If (!([string]::IsNullOrEmpty($policy.Id))) 
   
  { 
   Write-Host ("")        
 
   $item.DisplayName + " (AppId: " + $item.AppId+")"; 
 
   Write-Host ("") 
   Write-Host ("Policy") 
     
   Get-AzureADPolicy -Id $policy.id | fl 
    
   Write-Host ("") 
   } 
 }  
