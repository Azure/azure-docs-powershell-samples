# Display users and groups assigned to a specific Application Proxy application

$AADAPSERVPRINCOBJID="OBJECT_ID_OF_THE_SERVICE_PRINCE_PRINCIPAL_OF_THE_AADP_APPLICATION"
$USERS=Get-AzureADUser -Top 1000000
$GROUPS=Get-AzureADGroup -Top 1000000 

$APP=Get-AzureADServicePrincipal -ObjectId $AADAPSERVPRINCOBJID

Write-Host ("Application: " + $APP.DisplayName + "(ServicePrinc. ObjID:"+$AADAPSERVPRINCOBJID+")")
Write-Host ("")
Write-Host ("Assigned (directly and through group membership) users:")
Write-Host ("")

$NUMBER=0

foreach ($ITEM in $USERS)
  {
   $LISTOFASSIGNEMENTS=Get-AzureADUserAppRoleAssignment -ObjectId $ITEM.ObjectId

   $ASSIGNED=$false

   foreach ($ITEM2 in $LISTOFASSIGNEMENTS) 
     {
      If ($ITEM2.ResourceID -eq $AADAPSERVPRINCOBJID) 
        {  
          $ASSIGNED=$true
        }
     }

     If ($ASSIGNED -eq $true)
      {
        Write-Host ("DisplayName: " + $ITEM.DisplayName + " UPN: " + $ITEM.UserPrincipalName + " ObjectID: " + $ITEM.ObjectID)
        $NUMBER=$NUMBER+1
      }
  }

Write-Host ("")
Write-Host ("Number of (directly and through group membership) users: " + $NUMBER)
Write-Host ("")
Write-Host ("")
Write-Host ("Assigned groups:")
Write-Host ("")

$NUMBER=0

foreach ($ITEM in $GROUPS)
  {
   $LISTOFASSIGNEMENTS=Get-AzureADGroupAppRoleAssignment -ObjectId $ITEM.ObjectId

   $ASSIGNED=$false

   foreach ($ITEM2 in $LISTOFASSIGNEMENTS) 
     {
      If ($ITEM2.ResourceID -eq $AADAPSERVPRINCOBJID) 
        {  
          $ASSIGNED=$true
        }
     }

     If ($ASSIGNED -eq $true)
      {
        Write-Host ("DisplayName: " + $ITEM.DisplayName + " ObjectID: " + $ITEM.ObjectID)
        $NUMBER=$NUMBER+1
      }
  }

  
Write-Host ("")
Write-Host ("Number of assigned groups: " + $NUMBER)
Write-Host ("")
 
