# Retrieve the resource ID for the managed resource group
$managedRgId = (Get-AzureRmManagedApplication -ResourceGroupName DemoApp).Properties.managedResourceGroupId

# Retrieve the built-in Azure policy for allowed locations
$locationPolicyDefinition = Get-AzureRmPolicyDefinition -Id /providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c

# Specify the allowed locations for new Azure resources in the managed resource group
$locationsArray = @("northeurope", "westeurope")
$policyParameters = @{"listOfAllowedLocations"=$locationsArray}

# Assign the policy to the managed resource group
New-AzureRMPolicyAssignment -Name locationAssignment -Scope $managedRgId -PolicyDefinition $locationPolicyDefinition -PolicyParameterObject $policyParameters
