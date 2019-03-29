Param(
    [parameter(Mandatory=$true)]
    $CsvFilePath
)

$ErrorActionPreference = "Stop"

$scriptsPath = $PSScriptRoot
if ($PSScriptRoot -eq "") {
    $scriptsPath = "."
}

. "$scriptsPath\asr_logger.ps1"
. "$scriptsPath\asr_common.ps1"
. "$scriptsPath\asr_csv_processor.ps1"

Function ProcessItemImpl($processor, $csvItem, $reportItem) {
    $reportItem | Add-Member NoteProperty "ProtectableStatus" $null
    $reportItem | Add-Member NoteProperty "ProtectionState" $null
    $reportItem | Add-Member NoteProperty "ProtectionStateDescription" $null
    $reportItem | Add-Member NoteProperty "ReplicationJobId" $null
    
    $vaultName = $csvItem.VAULT_NAME
    $sourceAccountName = $csvItem.ACCOUNT_NAME
    $sourceProcessServer = $csvItem.PROCESS_SERVER
    $sourceConfigurationServer = $csvItem.CONFIGURATION_SERVER
    $targetPostFailoverResourceGroup = $csvItem.TARGET_RESOURCE_GROUP
    $targetPostFailoverStorageAccountName = $csvItem.TARGET_STORAGE_ACCOUNT
    $targetPostFailoverLogStorageAccountName = $csvItem.TARGET_LOGSTORAGE_ACCOUNT 
    $targetPostFailoverVNET = $csvItem.TARGET_VNET
    $targetPostFailoverSubnet = $csvItem.TARGET_SUBNET
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    $replicationPolicy = $csvItem.REPLICATION_POLICY
    $targetMachineName = $csvItem.TARGET_MACHINE_NAME
    $targetStorageAccountRG = $csvItem.TARGET_STORAGE_ACCOUNT_RG
    $targetLogStorageAccountRG = $csvItem.TARGET_LOGSTORAGE_ACCOUNT_RG
    $targetVNETRG = $csvItem.TARGET_VNET_RG

    $vaultServer = $asrCommon.GetAndEnsureVaultContext($vaultName)
    $fabricServer = $asrCommon.GetFabricServer($sourceConfigurationServer)
    $protectionContainer = $asrCommon.GetProtectionContainer($fabricServer)
    $protectableVM = $asrCommon.GetProtectableItem($protectionContainer, $sourceMachineName)

    $processor.Logger.LogTrace("ProtectableStatus: '$($protectableVM.ProtectionStatus)'")
    $reportItem.ProtectableStatus = $protectableVM.ProtectionStatus

    if ($protectableVM.ReplicationProtectedItemId -eq $null) {
        $processor.Logger.LogTrace("Starting protection for item '$($sourceMachineName)'")
        #Assumption storage are already created
        $targetPostFailoverStorageAccount = Get-AzStorageAccount `
            -Name $targetPostFailoverStorageAccountName `
            -ResourceGroupName $targetStorageAccountRG

        $targetPostFailoverLogStorageAccount = Get-AzStorageAccount `
            -Name $targetPostFailoverLogStorageAccountName `
            -ResourceGroupName $targetLogStorageAccountRG

        $targetResourceGroupObj = Get-AzResourceGroup -Name $targetPostFailoverResourceGroup
        $targetVnetObj = Get-AzVirtualNetwork `
            -Name $targetPostFailoverVNET `
            -ResourceGroupName $targetVNETRG 
        $targetPolicyMap  =  Get-AzRecoveryServicesAsrProtectionContainerMapping `
            -ProtectionContainer $protectionContainer | Where-Object { $_.PolicyFriendlyName -eq $replicationPolicy }
        if ($targetPolicyMap -eq $null) {
            $processor.Logger.LogErrorAndThrow("Policy map '$($replicationPolicy)' was not found")
        }

        $sourceProcessServerObj = $fabricServer.FabricSpecificDetails.ProcessServers | Where-Object { $_.FriendlyName -eq $sourceProcessServer }
        if ($sourceProcessServerObj -eq $null) {
            $processor.Logger.LogErrorAndThrow("Process server with name '$($sourceProcessServer)' was not found")
        }
        $sourceAccountObj = $fabricServer.FabricSpecificDetails.RunAsAccounts | Where-Object { $_.AccountName -eq $sourceAccountName }
        if ($sourceAccountObj -eq $null) {
            $processor.Logger.LogErrorAndThrow("Account name '$($sourceAccountName)' was not found")
        }

        $processor.Logger.LogTrace( "Starting replication Job for source '$($sourceMachineName)'")
        $replicationJob = New-AzRecoveryServicesAsrReplicationProtectedItem `
            -VMwareToAzure `
            -ProtectableItem $protectableVM `
            -Name (New-Guid).Guid `
            -ProtectionContainerMapping $targetPolicyMap `
            -RecoveryAzureStorageAccountId $targetPostFailoverStorageAccount.Id `
	    -LogStorageAccountId $targetPostFailoverLogStorageAccount.Id `
            -ProcessServer $sourceProcessServerObj `
            -Account $sourceAccountObj `
            -RecoveryResourceGroupId $targetResourceGroupObj.ResourceId `
            -RecoveryAzureNetworkId $targetVnetObj.Id `
            -RecoveryAzureSubnetName $targetPostFailoverSubnet `
            -RecoveryVmName $targetMachineName

        $replicationJobObj = Get-AzRecoveryServicesAsrJob -Name $replicationJob.Name
        while ($replicationJobObj.State -eq 'NotStarted') {
            Write-Host "." -NoNewline 
            $replicationJobObj = Get-AzRecoveryServicesAsrJob -Name $replicationJob.Name
        }
        $reportItem.ReplicationJobId = $replicationJob.Name

        if ($replicationJobObj.State -eq 'Failed') {
            LogError "Error starting replication job"
            foreach ($replicationJobError in $replicationJobObj.Errors) {
                LogError $replicationJobError.ServiceErrorDetails.Message
                LogError $replicationJobError.ServiceErrorDetails.PossibleCauses
            }
        } else {
            $processor.Logger.LogTrace("ReplicationJob initiated")      
        }
    } else {
        $protectedItem = Get-AzRecoveryServicesAsrReplicationProtectedItem `
            -ProtectionContainer $protectionContainer `
            -FriendlyName $sourceMachineName
        $reportItem.ProtectionState = $protectedItem.ProtectionState
        $reportItem.ProtectionStateDescription = $protectedItem.ProtectionStateDescription

        $processor.Logger.LogTrace("ProtectionState: '$($protectedItem.ProtectionState)'")
        $processor.Logger.LogTrace("ProtectionDescription: '$($protectedItem.ProtectionStateDescription)'")
    }
}

Function ProcessItem($processor, $csvItem, $reportItem) {
    try {
        ProcessItemImpl $processor $csvItem $reportItem
    }
    catch {
        $exceptionMessage = $_ | Out-String
        $processor.Logger.LogError($exceptionMessage)
        throw
    }
}

$logger = New-AsrLoggerInstance -CommandPath $PSCommandPath
$asrCommon = New-AsrCommonInstance -Logger $logger
$processor = New-CsvProcessorInstance -Logger $logger -ProcessItemFunction $function:ProcessItem
$processor.ProcessFile($CsvFilePath)
