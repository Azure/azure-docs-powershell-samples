# Get all Azure AD Proxy applications that have assigned an Azure AD policy (token lifetime) with policy details. (AzureADPreview module required) 
 
$AADAPSERVPRINC=Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 
$ALLAPPS=Get-AzureADApplication -Top 100000  
 
foreach ($ITEM in $AADAPSERVPRINC)  
{     
 
 $POLICY=AzureADServicePrincipalPolicy -Id $ITEM.ObjectId 
 
 If (!([string]::IsNullOrEmpty($POLICY.Id))) 
   
  { 
   Write-Host ("")        
 
   $ITEM.DisplayName + " (AppId: " + $ITEM.AppId+")"; 
 
   Write-Host ("") 
   Write-Host ("Policy") 
     
   Get-AzureADPolicy -Id $POLICY.id | fl 
    
   Write-Host ("") 
   } 
 }  
