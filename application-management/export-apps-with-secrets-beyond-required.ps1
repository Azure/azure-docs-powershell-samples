#################################################################################
#DISCLAIMER: This is not an official PowerShell Script. We designed it specifically for the situation you have encountered right now.
#Please do not modify or change any preset parameters. 
#Please note that we will not be able to support the script if it is changed or altered in any way or used in a different situation for other means.

#This code-sample is provided "AS IT IS" without warranty of any kind, either expressed or implied, including but not limited to the implied warranties of merchantability and/or fitness for a particular purpose.
#This sample is not supported under any Microsoft standard support program or service.. 
#Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
#The entire risk arising out of the use or performance of the sample and documentation remains with you. 
#In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the script be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of  the use of or inability to use the sample or documentation, even if Microsoft has been advised of the possibility of such damages.
#################################################################################

$loginURL = "https://login.microsoftonline.com"
$resource = "https://graph.microsoft.com"

#PARAMETERS TO CHANGE
$ClientID = "App ID"
$ClientSecret = "APP Secret"
$TenantName = "TENANT.onmicrosoft.com"

$Months = "Number of months"
$Path = "add a path here\File.csv"
###################################################################
#Repeating Function to get an Access Token based on the parameters:
function RefreshToken($loginURL, $ClientID, $clientSecret, $tenantName) { 
    $body = @{grant_type = "client_credentials"; client_id = $ClientID; client_secret = $ClientSecret; scope = "https://graph.microsoft.com/.default" } 
    $oauthResponse = Invoke-RestMethod -Method POST -Uri $loginURL/$TenantName/oauth2/v2.0/token -Body $body 
    return $oauthResponse
}

#BUILD THE ACCESS TOKEN
$oauth = RefreshToken -loginURL $loginURL -resource $resource -ClientID $ClientID -clientSecret $ClientSecret -tenantName $TenantName
$Identity = $oauth.access_token

##############################################

$headerParams = @{'Authorization' = "$($oauth.token_type) $($Identity)" }
$AppsSecrets = "https://graph.microsoft.com/v1.0/applications"

$ApplicationsList = (Invoke-WebRequest -Headers $headerParams -Uri $AppsSecrets -Method GET)
$Logs = @()
$NextCounter = 0

do {
    foreach ($event in ($ApplicationsList.Content | ConvertFrom-Json | select -ExpandProperty value)) { 
        $ids = $event.id
        $AppName = $event.displayName
        $AppID = $event.appId
        $secrets = $event.passwordCredentials
        $NextCounter++

        foreach ($s in $secrets) {
            $StartDate = $s.startDateTime
            $EndDate = $s.endDateTime
            $pos = $StartDate.IndexOf("T")
            $leftPart = $StartDate.Substring(0, $pos)
            $position = $EndDate.IndexOf("T")
            $leftPartEnd = $EndDate.Substring(0, $pos)
            $DatestringStart = [Datetime]::ParseExact($leftPart, 'yyyy-MM-dd', $null)
            $DatestringEnd = [Datetime]::ParseExact($leftPartEnd, 'yyyy-MM-dd', $null)
            $OptimalDate = $DatestringStart.AddMonths($Months)

            if ($OptimalDate -lt $DatestringEnd) {
                $Log = New-Object System.Object
                $Log | Add-Member -MemberType NoteProperty -Name "Application" -Value $AppName
                $Log | Add-Member -MemberType NoteProperty -Name  "AppID" -value $AppID
                $Log | Add-Member -MemberType NoteProperty -Name "Secret Start Date" -Value $DatestringStart
                $Log | Add-Member -MemberType NoteProperty -Name  "Secret End Date" -value $DatestringEnd

                $Owners = "https://graph.microsoft.com/v1.0/applications/$ids/owners"
                $ApplicationsOwners = (Invoke-WebRequest -Headers $headerParams -Uri $Owners -Method GET)

                foreach ($user in ($ApplicationsOwners.Content | ConvertFrom-Json | select -ExpandProperty value)) {
                    $Owner = $user.displayname
                    $Log | Add-Member -MemberType NoteProperty -Name  "AppOwner" -value $Owner
                }
                $Logs += $Log
            }
        }

        If ($NextCounter -eq 100) {
            $odata = $ApplicationsList.Content | ConvertFrom-Json
            $AppsSecrets = $odata.'@odata.nextLink'
            try {
                $ApplicationsList = Invoke-WebRequest -UseBasicParsing -Headers $headerParams -Uri $AppsSecrets -Method Get -ContentType "application/Json"
            }
            catch {
                $_
            }

            $NextCounter = 0
            sleep 1
        }
    }

} while ($AppsSecrets -ne $null)

$Logs | Export-CSV $Path -NoTypeInformation -Encoding UTF8
