# Sample script: Display users and groups assigned to the specified Application Proxy application
#
# .\display-users-group-of-an-app.ps1 -ObjectId <ObjectId of the application>
#
# Required AAD role: Global Administrator or Application Administrator
#
# PowerShell 5.1 (x64), module: , AzureAD 2.0.2.52 / AzureADPreview 2.0.2.53

param(
[string] $ObjectId = "null"
)

$aadapServPrincObjId=$ObjectId

If ($aadapServPrincObjId -eq "null") {

    Write-Host "Parameter is missing." -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "
    Write-Host ".\display-users-group-of-an-app.ps1 -ObjectId <ObjectId of the application>" -BackgroundColor "Black" -ForegroundColor "Green"
    Write-Host " "

    Exit
}

Write-Host "Reading users. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$users=Get-AzureADUser -Top 1000000

Write-Host "Reading groups. This operation might take longer..." -BackgroundColor "Black" -ForegroundColor "Green"

$groups = Get-AzureADGroup -Top 1000000 

$aadapApp = $aadapServPrinc | ForEach-Object { $allApps -match $_.AppId } 

Write-Host "Displaying users and groups assigned to the specified Application Proxy application..." -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host " "

try { $app = Get-AzureADServicePrincipal -ObjectId $aadapServPrincObjId}

catch {

    Write-Host "Possibly the ObjetId is incorrect." -BackgroundColor "Black" -ForegroundColor "Red"
    Write-Host " "

    Exit
}

Write-Host ("Application: " + $app.DisplayName + "(ServicePrinc. ObjID:" + $aadapServPrincObjId + ")")
Write-Host ("")
Write-Host ("Assigned (directly and through group membership) users:")
Write-Host ("")

$number=0

foreach ($item in $users) {

   $listOfAssignments = Get-AzureADUserAppRoleAssignment -ObjectId $item.ObjectId

   $assigned = $false

   foreach ($item2 in $listOfAssignments) { If ($item2.ResourceID -eq $aadapServPrincObjId) { $assigned = $true } }

     If ($assigned -eq $true) {
        Write-Host ("DisplayName: " + $item.DisplayName + " UPN: " + $item.UserPrincipalName + " ObjectID: " + $item.ObjectID)
        $number = $number + 1
     }
}

Write-Host ("")
Write-Host ("Number of (directly and through group membership) users: " + $number)
Write-Host ("")
Write-Host ("")
Write-Host ("Assigned groups:")
Write-Host ("")

$number=0

foreach ($item in $groups) {

   $listOfAssignments = Get-AzureADGroupAppRoleAssignment -ObjectId $item.ObjectId

   $assigned = $false

   foreach ($item2 in $listOfAssignments) { If ($item2.ResourceID -eq $aadapServPrincObjId) { $assigned = $true } }

   If ($assigned -eq $true) {
        Write-Host ("DisplayName: " + $item.DisplayName + " ObjectID: " + $item.ObjectID)
        $number=$number+1
   }
}

  
Write-Host ("")
Write-Host ("Number of assigned groups: " + $number)
Write-Host ("")

Write-Host ("")
Write-Host ("Finished.") -BackgroundColor "Black" -ForegroundColor "Green"
Write-Host ("") 

