# This sample script gets all Azure AD Application Proxy applications (AppId, Name of the app, external / internal url, pre-authentication type etc.).
#
# This script requires PowerShell 5.1 (x64) and one of the following modules:
#     AzureAD 2.0.2.128
#
# Before you begin:
#    Run Connect-AzureAD to connect to the tenant domain.
#    Required Azure AD role: Global Administrator or Application Administrator or Application Developer

$ssoMode = "All"

# Change $ssoMode to filter the output based on the configured SSO type
# All                           - all Azure AD Application Proxy apps (no filter)
# None                          - Azure AD Application Proxy apps configured with no SSO, SAML, Linked, Password
# OnPremisesKerberos            - Azure AD Application Proxy apps configured with Windows Integrated SSO (Kerberos Constrained Delegation)

Write-Host "Reading service principals. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green" 

$aadapServPrinc = Get-AzureADServicePrincipal -Top 100000 | where-object {$_.Tags -Contains "WindowsAzureActiveDirectoryOnPremApp"} 

Write-Host "Reading Azure AD applications. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$allApps = Get-AzureADApplication -Top 100000

Write-Host "Reading application. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$aadapApp = $aadapServPrinc | ForEach-Object { $allApps -match $_.AppId}

Write-Host "Displaying all Azure AD Application Proxy applications with configuration details..." -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host "SSO mode filter: " $ssoMode -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " "

foreach ($item in $aadapApp) {
    
    $aadapTemp = Get-AzureADApplicationProxyApplication -ObjectId $item.ObjectId 
    
    if ($ssoMode -eq "All" -Or $aadapTemp.SingleSignOnSettings.SingleSignOnMode -eq $ssoMode) {
    
      $aadapServPrinc[$aadapApp.IndexOf($item)].DisplayName + " (AppId: " + $aadapServPrinc[$aadapApp.IndexOf($item)].AppId + ")";    

      Write-Host "External Url: " $aadapTemp.ExternalUrl
      Write-Host "Internal Url: " $aadapTemp.InternalUrl
      Write-Host "Pre authentication type: " $aadapTemp.ExternalAuthenticationType
      Write-Host "SSO mode: " $aadapTemp.SingleSignOnSettings.SingleSignOnMode

      If ($aadapTemp.SingleSignOnSettings.SingleSignOnMode -eq "OnPremisesKerberos") {

      Write-Host "Service Principal Name (SPN): " $aadtemp.SingleSignOnSettings.KerberosSignOnSettings.KerberosServicePrincipalName
      Write-Host "Username Mapping Attribute: " $aadapTemp.SingleSignOnSettings.KerberosSignOnSettings.KerberosSignOnMappingAttributeType
      
      }

      Write-Host "Backend Application Timeout: " $aadapTemp.ApplicationServerTimeout
      Write-Host "Translate URLs in Headers: " $aadapTemp.IsTranslateHostHeaderEnabled
      Write-Host "Translate URLs in Application Body: " $aadapTemp.IsTranslateLinksInBodyEnabled
      Write-Host "Use HTTP-Only Cookie: " $aadapTemp.IsHttpOnlyCookieEnabled
      Write-Host "Use Secure Cookie: " $aadapTemp.IsSecureCookieEnabled
      Write-Host "Use Persistent Cookie: " $aadapTemp.IsPersistentCookieEnabled
      
      If ($aadapTemp.VerifiedCustomDomainCertificatesMetadata.Thumbprint.Length -ne 0) {
       
      Write-Host "SSL Certificate details:"
      Write-Host "Certificate SubjectName: " $aadapTemp.VerifiedCustomDomainCertificatesMetadata.SubjectName
      Write-Host "Certificate Thumbprint: " $aadapTemp.VerifiedCustomDomainCertificatesMetadata.Issuer
      Write-Host "Certificate Thumbprint: " $aadapTemp.VerifiedCustomDomainCertificatesMetadata.Thumbprint
      Write-Host "Valid from: " $aadapTemp.VerifiedCustomDomainCertificatesMetadata.IssueDate
      Write-Host "Valid to: " $aadapTemp.VerifiedCustomDomainCertificatesMetadata.ExpiryDate
       
      } 
      
      Write-Host ""
   }
}

Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("")
