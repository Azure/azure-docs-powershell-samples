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

Connect-MgGraph -Scopes "Application.ReadWrite.All"

$Applications = Get-MgServicePrincipal -all
$Logs = @()
Write-host "I would like to see the Applications with the Secrets that expire in the next X amount of Days? <<Replace X with the number of days. The answer should be ONLY in Numbers>>" -ForegroundColor Green
$Days = Read-Host

Write-host "Would you like to see Applications with already expired secrets as well? <<Answer with [Yes] [No]>>" -ForegroundColor Green
$AlreadyExpired = Read-Host

$now = get-date

Write-Host "The operation is running and will take longer the more applications the tenant has...Please wait..."  -ForegroundColor yellow

foreach ($app in $Applications) {
    $AppName = $app.DisplayName
    $AppID = $app.Id
    $ApplID = $app.AppId
    $AppCreds = Get-MgServicePrincipal -ServicePrincipalId $AppID |
        Select-Object PasswordCredentials, KeyCredentials
    $secret = $AppCreds.PasswordCredentials
    $cert = $AppCreds.KeyCredentials

    foreach ($s in $secret) {
        $StartDate = $s.StartDateTime
        $EndDate = $s.EndDateTime
        $SecretName = $s.DisplayName

        $operation = $EndDate - $now
        $ODays = $operation.Days

        if ($AlreadyExpired -eq "No") {
            if ($ODays -le $Days -and $ODays -ge 0) {
                $Owner = Get-MgServicePrincipalOwner -ServicePrincipalId $app.Id
                $Username = $Owner.AdditionalProperties.userPrincipalName -join ";"
                $OwnerID = $Owner.Id -join ";"

                if ($null -eq $Owner.AdditionalProperties.userPrincipalName) {
                    $Username = $Owner.AdditionalProperties.displayName + " **<This is an Application>**"
                }

                if ($null -eq $Owner.AdditionalProperties.displayName) {
                    $Username = "<<No Owner>>"
                }

                $Log = New-Object System.Object

                $Log | Add-Member -MemberType NoteProperty -Name "ApplicationName" -Value $AppName
                $Log | Add-Member -MemberType NoteProperty -Name "ApplicationID" -Value $ApplID
                $Log | Add-Member -MemberType NoteProperty -Name "Secret Name" -Value $SecretName
                $Log | Add-Member -MemberType NoteProperty -Name "Secret Start Date" -Value $StartDate
                $Log | Add-Member -MemberType NoteProperty -Name "Secret End Date" -value $EndDate
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate Name" -Value $Null
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate Start Date" -Value $Null
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate End Date" -value $Null
                $Log | Add-Member -MemberType NoteProperty -Name "Owner" -Value $Username
                $Log | Add-Member -MemberType NoteProperty -Name "Owner_ObjectID" -value $OwnerID
                $Logs += $Log
            }
        }

        elseif ($AlreadyExpired -eq "Yes") {
            if ($ODays -le $Days) {
                $Owner = Get-MgServicePrincipalOwner -ServicePrincipalId $app.Id
                $Username = $Owner.AdditionalProperties.userPrincipalName -join ";"
                $OwnerID = $Owner.Id -join ";"

                if ($null -eq $Owner.AdditionalProperties.userPrincipalName) {
                    $Username = $Owner.AdditionalProperties.displayName + " **<This is an Application>**"
                }

                if ($null -eq $Owner.AdditionalProperties.displayName) {
                    $Username = "<<No Owner>>"
                }

                $Log = New-Object System.Object

                $Log | Add-Member -MemberType NoteProperty -Name "ApplicationName" -Value $AppName
                $Log | Add-Member -MemberType NoteProperty -Name "ApplicationID" -Value $ApplID
                $Log | Add-Member -MemberType NoteProperty -Name "Secret Name" -Value $SecretName
                $Log | Add-Member -MemberType NoteProperty -Name "Secret Start Date" -Value $StartDate
                $Log | Add-Member -MemberType NoteProperty -Name "Secret End Date" -value $EndDate
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate Name" -Value $Null
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate Start Date" -Value $Null
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate End Date" -value $Null
                $Log | Add-Member -MemberType NoteProperty -Name "Owner" -Value $Username
                $Log | Add-Member -MemberType NoteProperty -Name "Owner_ObjectID" -value $OwnerID
                $Logs += $Log
            }
        }
    }


    foreach ($c in $cert) {
        $CStartDate = $c.StartDateTime
        $CEndDate = $c.EndDateTime
        $CertName = $c.DisplayName

        $operation = $EndDate - $now
        $ODays = $operation.Days

        if ($AlreadyExpired -eq "No") {
            if ($ODays -le $Days -and $ODays -ge 0) {
                $Owner = Get-MgServicePrincipalOwner -ServicePrincipalId $app.Id
                $Username = $Owner.AdditionalProperties.userPrincipalName -join ";"
                $OwnerID = $Owner.Id -join ";"

                if ($null -eq $Owner.AdditionalProperties.userPrincipalName) {
                    $Username = $Owner.AdditionalProperties.displayName + " **<This is an Application>**"
                }
                if ($null -eq $Owner.AdditionalProperties.displayName) {
                    $Username = "<<No Owner>>"
                }

                $Log = New-Object System.Object

                $Log | Add-Member -MemberType NoteProperty -Name "ApplicationName" -Value $AppName
                $Log | Add-Member -MemberType NoteProperty -Name "ApplicationID" -Value $ApplID
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate Name" -Value $CertName
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate Start Date" -Value $CStartDate
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate End Date" -value $CEndDate
                $Log | Add-Member -MemberType NoteProperty -Name "Owner" -Value $Username
                $Log | Add-Member -MemberType NoteProperty -Name "Owner_ObjectID" -value $OwnerID
                $Logs += $Log
            }
        } elseif ($AlreadyExpired -eq "Yes") {
            if ($ODays -le $Days) {
                $Owner = Get-MgServicePrincipalOwner -ServicePrincipalId $app.Id
                $Username = $Owner.AdditionalProperties.userPrincipalName -join ";"
                $OwnerID = $Owner.Id -join ";"

                if ($null -eq $Owner.AdditionalProperties.userPrincipalName) {
                    $Username = $Owner.AdditionalProperties.displayName + " **<This is an Application>**"
                }
                if ($null -eq $Owner.AdditionalProperties.displayName) {
                    $Username = "<<No Owner>>"
                }

                $Log = New-Object System.Object

                $Log | Add-Member -MemberType NoteProperty -Name "ApplicationName" -Value $AppName
                $Log | Add-Member -MemberType NoteProperty -Name "ApplicationID" -Value $ApplID
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate Name" -Value $CertName
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate Start Date" -Value $CStartDate
                $Log | Add-Member -MemberType NoteProperty -Name "Certificate End Date" -value $CEndDate
                $Log | Add-Member -MemberType NoteProperty -Name "Owner" -Value $Username
                $Log | Add-Member -MemberType NoteProperty -Name "Owner_ObjectID" -value $OwnerID
                $Logs += $Log
            }
        }
    }
}

Write-host "Add the Path you'd like us to export the CSV file to, in the format of <C:\Users\<USER>\Desktop\Users.csv>" -ForegroundColor Green
$Path = Read-Host
$Logs | Export-CSV $Path -NoTypeInformation -Encoding UTF8
