# Assign a user to a specific Azure AD Application Proxy application

$AADAPServPrincObjId="OBJECT_ID_OF_THE_SERVICE_PRINCE_PRINCIPAL_OF_THE_AADP_APPLICATION"
$userObjectId="OBJECTID_OF_THE_USER"

New-AzureADUserAppRoleAssignment -ObjectId $userObjectId -PrincipalId $userObjectId -ResourceId $AADAPServPrincObjId -Id 18d14569-c3bd-439b-9a66-3a2aee01d14f 

# Assign a group to a specific Azure AD Application Proxy application

$AADAPServPrincObjId="OBJECT_ID_OF_THE_SERVICE_PRINCE_PRINCIPAL_OF_THE_AADP_APPLICATION"
$groupObjectId="OBJECTID_OF_THE_GROUP"

New-AzureADGroupAppRoleAssignment -ObjectId $groupObjectId -PrincipalId $groupObjectId -ResourceId $AADAPServPrincObjId -Id 18d14569-c3bd-439b-9a66-3a2aee01d14f  
