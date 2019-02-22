$rgName = <Specify your lab's resource group name>
$subscriptionId = <Specify your subscription ID>
$labName = <Specify your lab name>


‘List all the operations/actions for a resource provider.
Get-AzProviderOperation -OperationSearchString "Microsoft.DevTestLab/*"

‘List actions in a particular role.
(Get-AzRoleDefinition "DevTest Labs User").Actions

‘Create custom role.
$policyRoleDef = (Get-AzRoleDefinition "DevTest Labs User")
$policyRoleDef.Id = $null
$policyRoleDef.Name = "Policy Contributor"
$policyRoleDef.IsCustom = $true
$policyRoleDef.AssignableScopes.Clear()
$policyRoleDef.AssignableScopes.Add("/subscriptions/" + $subscriptionId)
$policyRoleDef.Actions.Add("Microsoft.DevTestLab/labs/policySets/policies/*")
$policyRoleDef = (New-AzRoleDefinition -Role $policyRoleDef)

$user=Get-AzADUser -SearchString "SomeUser"
$scope = '/subscriptions/' + subscriptionId + '/resourceGroups/' + $rgName + '/providers/Microsoft.DevTestLab/labs/' + $labName + '/policySets/default/policies/AllowedVmSizesInLab'
New-AzRoleAssignment -ObjectId $user.ObjectId -RoleDefinitionName "Policy Contributor" -Scope $scope
