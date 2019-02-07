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
    $reportItem | Add-Member NoteProperty "UpdatePropertiesJobId" $null
    $reportItem | Add-Member NoteProperty "ProtectableStatus" $null
    $reportItem | Add-Member NoteProperty "ProtectionState" $null
    $reportItem | Add-Member NoteProperty "ProtectionStateDescription" $null
    
    $vaultName = $csvItem.VAULT_NAME
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    $sourceConfigurationServer = $csvItem.CONFIGURATION_SERVER
    $targetAvailabilitySet = $csvItem.AVAILABILITY_SET
    $targetPrivateIP = $csvItem.PRIVATE_IP
    $targetSubnet = $csvItem.TARGET_SUBNET
    $targetMachineSize = $csvItem.MACHINE_SIZE
    $targetPostFailoverResourceGroup = $csvItem.TARGET_RESOURCE_GROUP

    $vaultServer = $asrCommon.GetAndEnsureVaultContext($vaultName)
    $fabricServer = $asrCommon.GetFabricServer($sourceConfigurationServer)
    $protectionContainer = $asrCommon.GetProtectionContainer($fabricServer)
    $protectableVM = $asrCommon.GetProtectableItem($protectionContainer, $sourceMachineName)

    $processor.Logger.LogTrace("ProtectableStatus: '$($protectableVM.ProtectionStatus)'")
    $reportItem.ProtectableStatus = $protectableVM.ProtectionStatus

    if ($protectableVM.ReplicationProtectedItemId -ne $null) {
        $protectedItem = $asrCommon.GetProtectedItem($protectionContainer, $sourceMachineName)

        $reportItem.ProtectionState = $protectedItem.ProtectionState
        $reportItem.ProtectionStateDescription = $protectedItem.ProtectionStateDescription
        $processor.Logger.LogTrace("ProtectionState: '$($protectedItem.ProtectionState)'")
        $processor.Logger.LogTrace("ProtectionDescription: '$($protectedItem.ProtectionStateDescription)'")

        if ($protectedItem.ProtectionState -eq 'Protected') {
            $processor.Logger.LogTrace("Creating job to set machine properties...")
            $nicDetails = $protectedItem.NicDetailsList[0]
            if (($targetAvailabilitySet -eq '') -or ($targetAvailabilitySet -eq $null)) {
                $updatePropertiesJob = Set-AzureRmRecoveryServicesAsrReplicationProtectedItem `
                    -InputObject $protectedItem `
                    -PrimaryNic $nicDetails.NicId `
                    -RecoveryNicStaticIPAddress $targetPrivateIP `
                    -RecoveryNetworkId $nicdetails.RecoveryVMNetworkId `
                    -RecoveryNicSubnetName $targetSubnet `
                    -UseManagedDisk $False `
                    -Size $targetMachineSize
            } else {
                $targetAvailabilitySetObj = Get-AzureRmAvailabilitySet `
                    -ResourceGroupName $targetPostFailoverResourceGroup `
                    -Name $targetAvailabilitySet
    
                $updatePropertiesJob = Set-AzureRmRecoveryServicesAsrReplicationProtectedItem `
                    -InputObject $protectedItem `
                    -PrimaryNic $nicDetails.NicId `
                    -RecoveryNicStaticIPAddress $targetPrivateIP `
                    -RecoveryNetworkId $nicdetails.RecoveryVMNetworkId `
                    -RecoveryNicSubnetName $targetSubnet `
                    -UseManagedDisk $False `
                    -RecoveryAvailabilitySet $targetAvailabilitySetObj.Id `
                    -Size $targetMachineSize
            }
    
            if ($updatePropertiesJob -eq $null)
            {
                $processor.Logger.LogErrorAndThrow("Error creating update properties job for '$($sourceMachineName)'")
            }
            $reportItem.UpdatePropertiesJobId = $updatePropertiesJob.Name
        } else {
            $processor.Logger.LogTrace("Item '$($sourceMachineName)' it is not in a Protected status")
        }
    } else {
        $processor.Logger.LogTrace("'$($sourceMachineName)' item is not in a protected state ready for replication")
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
