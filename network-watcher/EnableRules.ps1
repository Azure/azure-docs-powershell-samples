[CmdletBinding()]
Param(
  [Parameter(Mandatory=$False)]
  [string]$portNumber="8084",
[switch]$DisableRule #by default it is false
)

$firewallRuleName="NPMDFirewallRule"
$firewallRuleDescription = "NPMD Firewall port exception"
$processName = "NPMDAgent.exe"
$protocolName = "tcp"
$direction = "in"
$isPortInUse = $False

$ICMPv4DestinationUnreachableRuleName = "NPMDICMPV4DestinationUnreachable"
$ICMPv4TimeExceededRuleName = "NPMDICMPV4TimeExceeded"
$ICMPv6DestinationUnreachableRuleName = "NPMDICMPV6DestinationUnreachable"
$ICMPv6TimeExceededRuleName = "NPMDICMPV6TimeExceeded"

$registryPath = "HKLM:\Software\Microsoft"
$keyName = "NPMD"
$NPMDPath = "HKLM:\Software\Microsoft\NPMD"
$NPMDLogRegistryPath = "Registry::HKEY_USERS\S-1-5-20\Software\Microsoft"
$NPMDLogKeyPath = "Registry::HKEY_USERS\S-1-5-20\Software\Microsoft\NPMD"
$portNumberName = "PortNumber"
$logLocationName = "LogLocation"
$enableLogName = "EnableLog"
$NPMDProcess = "NPMDAgent"

#Creates or deletes firewall rule based on disable rule flag
#Incase rule already created if it is just update of port number it just updates rule
function EnableDisableFirewallRule
{
    #Check if the ICMPv4 firewall rules already exist
    $icmpV4DURuleExists = 1;
    $existingRule = netsh advfirewall firewall show rule name=$ICMPv4DestinationUnreachableRuleName
    if(!($existingRule -cmatch $ICMPv4DestinationUnreachableRuleName))
    { 
        $icmpV4DURuleExists = 0;
    }

    $icmpV4TERuleExists = 1;
    $existingRule = netsh advfirewall firewall show rule name=$ICMPv4TimeExceededRuleName
    if(!($existingRule -cmatch $ICMPv4TimeExceededRuleName))
    { 
        $icmpV4TERuleExists = 0;
    }        
	
    #Check if the ICMPv6 firewall rule already exists
    $icmpV6DURuleExists = 1;
    $existingRule = netsh advfirewall firewall show rule name=$ICMPv6DestinationUnreachableRuleName
    if(!($existingRule -cmatch $ICMPv6DestinationUnreachableRuleName))
    { 
        $icmpV6DURuleExists = 0;
    }

    $icmpV6TERuleExists = 1;
    $existingRule = netsh advfirewall firewall show rule name=$ICMPv6TimeExceededRuleName
    if(!($existingRule -cmatch $ICMPv6TimeExceededRuleName))
    { 
        $icmpV6TERuleExists = 0;
    }
    		
    if(!($DisableRule))
    {
        #TCP Firewall Rule
        $existingRule = (New-object -comObject HNetCfg.FwPolicy2).rules | Where-Object {$_.name -like $firewallRuleName}
        if(!($existingRule))
        { 
            netsh advfirewall firewall add rule action="Allow" Description=$firewallRuleDescription Dir=$direction LocalPort=$portNumber Name=$firewallRuleName Protocol=$protocolName
        }
        #Rule already exists, update port number if different 
        else
        {
            if($existingRule.Name -cmatch $firewallRuleName)
            {
                if(!($existingRule.LocalPorts -cmatch $portNumber))
                {
                    $existingRule.LocalPorts=$portNumber
                    Write-Host "Firewall rule NPMDFirewallRule already exists.`nPort updated successfully to" $portNumber"." -ForegroundColor Green
                }
                else
                {
                    Write-Host "Firewall rule NPMDFirewallRule on"$portNumber "already exits.`nNo changes were made." -ForegroundColor Green
                }
            }
        }
		
        #ICMPv4 firewall rule
        if($icmpV4DURuleExists -eq 0)
        {
            netsh advfirewall firewall add rule name=$ICMPv4DestinationUnreachableRuleName protocol="icmpv4:3,any" dir=in action=allow
        }

        if($icmpV4TERuleExists -eq 0)
        {
            netsh advfirewall firewall add rule name=$ICMPv4TimeExceededRuleName protocol="icmpv4:11,any" dir=in action=allow
        }
		
        #ICMPv6 firewall rule
        if($icmpV6DURuleExists -eq 0)
        {
            netsh advfirewall firewall add rule name=$ICMPv6DestinationUnreachableRuleName protocol="icmpv6:1,any" dir=in action=allow
        }

        if($icmpV6TERuleExists -eq 0)
        {
            netsh advfirewall firewall add rule name=$ICMPv6TimeExceededRuleName protocol="icmpv6:3,any" dir=in action=allow
        }
    }
    else
    {
        #Remove TCP rule, if it exist
        $existingRule = netsh advfirewall firewall show rule name=$firewallRuleName
        if($existingRule)
        {
            netsh advfirewall firewall delete rule name=$firewallRuleName
        }
        #Remove ICMPv4 firewall rules
        if($icmpV4DURuleExists -eq 1)
        {
            netsh advfirewall firewall delete rule name=$ICMPv4DestinationUnreachableRuleName
        }

        if($icmpV4TERuleExists -eq 1)
        {
            netsh advfirewall firewall delete rule name=$ICMPv4TimeExceededRuleName
        }
		
        #Remove ICMPv6 firewall rules
        if($icmpV6DURuleExists -eq 1)
        {
            netsh advfirewall firewall delete rule name=$ICMPv6DestinationUnreachableRuleName
        }

        if($icmpV6TERuleExists -eq 1)
        {
            netsh advfirewall firewall delete rule name=$ICMPv6TimeExceededRuleName
        }
    }

    CreateDeleteRegistry
}

#Creates or deletes registry based on disablerule flag
#In case registry already created, if it just update of port number it updates port on registry
function CreateDeleteRegistry
{
    if(!($DisableRule))
    {
        if(!(Test-Path -Path $NPMDPath))
        {
            New-Item -Path $registryPath -Name $keyName
            New-ItemProperty -Path $NPMDPath -Name $portNumberName -Value $portNumber -PropertyType DWORD
        }
        else
        {
            $NPMDKeys = Get-Item -Path $NPMDPath
            if ($NPMDKeys.GetValue($portNumberName) -eq $null) 
            {
               New-ItemProperty -Path $NPMDPath -Name $portNumberName -Value $portNumber -PropertyType DWORD
            } 
            elseif ($NPMDKeys.GetValueKind($portNumberName) -ne "DWORD") 
            {
               Remove-ItemProperty -Path $NPMDPath -Name $portNumberName
               New-ItemProperty -Path $NPMDPath -Name $portNumberName -Value $portNumber -PropertyType DWORD
            }
            else
            {
               Set-ItemProperty -Path $NPMDPath -Name $portNumberName -Value $portNumber              
            }            
        }
        #Key path to set Log key for Network Service SID
        if(!(Test-Path -Path $NPMDLogKeyPath))
        {
            New-Item -Path $NPMDLogRegistryPath -Name $keyName
            New-ItemProperty -Path $NPMDLogKeyPath -Name $logLocationName
            New-ItemProperty -Path $NPMDLogKeyPath -Name $enableLogName -Value 0 -PropertyType DWORD
        }
        SetAclOnRegistry $NPMDPath
        SetAclOnRegistry $NPMDLogKeyPath

    }
    else
    {
        if((Test-Path -Path $NPMDPath))
        {
            Remove-Item -Path $NPMDPath
        }
        if((Test-Path -Path $NPMDLogKeyPath))
        {
            Remove-Item -Path $NPMDLogKeyPath
        }
    }
    
}

#set acl to network service to read registry
function SetAclOnRegistry([string] $path)
{
    $sid = "S-1-5-20"
    $objUser = New-Object System.Security.Principal.SecurityIdentifier($sid)
    $str_account = ($objUser.Translate([System.Security.Principal.NTAccount])).Value 
    $acl = Get-Acl -Path $path
    $inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
    $propagation = [system.security.accesscontrol.PropagationFlags]"None"
    $rule=new-object system.security.accesscontrol.registryaccessrule "$str_account","ReadKey",$inherit,$propagation,"Allow"
    $acl.addaccessrule($rule)
    $acl|set-acl
}

#Script starts here
#Check if the specified port is already Listening
$getPortInfo = netstat -aon | Select-String "LISTENING" | Select-String $portNumber
if(!($DisableRule) -and ($getPortInfo))
{
    $isPortInUse = $true
    $getPortInfo = $getPortInfo[0]
    #repalce all the extra spaces with ':'
    $getPortInfo=$getPortInfo -replace '\s+',':'
    #remove all the non-digit chars with ':'
    $getPortInfo=$getPortInfo -replace '\D+',':'
    #if the last char of the string is ':', which will be the case in localized version,
    #remove the last char 
    if($getPortInfo[$getPortInfo.Length-1] -eq ':')
    { 
        $getPortInfo=$getPortInfo.Substring(0,$getPortInfo.Length - 1) 
    }
    #Get the peocessID corresponding to the current listening port
    #And the process with this processID
    $portProcessId = $getPortInfo.Split(":")[-1]
    $processOnPort = Get-Process -ID $portProcessId
    #If the process is not NPMD, terminate the script
    #else we will be updating the rules
    if($processOnPort -and $processOnPort.Name -eq $NPMDProcess)
    {
        EnableDisableFirewallRule   
    }
    else
    {
        Write-Host "Port number" $portNumber "already in use by some other process.`nPlease specify a different port using the argument [portNumber] to the script.`nYou must ensure that same port is used while running this script on other machines." -ForegroundColor "red"
        exit
    }
}
else
{
    EnableDisableFirewallRule
}
# SIG # Begin signature block
# MIIakwYJKoZIhvcNAQcCoIIahDCCGoACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYNwN1rUqcEdm0xuEzhPMMVTE
# qgSgghVgMIIEwjCCA6qgAwIBAgITMwAAAMEJ+AJBu02q3AAAAAAAwTANBgkqhkiG
# 9w0BAQUFADB3MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEw
# HwYDVQQDExhNaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTYwOTA3MTc1ODUw
# WhcNMTgwOTA3MTc1ODUwWjCBsjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEMMAoGA1UECxMDQU9DMScwJQYDVQQLEx5uQ2lwaGVyIERTRSBFU046
# MTJFNy0zMDY0LTYxMTIxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNl
# cnZpY2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCnQx/5lyl8yUKs
# OCe7goaBSbYZRGLqqBkrgKhq8dH8OM02K+bXkjkBBc3oxkLyHPwFN5BUpQQY9rEG
# ywPRQNdZs+ORWsZU5DRjq+pmFIB+8mMDl9DoDh9PHn0d+kqLCjTpzeMKMY3OFLCB
# tZM0mUmAyFGtDbAaT+V/5pR7TFcWohavrNNFERDbFL1h3g33aRN2IS5I0DRISNZe
# +o5AvedZa+BLADFpBegnHydhbompjhg5oH7PziHYYKnSZB/VtGD9oPcte8fL5xr3
# zQ/v8VbQLSo4d2Y7yDOgUaeMgguDWFQk/BTyIhAMi2WYLRr1IzjUWafUWXrRAejc
# H4/LGxGfAgMBAAGjggEJMIIBBTAdBgNVHQ4EFgQU5Wc2VV+w+VLFrEvWbjW/iDqt
# Ra8wHwYDVR0jBBgwFoAUIzT42VJGcArtQPt2+7MrsMM1sw8wVAYDVR0fBE0wSzBJ
# oEegRYZDaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljcm9zb2Z0VGltZVN0YW1wUENBLmNybDBYBggrBgEFBQcBAQRMMEowSAYIKwYB
# BQUHMAKGPGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9z
# b2Z0VGltZVN0YW1wUENBLmNydDATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQUFAAOCAQEANDgLKXRowe/Nzu4x3vd07BG2sXKl3uYIgQDBrw83AWJ0nZ15
# VwL0KHe4hEkjNVn16/j0qOADdl5AS0IemYRZ3Ro9Qexf4jgglAXXm+k+bbHkYfOZ
# 3g+pFhs5+MF6vY6pWB7IHmkJhzs1OHn1rFNBNYVO12DhuPYYr//7KIN52jd6I86o
# yM+67V1W8ku8SsbnPz2gBDoYIeHkzaSZCoX2+i2eL5EL3d8TEXXqKjnxh5xEcdPz
# BuVnt3VIu8SjWdyy/ulTzBy+jRFLcTyfGQm19mlerWcwfV271WWbhTpgxAQugy9o
# 6PM4DR9HIEz6vRUYyIfX09FxoX5pENTGzssKyDCCBMswggOzoAMCAQICEzMAAAGD
# xsfeNDgwnm8AAQAAAYMwDQYJKoZIhvcNAQEFBQAweTELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjEjMCEGA1UEAxMaTWljcm9zb2Z0IENvZGUgU2ln
# bmluZyBQQ0EwHhcNMTcxMTAxMTkwNjAzWhcNMTgxMTAxMTkwNjAzWjB0MQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCK
# riAMJqDcVlyNeYPH/twss6HdEzSSGFdYljXwbAIR5i8oj/FoQOkaHUAbr19aE4sP
# 8ueR+FEBlJetLT4v6km1gJA/3N+bl9LB3MoajchcKi/xVoGCM9jnouE7re/PNRIt
# hRSEU0fU0kaQ7lA8V5GQ8keWdEhuET9AWLS9vEFfwLSQu0WsspUIFSmnZFDoxbOv
# 8/GL6Gsik/cyLtT88V3bYIJE7JG6SylFFhOjjfDiIR80VcYbiFkHeYZVmRhuYhwa
# nbDcLOOEAT4uvWODIfCBueEU4xgULuDWctZXF4v8xK7JshhyXYjNkPJcfyWIfoMP
# VOzUVRuJezzcNSjpvqxNAgMBAAGjggFPMIIBSzAfBgNVHSUEGDAWBgorBgEEAYI3
# TBQBBggrBgEFBQcDAzAdBgNVHQ4EFgQULYoazBpoli+S1X9BwRULA/V2JdAwNAYD
# VR0RBC0wK6QpMCcxDTALBgNVBAsTBE1PUFIxFjAUBgNVBAUTDTIzMzEyNysyNDMz
# MDAwHwYDVR0jBBgwFoAUyxHoytK0FlgByTcuMxYWuUyaCh8wVgYDVR0fBE8wTTBL
# oEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVjdHMv
# TWljQ29kU2lnUENBXzA4LTMxLTIwMTAuY3JsMFoGCCsGAQUFBwEBBE4wTDBKBggr
# BgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWND
# b2RTaWdQQ0FfMDgtMzEtMjAxMC5jcnQwDQYJKoZIhvcNAQEFBQADggEBAGkvETWY
# qabqosDmo6dg7JAvK2TB7Rbb6ugZSGp31Th0H0A67Ldn5jk7Gj9qK34o85wXviV3
# +d/TSu92rAmckl6nxgP1oqtppREFBKpOgpMY5uQ6reyY741zKkGucGAgCNQHqu6i
# NybkB+sOKACAq8sq1BYu3WMOkXwaolAQAeg8yXOZEuHMK5RCi24JitK0DSIhXSUh
# vV4mTQoh0de9kXtOLfTiRg1AG7RDK9lE+PbrtLTaZVmgyPsbvwf4R8WF9fEN4NwP
# 1O5j9IO5Z86M88iXwGZNpi0gp3pyTFtsJyNhfQUtm2g5nv+rtIWSd2YDGyitzTQa
# zw5e9LoHM50P24YwggW8MIIDpKADAgECAgphMyYaAAAAAAAxMA0GCSqGSIb3DQEB
# BQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/IsZAEZFgltaWNy
# b3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eTAeFw0xMDA4MzEyMjE5MzJaFw0yMDA4MzEyMjI5MzJaMHkxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBD
# b2RlIFNpZ25pbmcgUENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# snJZXBkwZL8dmmAgIEKZdlNsPhvWb8zL8epr/pcWEODfOnSDGrcvoDLs/97CQk4j
# 1XIA2zVXConKriBJ9PBorE1LjaW9eUtxm0cH2v0l3511iM+qc0R/14Hb873yNqTJ
# XEXcr6094CholxqnpXJzVvEXlOT9NZRyoNZ2Xx53RYOFOBbQc1sFumdSjaWyaS/a
# GQv+knQp4nYvVN0UMFn40o1i/cvJX0YxULknE+RAMM9yKRAoIsc3Tj2gMj2QzaE4
# BoVcTlaCKCoFMrdL109j59ItYvFFPeesCAD2RqGe0VuMJlPoeqpK8kbPNzw4nrR3
# XKUXno3LEY9WPMGsCV8D0wIDAQABo4IBXjCCAVowDwYDVR0TAQH/BAUwAwEB/zAd
# BgNVHQ4EFgQUyxHoytK0FlgByTcuMxYWuUyaCh8wCwYDVR0PBAQDAgGGMBIGCSsG
# AQQBgjcVAQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFP3RMU7TJoqV4ZhgO6gxb6Y8
# vNgtMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMB8GA1UdIwQYMBaAFA6sgmBA
# VieX5SUT/CrhClOVWeSkMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwubWlj
# cm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jvc29mdHJvb3RjZXJ0LmNy
# bDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0dHA6Ly93d3cubWljcm9z
# b2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENlcnQuY3J0MA0GCSqGSIb3
# DQEBBQUAA4ICAQBZOT5/Jkav629AsTK1ausOL26oSffrX3XtTDst10OtC/7L6S0x
# oyPMfFCYgCFdrD0vTLqiqFac43C7uLT4ebVJcvc+6kF/yuEMF2nLpZwgLfoLUMRW
# zS3jStK8cOeoDaIDpVbguIpLV/KVQpzx8+/u44YfNDy4VprwUyOFKqSCHJPilAcd
# 8uJO+IyhyugTpZFOyBvSj3KVKnFtmxr4HPBT1mfMIv9cHc2ijL0nsnljVkSiUc35
# 6aNYVt2bAkVEL1/02q7UgjJu/KSVE+Traeepoiy+yCsQDmWOmdv1ovoSJgllOJTx
# eh9Ku9HhVujQeJYYXMk1Fl/dkx1Jji2+rTREHO4QFRoAXd01WyHOmMcJ7oUOjE9t
# DhNOPXwpSJxy0fNsysHscKNXkld9lI2gG0gDWvfPo2cKdKU27S0vF8jmcjcS9G+x
# PGeC+VKyjTMWZR4Oit0Q3mT0b85G1NMX6XnEBLTT+yzfH4qerAr7EydAreT54al/
# RrsHYEdlYEBOsELsTu2zdnnYCjQJbRyAMR/iDlTd5aH75UcQrWSY/1AWLny/BSF6
# 4pVBJ2nDk4+VyY3YmyGuDVyc8KKuhmiDDGotu3ZrAB2WrfIWe/YWgyS5iM9qqEcx
# L5rc43E91wB+YkfRzojJuBj6DnKNwaM9rwJAav9pm5biEKgQtDdQCNbDPTCCBgcw
# ggPvoAMCAQICCmEWaDQAAAAAABwwDQYJKoZIhvcNAQEFBQAwXzETMBEGCgmSJomT
# 8ixkARkWA2NvbTEZMBcGCgmSJomT8ixkARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMk
# TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MB4XDTA3MDQwMzEy
# NTMwOVoXDTIxMDQwMzEzMDMwOVowdzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAn6Fssd/bSJIqfGsuGeG94uPF
# mVEjUK3O3RhOJA/u0afRTK10MCAR6wfVVJUVSZQbQpKumFwwJtoAa+h7veyJBw/3
# DgSY8InMH8szJIed8vRnHCz8e+eIHernTqOhwSNTyo36Rc8J0F6v0LBCBKL5pmyT
# Z9co3EZTsIbQ5ShGLieshk9VUgzkAyz7apCQMG6H81kwnfp+1pez6CGXfvjSE/MI
# t1NtUrRFkJ9IAEpHZhEnKWaol+TTBoFKovmEpxFHFAmCn4TtVXj+AZodUAiFABAw
# Ru233iNGu8QtVJ+vHnhBMXfMm987g5OhYQK1HQ2x/PebsgHOIktU//kFw8IgCwID
# AQABo4IBqzCCAacwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUIzT42VJGcArt
# QPt2+7MrsMM1sw8wCwYDVR0PBAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEAMIGYBgNV
# HSMEgZAwgY2AFA6sgmBAVieX5SUT/CrhClOVWeSkoWOkYTBfMRMwEQYKCZImiZPy
# LGQBGRYDY29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRN
# aWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHmCEHmtFqFKoKWtTHNY
# 9AcTLmUwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC5taWNyb3NvZnQuY29t
# L3BraS9jcmwvcHJvZHVjdHMvbWljcm9zb2Z0cm9vdGNlcnQuY3JsMFQGCCsGAQUF
# BwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aS9jZXJ0cy9NaWNyb3NvZnRSb290Q2VydC5jcnQwEwYDVR0lBAwwCgYIKwYBBQUH
# AwgwDQYJKoZIhvcNAQEFBQADggIBABCXisNcA0Q23em0rXfbznlRTQGxLnRxW20M
# E6vOvnuPuC7UEqKMbWK4VwLLTiATUJndekDiV7uvWJoc4R0Bhqy7ePKL0Ow7Ae7i
# vo8KBciNSOLwUxXdT6uS5OeNatWAweaU8gYvhQPpkSokInD79vzkeJkuDfcH4nC8
# GE6djmsKcpW4oTmcZy3FUQ7qYlw/FpiLID/iBxoy+cwxSnYxPStyC8jqcD3/hQoT
# 38IKYY7w17gX606Lf8U1K16jv+u8fQtCe9RTciHuMMq7eGVcWwEXChQO0toUmPU8
# uWZYsy0v5/mFhsxRVuidcJRsrDlM1PZ5v6oYemIp76KbKTQGdxpiyT0ebR+C8AvH
# LLvPQ7Pl+ex9teOkqHQ1uE7FcSMSJnYLPFKMcVpGQxS8s7OwTWfIn0L/gHkhgJ4V
# MGboQhJeGsieIiHQQ+kr6bv0SMws1NgygEwmKkgkX1rqVu+m3pmdyjpvvYEndAYR
# 7nYhv5uCwSdUtrFqPYmhdmG0bqETpr+qR/ASb/2KMmyy/t9RyIwjyWa9nR2HEmQC
# PS2vWY+45CHltbDKY7R4VAXUQS5QrJSwpXirs6CWdRrZkocTdSIvMqgIbqBbjCW/
# oO+EyiHW6x5PyZruSeD3AWVviQt9yGnI5m7qp5fOMSn/DsVbXNhNG6HY+i+ePy5V
# FmvJE6P9MYIEnTCCBJkCAQEwgZAweTELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEjMCEGA1UEAxMaTWljcm9zb2Z0IENvZGUgU2lnbmluZyBQQ0EC
# EzMAAAGDxsfeNDgwnm8AAQAAAYMwCQYFKw4DAhoFAKCBtjAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkq
# hkiG9w0BCQQxFgQU7u7PMgXXBBgEIXDvL5f57vJ4ABgwVgYKKwYBBAGCNwIBDDFI
# MEagJIAiAE0AaQBjAHIAbwBzAG8AZgB0ACAAVwBpAG4AZABvAHcAc6EegBxodHRw
# czovL2F6dXJlLm1pY3Jvc29mdC5jb20vMA0GCSqGSIb3DQEBAQUABIIBAIi2I/t9
# 7Uaq0xRXuwPWEPhStilP4U5Nd47cdF9qHrr6NdCUIQP/ZXVcQt72c9wPsoHl9kXr
# lgPTDBRUts/tjDqoiv4lBeOUHq/wsYgyCKnPx3fV2y8V/9+hWImyd36eTBzJIpNF
# cUExPpIaQDQt6VS0aTnGcTsy9LDYC794ltMpGGb5U+IfheQD5qK0ZAdEpmDfRR6/
# aL6+N8r86w+MgeDWvVQ9CLB3aoWoEeM63ZjTpZQBj3wXoSYNMJmz02e22j7KkzhZ
# pavIteAESK4dxwvaU0UGtKOwKQa+UQk9qy44Bivq18LBweIOOjxHcw3mGJZ3TIoY
# RczVKcoiF+mf1XihggIoMIICJAYJKoZIhvcNAQkGMYICFTCCAhECAQEwgY4wdzEL
# MAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1v
# bmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWlj
# cm9zb2Z0IFRpbWUtU3RhbXAgUENBAhMzAAAAwQn4AkG7TarcAAAAAADBMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0xODAzMTAxMzA2MTZaMCMGCSqGSIb3DQEJBDEWBBTGeV0d15Pp2BTYfYoMa+Dk
# L/okQzANBgkqhkiG9w0BAQUFAASCAQBHfeLe1jL2mvBSz1ZU5T3gf1sGby8qGHYy
# Mpszq236Ci0weCDe+UJpNwDI5b69MkoAeDhYwm24UYIouYok+3ebAP3y2akxq/n9
# XsYm5XMHjfffNU/cUTWYEw+BfVAmAvE/n3LJeBLSzoY8uCwfGFceIk8dsUhjlF32
# DgQ3sJQm6omwfPSG6f7QE5FvYKFtjAjuuegjw8K+in6IUdgnR+euvC4+9HJNcLAj
# pYAkiCOl9kKKfZ1xktNVimA59isoXnToOuJhaUgWjYmBvJaMJChJx4tXswDvfd6c
# ToS6ixa6Hnen0krFHpBnuwWjPEF7PN66AleoXpkdX+KSWC/1Kpts
# SIG # End signature block
