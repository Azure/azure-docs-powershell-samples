$rgName = <Specify your lab's resource group name>
$subscriptionId = <Specify your subscription ID>
$labName = <Specify your lab name>


‘List all the operations/actions for a resource provider.
Get-AzureRmProviderOperation -OperationSearchString "Microsoft.DevTestLab/*"

‘List actions in a particular role.
(Get-AzureRmRoleDefinition "DevTest Labs User").Actions

‘Create custom role.
$policyRoleDef = (Get-AzureRmRoleDefinition "DevTest Labs User")
$policyRoleDef.Id = $null
$policyRoleDef.Name = "Policy Contributor"
$policyRoleDef.IsCustom = $true
$policyRoleDef.AssignableScopes.Clear()
$policyRoleDef.AssignableScopes.Add("/subscriptions/" + $subscriptionId)
$policyRoleDef.Actions.Add("Microsoft.DevTestLab/labs/policySets/policies/*")
$policyRoleDef = (New-AzureRmRoleDefinition -Role $policyRoleDef)

$user=Get-AzureRmADUser -SearchString "SomeUser"
$scope = '/subscriptions/' + subscriptionId + '/resourceGroups/' + $rgName + '/providers/Microsoft.DevTestLab/labs/' + $labName + '/policySets/default/policies/AllowedVmSizesInLab'
New-AzureRmRoleAssignment -ObjectId $user.ObjectId -RoleDefinitionName "Policy Contributor" -Scope $scope