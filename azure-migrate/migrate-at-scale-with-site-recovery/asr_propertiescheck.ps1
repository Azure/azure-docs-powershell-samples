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

Function CheckParameter($logger, [string]$ParameterName, [string]$ExpectedValue, [string]$ActualValue) {
    $logger.LogTrace("Parameter check '$($ParameterName)'. ExpectedValue: '$($ExpectedValue)', ActualValue: '$($ActualValue)'")
    if ($ExpectedValue -ne $ActualValue) {
        throw "Expected value '$($ExpectedValue)' does not match actual value '$($ActualValue)' for parameter $($ParameterName)"
    } else {
        $logger.LogTrace("Parameter check '$($ParameterName)' DONE")
    }
}

Function ProcessItemImpl($processor, $csvItem, $reportItem) {
    $reportItem | Add-Member NoteProperty "VaultNameCheck" $null
    $reportItem | Add-Member NoteProperty "SourceConfigurationServerCheck" $null
    $reportItem | Add-Member NoteProperty "SourceMachineNameCheck" $null
    $reportItem | Add-Member NoteProperty "TargetPostFailoverResourceGroupCheck" $null
    $reportItem | Add-Member NoteProperty "TargetPostFailoverStorageAccountNameCheck" $null
    $reportItem | Add-Member NoteProperty "TargetPostFailoverVNETCheck" $null
    $reportItem | Add-Member NoteProperty "TargetPostFailoverSubnetCheck" $null
    $reportItem | Add-Member NoteProperty "ReplicationPolicyCheck" $null
    $reportItem | Add-Member NoteProperty "TargetAvailabilitySetCheck" $null
    $reportItem | Add-Member NoteProperty "TargetPrivateIPCheck" $null
    $reportItem | Add-Member NoteProperty "TargetMachineSizeCheck" $null
    $reportItem | Add-Member NoteProperty "TargetMachineNameCheck" $null
    
    $vaultName = $csvItem.VAULT_NAME
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    $sourceConfigurationServer = $csvItem.CONFIGURATION_SERVER
    $targetPostFailoverResourceGroup = $csvItem.TARGET_RESOURCE_GROUP
    $targetPostFailoverStorageAccountName = $csvItem.TARGET_STORAGE_ACCOUNT
    $targetPostFailoverVNET = $csvItem.TARGET_VNET
    $targetPostFailoverSubnet = $csvItem.TARGET_SUBNET
    $replicationPolicy = $csvItem.REPLICATION_POLICY
    $targetAvailabilitySet = $csvItem.AVAILABILITY_SET
    $targetPrivateIP = $csvItem.PRIVATE_IP
    $targetMachineSize = $csvItem.MACHINE_SIZE
    $targetMachineName = $csvItem.TARGET_MACHINE_NAME

    $vaultServer = $asrCommon.GetAndEnsureVaultContext($vaultName)
    $fabricServer = $asrCommon.GetFabricServer($sourceConfigurationServer)
    $reportItem.SourceConfigurationServerCheck = "DONE"

    $protectionContainer = $asrCommon.GetProtectionContainer($fabricServer)
    $protectableVM = $asrCommon.GetProtectableItem($protectionContainer, $sourceMachineName)
    $reportItem.SourceMachineNameCheck = "DONE"

    if ($protectableVM.ReplicationProtectedItemId -ne $null) {
        $protectedItem = $asrCommon.GetProtectedItem($protectionContainer, $sourceMachineName)

        $apiVersion = "2018-01-10"
        #Using 'Get-AzResource -ResourceId $protectedItem.ID -ApiVersion $apiVersion' returns $null after 5.x Az.Resources module version        
        $resourceName = [string]::Concat($vaultServer.Name, "/", $fabricServer.Name, "/", $protectionContainer.Name, "/", $protectedItem.Name)
        $resourceRawData = Get-AzResource `
             -ResourceGroupName $vaultServer.ResourceGroupName `
             -ResourceType  $protectedItem.Type `
             -ResourceName $resourceName `
             -ApiVersion $apiVersion

        #RESOURCE_GROUP
        try {
            #$resourceRawData.Properties.providerSpecificDetails.recoveryAzureResourceGroupId
            $targetResourceGroup = Get-AzResourceGroup -Name $targetPostFailoverResourceGroup
            CheckParameter $processor.Logger 'TARGET_RESOURCE_GROUP' $targetResourceGroup.ResourceId $resourceRawData.Properties.providerSpecificDetails.recoveryAzureResourceGroupId
            $reportItem.TargetPostFailoverResourceGroupCheck = "DONE"
        } catch {
            $reportItem.TargetPostFailoverResourceGroupCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
        }

        #$resourceRawData.Properties.providerSpecificDetails.RecoveryAzureStorageAccount
        try {
            $RecoveryAzureStorageAccountRef = Get-AzResource -ResourceId $resourceRawData.Properties.providerSpecificDetails.RecoveryAzureStorageAccount
            CheckParameter $processor.Logger 'TARGET_STORAGE_ACCOUNT' $targetPostFailoverStorageAccountName $RecoveryAzureStorageAccountRef.Name
            $reportItem.TargetPostFailoverStorageAccountNameCheck = "DONE"
        } catch {
            $reportItem.TargetPostFailoverStorageAccountNameCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
        }

        # #$resourceRawData.Properties.PolicyFriendlyName
        # $reportItem.replicationPolicy = "DONE"
        try {
            CheckParameter $processor.Logger 'REPLICATION_POLICY' $replicationPolicy $resourceRawData.Properties.PolicyFriendlyName
            $reportItem.ReplicationPolicyCheck = "DONE"
        } catch {
            $reportItem.ReplicationPolicyCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
        }

        # #$resourceRawData.Properties.providerSpecificDetails.recoveryAvailabilitySetId
        # $reportItem.targetAvailabilitySet = "DONE"
        try {
            $actualAvailabilitySet = $resourceRawData.Properties.providerSpecificDetails.recoveryAvailabilitySetId
            if ($targetAvailabilitySet -eq '' -and $actualAvailabilitySet -eq '') {
                $reportItem.TargetAvailabilitySetCheck = "DONE"
            } else {
                $targetAvailabilitySetObj = Get-AzAvailabilitySet `
                    -ResourceGroupName $targetPostFailoverResourceGroup `
                    -Name $targetAvailabilitySet
                CheckParameter $processor.Logger 'AVAILABILITY_SET' $targetAvailabilitySetObj.Id $actualAvailabilitySet
                $reportItem.TargetAvailabilitySetCheck = "DONE"
            }
        } catch {
            $reportItem.TargetAvailabilitySetCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
        }
      
        # #$resourceRawData.Properties.providerSpecificDetails.recoveryAzureVMSize
        # $reportItem.targetMachineSize = "DONE"
        try {
            CheckParameter $processor.Logger 'MACHINE_SIZE' $targetMachineSize $resourceRawData.Properties.providerSpecificDetails.recoveryAzureVMSize
            $reportItem.TargetMachineSizeCheck = "DONE"
        } catch {
            $reportItem.TargetMachineSizeCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
        }

        # #$resourceRawData.Properties.providerSpecificDetails.recoveryAzureVMName
        try {
            CheckParameter $processor.Logger 'TARGET_MACHINE_NAME' $targetMachineName $resourceRawData.Properties.providerSpecificDetails.recoveryAzureVMName
            $reportItem.TargetMachineNameCheck = "DONE"
        } catch {
            $reportItem.TargetMachineNameCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
        }

        # #nic
        # #$resourceRawData.Properties.providerSpecificDetails.vmNics[0].replicaNicStaticIPAddress
        # $reportItem.targetPrivateIP = "DONE"
        try {
            CheckParameter $processor.Logger 'PRIVATE_IP' $targetPrivateIP $resourceRawData.Properties.providerSpecificDetails.vmNics[0].replicaNicStaticIPAddress
            $reportItem.TargetPrivateIPCheck = "DONE"
        } catch {
            $reportItem.TargetPrivateIPCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
        }

        # #$resourceRawData.Properties.providerSpecificDetails.vmNics[0].recoveryVMNetworkId
        # $reportItem.targetPostFailoverVNET = "DONE"
        try {
            $VNETRef = Get-AzResource -ResourceId $resourceRawData.Properties.providerSpecificDetails.vmNics[0].recoveryVMNetworkId
            CheckParameter $processor.Logger 'TARGET_VNET' $VNETRef.ResourceId $resourceRawData.Properties.providerSpecificDetails.vmNics[0].recoveryVMNetworkId
            $reportItem.TargetPostFailoverVNETCheck = "DONE"
        } catch {
            $reportItem.TargetPostFailoverVNETCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
        }

        # #$resourceRawData.Properties.providerSpecificDetails.vmNics[0].recoveryVMSubnetName
        # $reportItem.targetPostFailoverSubnet = "DONE"
        try {
            CheckParameter $processor.Logger 'TARGET_SUBNET' $targetPostFailoverSubnet $resourceRawData.Properties.providerSpecificDetails.vmNics[0].recoveryVMSubnetName
            $reportItem.TargetPostFailoverSubnetCheck = "DONE"
        } catch {
            $reportItem.TargetPostFailoverSubnetCheck = "ERROR"
            $exceptionMessage = $_ | Out-String
            $processor.Logger.LogError($exceptionMessage)
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
