# Display users and groups assigned to a specific Application Proxy application

$AADAPServPrincObjId="OBJECT_ID_OF_THE_SERVICE_PRINCE_PRINCIPAL_OF_THE_AADP_APPLICATION"
$users=Get-AzureADUser -Top 1000000
$groups=Get-AzureADGroup -Top 1000000 

$app=Get-AzureADServicePrincipal -ObjectId $AADAPServPrincObjId

Write-Host ("Application: " + $app.DisplayName + "(ServicePrinc. ObjID:"+$AADAPServPrincObjId+")")
Write-Host ("")
Write-Host ("Assigned (directly and through group membership) users:")
Write-Host ("")

$number=0

foreach ($item in $users)
  {
   $listOfAssignments=Get-AzureADUserAppRoleAssignment -ObjectId $item.ObjectId

   $assigned=$false

   foreach ($item2 in $listOfAssignments) 
     {
      If ($item2.ResourceID -eq $AADAPServPrincObjId) 
        {  
          $assigned=$true
        }
     }

     If ($assigned -eq $true)
      {
        Write-Host ("DisplayName: " + $item.DisplayName + " UPN: " + $item.UserPrincipalName + " ObjectID: " + $item.ObjectID)
        $number=$number+1
      }
  }

Write-Host ("")
Write-Host ("Number of (directly and through group membership) users: " + $number)
Write-Host ("")
Write-Host ("")
Write-Host ("Assigned groups:")
Write-Host ("")

$number=0

foreach ($item in $groups)
  {
   $listOfAssignments=Get-AzureADGroupAppRoleAssignment -ObjectId $item.ObjectId

   $assigned=$false

   foreach ($item2 in $listOfAssignments) 
     {
      If ($item2.ResourceID -eq $AADAPServPrincObjId) 
        {  
          $assigned=$true
        }
     }

     If ($assigned -eq $true)
      {
        Write-Host ("DisplayName: " + $item.DisplayName + " ObjectID: " + $item.ObjectID)
        $number=$number+1
      }
  }

  
Write-Host ("")
Write-Host ("Number of assigned groups: " + $number)
Write-Host ("")
 
