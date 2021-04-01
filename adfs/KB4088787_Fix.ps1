# 
# Version 2.0.0 
# 

# Helper function - serializes any DataContract object to an XML string 
function Get-DataContractSerializedString() 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory = $true, HelpMessage="Any object serializable with the DataContractSerializer")] 
        [ValidateNotNull()] 
        $object 
    ) 

    $serializer = New-Object System.Runtime.Serialization.DataContractSerializer($object.GetType()) 
    $serializedData = $null 

    try 
    { 
        # No simple write to string option, so we have to write to a memory stream 
        # then read back the bytes... 
        $stream = New-Object System.IO.MemoryStream 
        $writer = New-Object System.Xml.XmlTextWriter($stream,[System.Text.Encoding]::UTF8) 

        $null = $serializer.WriteObject($writer, $object); 
        $null = $writer.Flush(); 
                
        # Read back the text we wrote to the memory stream 
        $reader = New-Object System.IO.StreamReader($stream,[System.Text.Encoding]::UTF8) 
        $null = $stream.Seek(0, [System.IO.SeekOrigin]::Begin) 
        $serializedData = $reader.ReadToEnd() 
    } 
    finally 
    { 
        if ($reader -ne $null) 
        { 
            try 
            { 
                $reader.Dispose() 
            } 
            catch [System.ObjectDisposedException] { } 
        } 

        if ($writer -ne $null) 
        { 
            try 
            { 
                $writer.Dispose() 
            } 
            catch [System.ObjectDisposedException] { } 
        } 

        if ($stream -ne $null) 
        { 
            try 
            { 
                $stream.Dispose() 
            } 
            catch [System.ObjectDisposedException] { } 
        } 
    } 

    return $serializedData 
} 

function Write-XmlIndent 
{ 
    param 
    ( 
        $xmlData 
    ) 

    $strWriter = New-Object System.IO.StringWriter 
    $xmlWriter = New-Object System.XMl.XmlTextWriter $strWriter 

    # Default = None, change Formatting to Indented 
    $xmlWriter.Formatting = "indented" 

    # Gets or sets how many IndentChars to write for each level in 
    # the hierarchy when Formatting is set to Formatting.Indented 
    $xmlWriter.Indentation = 1 
    
    $xmlData.WriteContentTo($xmlWriter) 
    $xmlWriter.Flush() 
    $strWriter.Flush() 
    $strWriter.ToString() 
} 

function Get-ADFSXMLServiceSettings 
{ 
    param 
    ( 
        $saveData 
    ) 

    $doc = new-object Xml 
    $doc.Load("$env:windir\ADFS\Microsoft.IdentityServer.Servicehost.exe.config") 
    $connString = $doc.configuration.'microsoft.identityServer.service'.policystore.connectionString 
    $cli = new-object System.Data.SqlClient.SqlConnection 
    $cli.ConnectionString = $connString 
    $cli.Open() 
    try 
    { 
        $cmd = new-object System.Data.SqlClient.SqlCommand 
        $cmd.CommandText = "Select ServiceSettingsData from [IdentityServerPolicy].[ServiceSettings]" 
        $cmd.Connection = $cli 
        $configString = $cmd.ExecuteScalar() 
        $configXml = new-object XML 
        $configXml.LoadXml($configString) 
        
        if($saveData) 
        { 
            $script:originalPath = "original_serviceSettingsXml_$(get-date -f yyyy-MM-dd-hh-mm-ss).xml" 
            Write-XmlIndent($configXml) | Out-File $script:originalPath 
            Write-Host "Original XML saved to: $script:originalPath" 
        } 
        
        write-output $configXml 
    } 
    finally 
    { 
        $cli.CLose() 
    } 
} 

# Gets internal ADFS settings by extracting them Get-AdfsProperties 
function Get-AdfsInternalSettings() 
{ 
    $settings = Get-AdfsProperties 
    $settingsType = $settings.GetType() 
    $propInfo = $settingsType.GetProperty("ServiceSettingsData", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic) 
    $internalSettings = $propInfo.GetValue($settings, $null) 
    
    return $internalSettings 
} 

function Set-AdfsInternalSettings() 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory = $true, HelpMessage="Settings object fetched from Get-AdfsInternalSettings")] 
        [ValidateNotNull()] 
        $InternalSettings 
    ) 

    $settingsData = Get-DataContractSerializedString -object $InternalSettings 

    $doc = new-object Xml 
    $doc.Load("$env:windir\ADFS\Microsoft.IdentityServer.Servicehost.exe.config") 
    $connString = $doc.configuration.'microsoft.identityServer.service'.policystore.connectionString 
    $cli = new-object System.Data.SqlClient.SqlConnection 
    $cli.ConnectionString = $connString 
    $cli.Open() 
    try 
    {    
        $cmd = new-object System.Data.SqlClient.SqlCommand 
        $cmd.CommandText = "update [IdentityServerPolicy].[ServiceSettings] SET ServiceSettingsData=@content,[ServiceSettingsVersion] = [ServiceSettingsVersion] + 1,[LastUpdateTime] = GETDATE()" 
        $cmd.Parameters.AddWithValue("@content", $settingsData) | out-null 
        $cmd.Connection = $cli 
        $rowsAffected = $cmd.ExecuteNonQuery() 

        # Update service state table for WID sync if required 
        if ($connString -match "##wid") 
        { 
            $cmd = new-object System.Data.SqlClient.SqlCommand 
            $cmd.CommandText = "UPDATE [IdentityServerPolicy].[ServiceStateSummary] SET [SerialNumber] = [SerialNumber] + 1,[LastUpdateTime] = GETDATE() WHERE ServiceObjectType='ServiceSettings'" 

            $cmd.Connection = $cli 
            $widRowsAffected = $cmd.ExecuteNonQuery() 
        } 
    } 
    finally 
    { 
        $cli.CLose() 
    } 
} 

function Create-EndpointConfiguration() 
{ 
    Param 
    ( 
        [ValidateNotNull()] 
        $xmlData 
    ) 
    
    # EndpointConfiguration 
    $enabled = Create-BoolFromString($xmlData.Enabled) 
    $proxy = Create-BoolFromString($xmlData.Proxy) 
    $canProxy = Create-BoolFromString($xmlData.CanProxy) 

    $endpointConfig = New-Object -TypeName Microsoft.IdentityServer.PolicyModel.Configuration.EndpointConfiguration -ArgumentList $xmlData.Address, $enabled , ([Microsoft.IdentityServer.PolicyModel.Configuration.EndpointMode] $xmlData.ModeValue), $proxy, $xmlData.Version, $canProxy 

    return $endpointConfig 
} 

function Create-ClientSecretSettings() 
{ 
    Param 
    ( 
        [ValidateNotNull()] 
        $xmlData 
    ) 

    # ClientSecretSettings 
    $clientSecretSettings = New-Object -TypeName Microsoft.IdentityServer.PolicyModel.Client.ClientSecretSettings 
    $clientSecretSettings.ClientSecretRolloverTimeMinutes = $xmlData.ClientSecretRolloverTimeMinutes 
    $clientSecretSettings.ClientSecretLockoutThreshold = $xmlData.ClientSecretLockoutThreshold; 
    $clientSecretSettings.SaltedHashAlgorithm = $xmlData.SaltedHashAlgorithm 
    $clientSecretSettings.SaltSize = $xmlData.SaltSize 
    $clientSecretSettings.SecretSize = $xmlData.SecretSize 
    return $clientSecretSettings 
} 

function Create-IdTokenIssuer() 
{ 
    Param 
    ( 
        [ValidateNotNull()] 
        $xmlData 
    ) 

    #IdTokenIssuer 
    $idTokenIssuerConfig = New-Object -TypeName Microsoft.IdentityServer.PolicyModel.Configuration.IdTokenIssuerConfiguration 
    $idTokenIssuerConfig.Address = $xmlData.Address 
    return $idTokenIssuerConfig 
} 

function Create-CertificateAuthorityConfiguration() 
{ 
    Param 
    ( 
        [ValidateNotNull()] 
        $xmlData 
    ) 

    # CertificateAuthorityConfiguration 
    $certAuthorityConfig = New-Object -TypeName Microsoft.IdentityServer.PolicyModel.Configuration.CertificateAuthorityConfiguration 

    $certAuthorityConfig.Mode.Value = [Microsoft.IdentityServer.PolicyModel.Configuration.CertificateAuthorityMode] $xmlData.ModeValue 
    $certAuthorityConfig.GenerationThresholdInMinutes = $xmlData.GenerationThresholdInMinutes 
    $certAuthorityConfig.PromotionThresholdInMinutes = $xmlData.PromotionThresholdInMinutes 
    $certAuthorityConfig.CertificateLifetimeInMinutes = $xmlData.CertificateLifetimeInMinutes 
    $certAuthorityConfig.RolloverIntervalInMinutes = $xmlData.RolloverIntervalInMinutes 
    $certAuthorityConfig.CriticalThresholdInMinutes = $xmlData.CriticalThresholdInMinutes 

    # Create Cert reference 
    if ($xmlData.PrimaryIssuerCertificate.IsEmpty -ne $true) 
    { 
        $certReference = New-Object -TypeName Microsoft.IdentityServer.PolicyModel.Configuration.CertificateReference 
        $certReference.IsChainIncluded = Create-BoolFromString($xmlData.PrimaryIssuerCertificate.IsChainIncluded) 
        $certReference.IsChainIncludedSpecified = Create-BoolFromString($xmlData.PrimaryIssuerCertificate.IsChainIncludedSpecified) 
        $certReference.FindValue = $xmlData.PrimaryIssuerCertificate.FindValue 
        $certReference.RawCertificate = $xmlData.PrimaryIssuerCertificate.RawCertificate 
        $certReference.EncryptedPfx = $xmlData.PrimaryIssuerCertificate.EncryptedPfx 
        $certReference.StoreName.Value = [System.Security.Cryptography.X509Certificates.StoreName] $xmlData.PrimaryIssuerCertificate.StoreNameValue 
        $certReference.StoreLocation.Value = [System.Security.Cryptography.X509Certificates.StoreLocation] $xmlData.PrimaryIssuerCertificate.StoreLocationValue 
        $certReference.X509FindType.Value = [System.Security.Cryptography.X509Certificates.X509FindType] $xmlData.PrimaryIssuerCertificate.X509FindTypeValue 
        $certAuthorityConfig.PrimaryIssuerCertificate = $certReference 
    } 

    if ($xmlData.QueuedIssuerCertificate.IsEmpty -ne $true){ 
        # Create PromotionCert 
        $promotionCert = New-Object -TypeName Microsoft.IdentityServer.PolicyModel.Configuration.PromotionCertificate 
        $promotionCert.ObjectId = $xmlData.QueuedIssuerCertificate.ObjectId 
        $certAuthorityConfig.QueuedIssuerCertificate = $promotionCert 
    } 

    $certAuthorityConfig.CriticalThresholdInMinutes = $xmlData.CriticalThresholdInMinutes 

    if ($xmlData.CertificateAuthority.IsEmpty -ne $true){ 
        $certAuthorityConfig.CertificateAuthority = $xmlData.CertificateAuthority 
    }   

    if ($xmlData.EnrollmentAgentCertificateTemplateName.IsEmpty -ne $true) 
    { 
        $certAuthorityConfig.EnrollmentAgentCertificateTemplateName = $xmlData.EnrollmentAgentCertificateTemplateName 
    } 

    if ($xmlData.LogonCertificateTemplateName.IsEmpty -ne $true) 
    { 
        $certAuthorityConfig.LogonCertificateTemplateName = $xmlData.LogonCertificateTemplateName 
    } 

    if ($xmlData.VPNCertificateTemplateName.IsEmpty -ne $true) 
    { 
        $certAuthorityConfig.VPNCertificateTemplateName = $xmlData.VPNCertificateTemplateName 
    } 

    if ($xmlData.WindowsHelloCertificateTemplateName.IsEmpty -ne $true) 
    { 
        $certAuthorityConfig.WindowsHelloCertificateTemplateName = $xmlData.WindowsHelloCertificateTemplateName 
    } 

    $certAuthorityConfig.AutoEnrollEnabled = Create-BoolFromString($xmlData.AutoEnrollEnabled) 
    $certAuthorityConfig.WindowsHelloCertificateProxyEnabled = Create-BoolFromString($xmlData.WindowsHelloCertificateProxyEnabled) 

    return $certAuthorityConfig 
} 

function Create-OAuthClientAuthenticationMethods() 
{ 
    Param 
    ( 
        [ValidateNotNull()] 
        $xmlData 
    ) 

    # OAuthClientAuthenticationMethods 
    return 15 
} 

function Create-BoolFromString() 
{ 
    Param 
    ( 
        [ValidateNotNull()] 
        $xmlData 
    ) 

    if ($xmlData -eq $null -or $xmlData.ToLower() -eq "false") 
    { 
        return 0 
    }else{ 
        return 1 
    } 
} 

            
function Get-ObjectFromElement() 
{ 
    Param 
    ( 
    [Parameter(Mandatory = $true, HelpMessage="Settings object fetched from Get-AdfsInternalSettings")] 
        [ValidateNotNull()] 
        $xmlData, 
        [Parameter(Mandatory = $true, HelpMessage="Settings object fetched from Get-AdfsInternalSettings")] 
        [ValidateNotNull()] 
        $elementName 
    ) 

    $endpointConfigs = "DeviceRegistrationEndpoint", "OAuthJwksEndpoint", "OAuthDiscoveryEndpoint", "WebFingerEndpoint", "CertificateAuthorityCrlEndpoint", "UserInfoEndpoint" 
    # Microsoft.IdentityServer.PolicyModel.Configuration.EndpointConfiguration 

    $clientSecretSettings = "ClientSecretSettings" 
    # Microsoft.IdentityServer.PolicyModel.Client.ClientSecretSettings 

    $oauthClientAuthMethod = "OAuthClientAuthenticationMethods" 
    # Microsoft.IdentityServer.PolicyModel.Configuration.ClientAuthenticationMethod 

    $certAuthorityConfig = "CertificateAuthorityConfiguration" 
    # Microsoft.IdentityServer.PolicyModel.Configuration.CertificateAuthorityConfiguration 

    $idTokenIssuer = "IdTokenIssuer" 
    # Microsoft.IdentityServer.PolicyModel.Configuration.IdTokenIssuerConfiguration 

    $boolObjs = "EnableIdPInitiatedSignonPage", "IgnoreTokenBinding", "EnableOauthLogout" 

    $basicObjs = "DeviceUsageWindowInSeconds", "MaxLdapUserNameLength",  "FarmBehaviorMinorVersion",  "PromptLoginFederation", "PromptLoginFallbackAuthenticationType" 

    if ($endpointConfigs.Contains($elementName)) 
    { 
        return Create-EndpointConfiguration($xmlData) 
    }elseif ($clientSecretSettings.Contains($elementName)) 
    { 
        return  Create-ClientSecretSettings($xmlData)        
    }elseif ($oauthClientAuthMethod.Contains($elementName)) 
    { 
        return Create-OAuthClientAuthenticationMethods($xmlData) 
    }elseif ($certAuthorityConfig.Contains($elementName)) 
    { 
        return Create-CertificateAuthorityConfiguration($xmlData) 
    }elseif ($idTokenIssuer.Contains($elementName)) 
    { 
        return Create-IdTokenIssuer($xmlData) 
    }elseif ($boolObjs.Contains($elementName)) 
    { 
        return Create-BoolFromString($xmlData) 
    }else{ 
        return $xmlData 
    } 
} 

$role = (Get-AdfsSyncProperties).Role 
if($role -ne "PrimaryComputer") 
{ 
    Write-Host "This script must execute on the primary node in the AD FS farm. Cannot continue." 
    exit 
} 

Add-Type -Path ('C:\\Windows\\ADFS\\Microsoft.IdentityServer.dll') 
$script:originalPath = $null 

# Get the XML of the Service Settings blob, and look for duplicate elements 
$xmlData = Get-ADFSXMLServiceSettings($true) 
$dataObj = Get-AdfsInternalSettings 

if($dataObj.SecurityTokenService.DeviceRegistrationEndpoint.Length -ne 1) 
{ 
    if(($xmlData.ServiceSettingsData.SecurityTokenService | Select-Object "DeviceRegistrationEndpoint").DeviceRegistrationEndpoint.IsEmpty[0] -ne $True) 
    { 
        # In this case, the service settings object is showing an issue, but the XML data is not. 
        # This is possible in the case that the sequence of KB applications has occurred, but no Service Settings write oparation 
        # has occured. 
        # To handle this, we will prompt the user to allow us to throttle a Service Setting to force a write operation 

        # Do a no-op service settings action so that the duplicates are populated in the database (if issue exists) 
        $message  = "Confirmation required" 
        $question = "To ensure data detection is possible, we need to perform an AD FS Properties operation. `nIf you continue, this script will add 1 minute to the value of 'ProxyTrustTokenLifetime', and then the value of 'ProxyTrustTokenLifetime' will be returned to its original setting. `nIf you wish to make a Set-AdfsProperties operation yourself, answer 'No', and perform the operation yourself. `n`nAre you sure you want to proceed?" 

        $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription] 
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes')) 
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No')) 

        $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1) 

        if ($decision -eq 0) { 
            $prop = Get-AdfsProperties 
            $original = $prop.ProxyTrustTokenLifetime 
            Set-AdfsProperties -ProxyTrustTokenLifetime ($original + 1) 
            Set-AdfsProperties -ProxyTrustTokenLifetime $original 

            # Refresh the XML and data obj 
            $xmlData = Get-ADFSXMLServiceSettings($false) 
            $dataObj = Get-AdfsInternalSettings 
        }else{ 
            Write-Host "We did not perform a service settings operation. Please make some service settings change by performing a Set-AdfsProperties command, and try the script again." 
        } 
    } 
} 

if(($xmlData.ServiceSettingsData.SecurityTokenService | Select-Object "DeviceRegistrationEndpoint").DeviceRegistrationEndpoint.IsEmpty[0] -eq $True) 
{ 
    $possibleDuplicateElements = "DeviceRegistrationEndpoint", "DeviceUsageWindowInSeconds", "OAuthClientAuthenticationMethods", "MaxLdapUserNameLength", "EnableIdPInitiatedSignonPage", "ClientSecretSettings", "OAuthDiscoveryEndpoint", "OAuthJwksEndpoint", "IdTokenIssuer", "CertificateAuthorityConfiguration", "WebFingerEndpoint", "CertificateAuthorityCrlEndpoint",  "UserInfoEndpoint", "IgnoreTokenBinding", "FarmBehaviorMinorVersion", "EnableOauthLogout", "PromptLoginFederation", "PromptLoginFallbackAuthenticationType" 

    $existingDups = @() 
    foreach( $dup in $possibleDuplicateElements ) 
    { 
        $object = $xmlData.ServiceSettingsData.SecurityTokenService | Select-Object $dup 

        if( $object.$dup.Count -gt 1 ) 
        { 
            # We have an element with duplicate values 
            # Take the last one in the list 
            $newObj = $object.$dup[$object.$dup.Count - 1] 

            $savableObj = Get-ObjectFromElement -xmlData $newObj -elementName $dup 

            $existingDups += $dup 

            $dataObj.SecurityTokenService.$dup = $savableObj 
        } 
    } 

    # Write the modified Service Settings data object back to the database 
    if($existingDups.Count -gt 0) 
    { 
        $filename = "modified_serviceSettingsXml_$(get-date -f yyyy-MM-dd-hh-mm-ss).xml" 
        $modifiedData = Get-DataContractSerializedString -object $dataObj 
        Write-XmlIndent([xml]$modifiedData) | Out-File $filename 
        Write-Host "Modifed XML saved to: $filename" 

        $message  = "Confirmation required" 
        $question = "We have located duplicate data in Service Settings, and need to make a modification to the configuration database. `nIf you continue, the values of some elements will be updated in your database. `nIf you wish to see the difference, you can compare the following two files from the working directory: `n`n$script:originalPath `n$filename `n`nAre you sure you want to proceed?" 

        $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription] 
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes')) 
        $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No')) 

        $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1) 
        if ($decision -eq 0) { 
            Write-Host "Performing update to Service Settings" 
            Set-AdfsInternalSettings -InternalSettings $dataObj 
            Write-Host "Updated Service Settings`n`n" 

            Write-Host "The following elements in the service settings data were modified:`n" 
            foreach($d in $existingDups) 
            { 
                Write-Host $d 
            }            

            Write-Host "`nAll nodes in this farm should be restarted. This script will attempt to restart the current node, but no other nodes." 
            Write-Host "Please manually restart all nodes in your AD FS farm.`n`n" 

            $message  = "Confirmation required" 
            $question = "An AD FS Service restart is required. Proceed with restart?" 

            $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription] 
            $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes')) 
            $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No')) 

            $decision2 = $Host.UI.PromptForChoice($message, $question, $choices, 1) 

            if($decision2 -eq 0){ 
                Write-Host "Stopping AD FS" 
                net stop adfssrv 
                
                Write-Host "Starting AD FS" 
                net start adfssrv 
            }else{ 
                Write-Host "You chose not to restart AD FS. Please manually restart AD FS to allow the changes to take effect." 
            } 
        } else { 
          Write-Host "Cancelling" 
        } 
    }else{ 
        Write-Host "No Operations Needed" 
    } 

}else 
{ 
    Write-Host "No issues detected. Terminating script." 
} 