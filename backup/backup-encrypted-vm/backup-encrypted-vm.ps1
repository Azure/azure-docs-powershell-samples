# Edit these global variables with your unique Recovery Services Vault name, resource group name and location
$rsVaultName = "myRsVault"
$rgName = "myResourceGroup"
$location = "East US"

# Register the Recovery Services provider and create a resource group
Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.RecoveryServices"
New-AzureRmResourceGroup -Location $location -Name $rgName

# Create a Recovery Services Vault and set its storage redundancy type
New-AzureRmRecoveryServicesVault `
    -Name $rsVaultName `
    -ResourceGroupName $rgName `
    -Location $location 
$vault1 = Get-AzureRmRecoveryServicesVault –Name $rsVaultName
Set-AzureRmRecoveryServicesBackupProperties ` 
    -Vault $vault1 `
    -BackupStorageRedundancy GeoRedundant
    
# Set Recovery Services Vault context and create protection policy
Get-AzureRmRecoveryServicesVault -Name $rsVaultName | Set-AzureRmRecoveryServicesVaultContext 
$schPol = Get-AzureRmRecoveryServicesBackupSchedulePolicyObject -WorkloadType "AzureVM"
$retPol = Get-AzureRmRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
New-AzureRmRecoveryServicesBackupProtectionPolicy `
    -Name "NewPolicy" `
    -WorkloadType "AzureVM" ` 
    -RetentionPolicy $retPol `
    -SchedulePolicy $schPol
    
# Provide permissions to Azure Backup to access key vault and enable backup on the VM
Set-AzureRmKeyVaultAccessPolicy `
    -VaultName "KeyVaultName" `
    -ResourceGroupName "KyeVault-RGName" ` 
    -PermissionsToKeys backup,get,list `
    -PermissionsToSecrets backup,get,list ` 
    -ServicePrincipalName 262044b1-e2ce-469f-a196-69ab7ada62d3
$pol = Get-AzureRmRecoveryServicesBackupProtectionPolicy -Name "NewPolicy" `
Enable-AzureRmRecoveryServicesBackupProtection `
    -Policy $pol `
    -Name "myVM" `
    -ResourceGroupName "VM-RGName" 
    
# Modify protection policy
$retPol = Get-AzureRmRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"
$retPol.DailySchedule.DurationCountInDays = 365
$pol = Get-AzureRmRecoveryServicesBackupProtectionPolicy -Name "NewPolicy"
Set-AzureRmRecoveryServicesBackupProtectionPolicy `
    -Policy $pol `
    -RetentionPolicy $RetPol
    
# Trigger a backup and monitor backup job
$namedContainer = Get-AzureRmRecoveryServicesBackupContainer -ContainerType "AzureVM" -Status "Registered" -FriendlyName "myVM"
$item = Get-AzureRmRecoveryServicesBackupItem -Container $namedContainer -WorkloadType "AzureVM"
$job = Backup-AzureRmRecoveryServicesBackupItem -Item $item
$joblist = Get-AzureRmRecoveryservicesBackupJob –Status "InProgress"
Wait-AzureRmRecoveryServicesBackupJob `
        -Job $joblist[0] `
        -Timeout 43200
