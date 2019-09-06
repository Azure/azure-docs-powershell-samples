# Edit these global variables with your unique Recovery Services Vault name, resource group name and location
$rsVaultName = "myRsVault"
$rgName = "myResourceGroup"
$location = "East US"

# Register the Recovery Services provider and create a resource group
Register-AzResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"
New-AzResourceGroup -Location $location -Name $rgName

# Create a Recovery Services Vault and set its storage redundancy type
New-AzRecoveryServicesVault `
    -Name $rsVaultName `
    -ResourceGroupName $rgName `
    -Location $location 
$vault1 = Get-AzRecoveryServicesVault â€“Name $rsVaultName
Set-AzRecoveryServicesProperties ` 
    -Vault $vault1 `
    -BackupStorageRedundancy GeoRedundant
    
# Set Recovery Services Vault context and create protection policy
Get-AzRecoveryServicesVault -Name $rsVaultName | Set-AzRecoveryServicesVaultContext 
$schPol = Get-AzRecoveryServicesSchedulePolicyObject -WorkloadType "AzureVM"
$retPol = Get-AzRecoveryServicesRetentionPolicyObject -WorkloadType "AzureVM"
New-AzRecoveryServicesProtectionPolicy `
    -Name "NewPolicy" `
    -WorkloadType "AzureVM" ` 
    -RetentionPolicy $retPol `
    -SchedulePolicy $schPol
    
# Provide permissions to Azure Backup to access key vault and enable backup on the VM
Set-AzKeyVaultAccessPolicy `
    -VaultName "KeyVaultName" `
    -ResourceGroupName "KyeVault-RGName" ` 
    -PermissionsToKeys backup,get,list `
    -PermissionsToSecrets backup,get,list ` 
    -ServicePrincipalName 262044b1-e2ce-469f-a196-69ab7ada62d3
$pol = Get-AzRecoveryServicesProtectionPolicy -Name "NewPolicy" `
Enable-AzRecoveryServicesProtection `
    -Policy $pol `
    -Name "myVM" `
    -ResourceGroupName "VM-RGName" 
    
# Modify protection policy
$retPol = Get-AzRecoveryServicesRetentionPolicyObject -WorkloadType "AzureVM"
$retPol.DailySchedule.DurationCountInDays = 365
$pol = Get-AzRecoveryServicesProtectionPolicy -Name "NewPolicy"
Set-AzRecoveryServicesProtectionPolicy `
    -Policy $pol `
    -RetentionPolicy $RetPol
    
# Trigger a backup and monitor backup job
$namedContainer = Get-AzRecoveryServicesContainer -ContainerType "AzureVM" -Status "Registered" -FriendlyName "myVM"
$item = Get-AzRecoveryServicesItem -Container $namedContainer -WorkloadType "AzureVM"
$job = Backup-AzRecoveryServicesItem -Item $item
$joblist = Get-AzRecoveryServicesJob â€“Status "InProgress"
Wait-AzRecoveryServicesJob `
        -Job $joblist[0] `
        -Timeout 43200
