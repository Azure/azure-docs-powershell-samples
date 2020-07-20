# This Example is for a Dedicated Host

# Input bindings are passed in via param block.
param($Timer)

# Check if any maintenance updates are available for your dedicated host
$isMaintenance = Get-AzMaintenanceUpdate `
    -ResourceGroupName test-scheduler `
    -ResourceName windowscheduler-DHost `
    -ResourceType hosts `
    -ResourceParentName windowScheduler `
    -ResourceParentType hostGroups `
    -ProviderName Microsoft.Compute


# if available, apply the update. Else, write that there are "no availabe updates" to the log
if ($isMaintenance -ne $null)
{
New-AzApplyUpdate `
    -ResourceGroupName test-scheduler `
    -ResourceName windowscheduler-DHost `
    -ResourceType hosts `
    -ResourceParentName windowScheduler `
    -ResourceParentType hostGroups `
    -ProviderName Microsoft.Compute
}
else {
   Write-Output 'No Updates Available'

}
