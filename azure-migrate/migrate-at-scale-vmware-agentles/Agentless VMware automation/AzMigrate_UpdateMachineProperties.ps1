Param(
    [parameter(Mandatory=$true)]
    $CsvFilePath
)

$ErrorActionPreference = "Stop"

$scriptsPath = $PSScriptRoot
if ($PSScriptRoot -eq "") {
    $scriptsPath = "."
}

. "$scriptsPath\AzMigrate_Logger.ps1"
. "$scriptsPath\AzMigrate_Shared.ps1"
. "$scriptsPath\AzMigrate_CSV_Processor.ps1"

Function ProcessItemImpl($processor, $csvItem, $reportItem) {

    $reportItem | Add-Member NoteProperty "AdditionalInformation" $null
    
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    if ([string]::IsNullOrEmpty($sourceMachineName)) {
        $processor.Logger.LogError("SOURCE_MACHINE_NAME is not mentioned in the csv file")
        $reportItem.AdditionalInformation = "SOURCE_MACHINE_NAME is not mentioned in the csv file" 
        return
    }
    $azMigrateRG = $csvItem.AZMIGRATEPROJECT_RESOURCE_GROUP_NAME
    if ([string]::IsNullOrEmpty($azMigrateRG)) {
        $processor.Logger.LogTrace("AZMIGRATEPROJECT_RESOURCE_GROUP_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "AZMIGRATEPROJECT_RESOURCE_GROUP_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }
    $azMigrateProjName = $csvItem.AZMIGRATEPROJECT_NAME
    if ([string]::IsNullOrEmpty($azMigrateProjName)) {
        $processor.Logger.LogTrace("AZMIGRATEPROJECT_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "AZMIGRATEPROJECT_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }
    $azMigrateApplianceName = $csvItem.AZMIGRATE_APPLIANCE_NAME
    if ([string]::IsNullOrEmpty($AzMigrateApplianceName)) {
        $processor.Logger.LogTrace("AZMIGRATE_APPLIANCE_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "AZMIGRATE_APPLIANCE_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }

    #lets validate if we can/should Update properties at all for this machine
    $ReplicatingServermachine = $AzMigrateShared.GetReplicationServer($azMigrateRG, $azMigrateProjName, $sourceMachineName, $azMigrateApplianceName)
    if((-not $ReplicatingServermachine) -or ($csvItem.OK_TO_UPDATE -ne 'Y') `
        -or (($ReplicatingServermachine.MigrationState -ne "Replicating") -and ($ReplicatingServermachine.MigrationStateDescription -ne "Ready to migrate")))
    {
        $processor.Logger.LogError("We cannot Update replication as either is it not configured in csv file OR the state of this machine replication is not suitable for running updates now: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "We cannot Update replication as either is it not configured in csv file OR the state of this machine replication is not suitable for running updates now: '$($sourceMachineName)'. Please Run AzMigrate_UpdateReplicationStatus.ps1 and look at the output csv file which may provide more details"
        $processor.Logger.LogTrace("Current Migration State of machine: '$($ReplicatingServermachine.MigrationState)'")
        $processor.Logger.LogTrace("Current Migration State Description of machine: '$($ReplicatingServermachine.MigrationStateDescription)'")
        return
    }

    # parameters to pass to New-AzMigrateServerReplication
    $params = @{}
    $params.Add("InputObject", $ReplicatingServermachine)

    $sqlServerLicenseType = $csvItem.SQL_SERVER_LICENSE_TYPE
    if ([string]::IsNullOrEmpty($sqlServerLicenseType) -or ($sqlServerLicenseType -eq "NoLicenseType")) {
        $processor.Logger.LogTrace("SQL_SERVER_LICENSE_TYPE is not mentioned for: '$($sourceMachineName)', or it is set to 'NoLicenseType'")
        $params.Add("SqlServerLicenseType", "NoLicenseType")
    }
    else {
        $allowedLicenseTypes = @("PAYG", "AHUB")
        if (-not $allowedLicenseTypes.Contains($sqlServerLicenseType)) {
            $processor.Logger.LogError("SQL_SERVER_LICENSE_TYPE is not valid for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "SQL_SERVER_LICENSE_TYPE is not valid for: '$($sourceMachineName)'"
            return
        }
        $params.Add("SqlServerLicenseType", $sqlServerLicenseType)
    }

    $testVnetName = $csvItem.UPDATED_TEST_VNET_NAME
    if ([string]::IsNullOrEmpty($testVnetName)) {
        $processor.Logger.LogTrace("UPDATED_TEST_VNET_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $Test_VNet = Get-AzVirtualNetwork -Name $testVnetName
        if (-not $Test_VNet) {
            $processor.Logger.LogError("Updated VNET could not be retrieved for: '$($testVnetName)'")
            $reportItem.AdditionalInformation = "Updated VNET could not be retrieved for: '$($testVnetName)'"
            return
        }
        else {
            $params.Add("TestNetworkId", $Test_VNet.Id)
        }    
    }
    
    #Code added to accommodate for Target Subscription if the replicated machine is suppose to land in a different Target subscription
    $targetSubscriptionID = $csvItem.TARGET_SUBSCRIPTION_ID
    if ([string]::IsNullOrEmpty($targetSubscriptionID)) {
        $processor.Logger.LogTrace("TARGET_SUBSCRIPTION_ID is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "TARGET_SUBSCRIPTION_ID is not mentioned for: '$($sourceMachineName)'"         
    }
    else {
        Set-AzContext -SubscriptionId $targetSubscriptionID
    }    
    #End Code for Target Subscription

    #Get the Target ResourceGroup where we want to provision the VM in Azure
    $targetResourceGroup = $csvItem.UPDATED_TARGET_RESOURCE_GROUP_NAME
    if ([string]::IsNullOrEmpty($targetResourceGroup)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_RESOURCE_GROUP_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $Target_RG = Get-AzResourceGroup -name $targetResourceGroup
        if (-not $Target_RG) {
            $processor.Logger.LogError("Updated ResourceGroup could not be retrieved for: '$($targetResourceGroup)'")
            $reportItem.AdditionalInformation = "Updated ResourceGroup could not be retrieved for: '$($targetResourceGroup)'"
            return
        }    
        else {
            $params.Add("TargetResourceGroupID", $Target_RG.ResourceId)
        }
    }

    $updateTagKey = $csvItem.UPDATED_TAG_KEY
    $updateTagValue = $csvItem.UPDATED_TAG_VALUE
    $updateTagOperation = $csvItem.UPDATED_TAG_OPERATION
    $updateTagDict = @{}
    if ([string]::IsNullOrEmpty($updateTagKey) -or [string]::IsNullOrEmpty($updateTagValue) -or [string]::IsNullOrEmpty($updateTagOperation)) {
        $processor.Logger.LogTrace("UPDATED_TAG_KEY or UPDATED_TAG_VALUE or UPDATED_TAG_OPERATION is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $updateTagKeys = $updateTagKey.Split(",")
        $updateTagValues = $updateTagValue.Split(",")
        
        if ($updateTagKeys.Count -ne $updateTagValues.Count) {
            $processor.Logger.LogTrace("UPDATED_TAG_KEY and UPDATED_TAG_VALUE count is not same for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "UPDATED_TAG_KEY and UPDATED_TAG_VALUE count is not same for: '$($sourceMachineName)'"
            return
        }
        else {
            for ($i=0; $i -lt $updateTagKeys.Count; $i++) {
                $updateTagDict.Add($updateTagKeys[$i], $updateTagValues[$i])
            }
            $params.Add("UpdateTag", $updateTagDict)
            $params.Add("UpdateTagOperation", $updateTagOperation)
        }
    }

    $updateVmTagKey = $csvItem.UPDATED_VMTAG_KEY
    $updateVmTagValue = $csvItem.UPDATED_VMTAG_VALUE
    $updateVmTagOperation = $csvItem.UPDATED_VMTAG_OPERATION
    $updateVmTagDict = @{}
    if ([string]::IsNullOrEmpty($updateVmTagKey) -or [string]::IsNullOrEmpty($updateVmTagValue) -or [string]::IsNullOrEmpty($updateVmTagOperation)) {
        $processor.Logger.LogTrace("UPDATED_VM_TAG_KEY or UPDATED_VM_TAG_VALUE or UPDATED_VMTAG_OPERATION is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $updateVmTagKeys = $updateVmTagKey.Split(",")
        $updateVmTagValues = $updateVmTagValue.Split(",")
        
        if ($updateVmTagKeys.Count -ne $updateVmTagValues.Count) {
            $processor.Logger.LogTrace("UPDATED_VM_TAG_KEY and UPDATED_VM_TAG_VALUE count is not same for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "UPDATED_VM_TAG_KEY and UPDATED_VM_TAG_VALUE count is not same for: '$($sourceMachineName)'"
            return
        }
        else {
            for ($i=0; $i -lt $updateVmTagKeys.Count; $i++) {
                $updateVmTagDict.Add($updateVmTagKeys[$i], $updateVmTagValues[$i])
            }
            $params.Add("UpdateVmTag", $updateVmTagDict)
            $params.Add("UpdateVmTagOperation", $updateVmTagOperation)
        }
    }

    $updateDiskTagKey = $csvItem.UPDATED_DISKTAG_KEY
    $updateDiskTagValue = $csvItem.UPDATED_DISKTAG_VALUE
    $updateDiskTagOperation = $csvItem.UPDATED_DISKTAG_OPERATION
    $updateDiskTagDict = @{}
    if ([string]::IsNullOrEmpty($updateDiskTagKey) -or [string]::IsNullOrEmpty($updateDiskTagValue) -or [string]::IsNullOrEmpty($updateDiskTagOperation)) {
        $processor.Logger.LogTrace("UPDATED_DISKTAG_KEY or UPDATED_DISKTAG_VALUE or UPDATED_DISKTAG_OPERATION is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $updateDiskTagKeys = $updateDiskTagKey.Split(",")
        $updateDiskTagValues = $updateDiskTagValue.Split(",")
        
        if ($updateDiskTagKeys.Count -ne $updateDiskTagValues.Count) {
            $processor.Logger.LogTrace("UPDATED_DISKTAG_KEY and UPDATED_DISKTAG_VALUE count is not same for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "UPDATED_DISKTAG_KEY and UPDATED_DISKTAG_VALUE count is not same for: '$($sourceMachineName)'"
            return
        }
        else {
            for ($i=0; $i -lt $updateDiskTagKeys.Count; $i++) {
                $updateDiskTagDict.Add($updateDiskTagKeys[$i], $updateDiskTagValues[$i])
            }
            $params.Add("UpdateDiskTag", $updateDiskTagDict)
            $params.Add("UpdateDiskTagOperation", $updateDiskTagOperation)
        }
    }

    $updateNicTagKey = $csvItem.UPDATED_NICTAG_KEY
    $updateNicTagValue = $csvItem.UPDATED_NICTAG_VALUE
    $updateNicTagOperation = $csvItem.UPDATED_NICTAG_OPERATION
    $updateNicTagDict = @{}
    if ([string]::IsNullOrEmpty($updateNicTagKey) -or [string]::IsNullOrEmpty($updateNicTagValue) -or [string]::IsNullOrEmpty($updateNicTagOperation)) {
        $processor.Logger.LogTrace("UPDATED_NICTAG_KEY or UPDATED_NICTAG_VALUE or UPDATED_NICTAG_OPERATION is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $updateNicTagKeys = $updateNicTagKey.Split(",")
        $updateNicTagValues = $updateNicTagValue.Split(",")
        
        if ($updateNicTagKeys.Count -ne $updateNicTagValues.Count) {
            $processor.Logger.LogTrace("UPDATED_NICTAG_KEY and UPDATED_NICTAG_VALUE count is not same for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "UPDATED_NICTAG_KEY and UPDATED_NICTAG_VALUE count is not same for: '$($sourceMachineName)'"
            return
        }
        else {
            for ($i=0; $i -lt $updateNicTagKeys.Count; $i++) {
                $updateNicTagDict.Add($updateNicTagKeys[$i], $updateNicTagValues[$i])
            }
            $params.Add("UpdateNicTag", $updateNicTagDict)
            $params.Add("UpdateNicTagOperation", $updateNicTagOperation)
        }
    }
    

    #Get the Target VirtualNetwork Name where we want to provision the VM in Azure
    $targetVnetName = $csvItem.UPDATED_TARGET_VNET_NAME
    if ([string]::IsNullOrEmpty($targetVnetName)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_VNET_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $Target_VNet = Get-AzVirtualNetwork -Name $targetVnetName
        if (-not $Target_VNet) {
            $processor.Logger.LogError("Updated VNET could not be retrieved for: '$($targetVnetName)'")
            $reportItem.AdditionalInformation = "Updated VNET could not be retrieved for: '$($targetVnetName)'"
            return
        }
        else {
            $params.Add("TargetNetworkId", $Target_VNet.Id)
        }    
    }
    
    #Code added to accommodate for Target Subscription if the replicated machine is suppose to land in a different Target subscription
    #We are reverting to Azure Migrate Subscription
    if (-not([string]::IsNullOrEmpty($targetSubscriptionID))) {
        $azMigProjSubscriptionID = $csvItem.AZMIGRATEPROJECT_SUBSCRIPTION_ID
        if ([string]::IsNullOrEmpty($azMigProjSubscriptionID)){
            $processor.Logger.LogTrace("AZMIGRATEPROJECT_SUBSCRIPTION_ID is not mentioned for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "AZMIGRATEPROJECT_SUBSCRIPTION_ID is not mentioned for: '$($sourceMachineName)'"
            return
        }
        else {
            Set-AzContext -SubscriptionId $azMigProjSubscriptionID
        }        
    } 
    #End Code for Target Subscription

    $targetDiskName = $csvItem.UPDATED_TARGET_DISK_NAME
    if ([string]::IsNullOrEmpty($targetDiskName)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_DISK_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $params.Add("TargetDiskName", $targetDiskName)
    }

    $diskMapping = @()
    $paramsDisk1 = @{}
    $osDiskId = $csvItem.OS_DISK_ID
    $osDiskName = $csvItem.UPDATED_TARGET_OS_DISK_NAME

    if ([string]::IsNullOrEmpty($osDiskId)) {
        $processor.Logger.LogTrace("OS_DISK_ID is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "OS_DISK_ID is not mentioned for: '$($sourceMachineName)'"
    }
    else {
        $paramsDisk1.Add("DiskId", $osDiskId)
        $paramsDisk1.Add("IsOSDisk", $true)
        if ([string]::IsNullOrEmpty($osDiskName)) {
            $processor.Logger.LogTrace("UPDATED_TARGET_OS_DISK_NAME is not mentioned for: '$($sourceMachineName)'")
        }
        else {
            $paramsDisk1.Add("TargetDiskName", $osDiskName)
        }
        $diskMapping+= $paramsDisk1
    }

    $paramsDisk2 = @{}
    $dataDisk1Id = $csvItem.DATA_DISK1_ID
    $dataDisk1Name = $csvItem.UPDATED_TARGET_DATA_DISK1_NAME
    if ([string]::IsNullOrEmpty($dataDisk1Id)) {
        $processor.Logger.LogTrace("DATA_DISK1_ID is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "DATA_DISK1_ID is not mentioned for: '$($sourceMachineName)'"
    }
    else {
        $paramsDisk2.Add("DiskId", $dataDisk1Id)
        $paramsDisk2.Add("IsOSDisk", $false)
        if ([string]::IsNullOrEmpty($dataDisk1Name)) {
            $processor.Logger.LogTrace("UPDATED_TARGET_DATA_DISK1_NAME is not mentioned for: '$($sourceMachineName)'")
        }
        else {
            $paramsDisk2.Add("TargetDiskName", $dataDisk1Name)
        }
        $diskMapping+= $paramsDisk2
    }

    $paramsDisk3 = @{}
    $dataDisk2Id = $csvItem.DATA_DISK2_ID
    $dataDisk2Name = $csvItem.UPDATED_TARGET_DATA_DISK2_NAME
    if ([string]::IsNullOrEmpty($dataDisk2Id)) {
        $processor.Logger.LogTrace("DATA_DISK2_ID is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "DATA_DISK2_ID is not mentioned for: '$($sourceMachineName)'"
    }
    else {
        $paramsDisk3.Add("DiskId", $dataDisk2Id)
        $paramsDisk3.Add("IsOSDisk", $false)
        if ([string]::IsNullOrEmpty($dataDisk2Name)) {
            $processor.Logger.LogTrace("UPDATED_TARGET_DATA_DISK2_NAME is not mentioned for: '$($sourceMachineName)'")
        }else {
            $paramsDisk3.Add("TargetDiskName", $dataDisk2Name)
        }
        $diskMapping+= $paramsDisk3
    }

    if ($diskMapping.Count -gt 0) {
        $params.Add("DiskToUpdate", $diskMapping)
    }

    $targetMachineName = $csvItem.UPDATED_TARGET_MACHINE_NAME 
    if ([string]::IsNullOrEmpty($targetMachineName)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_MACHINE_NAME is not mentioned for: '$($sourceMachineName)'")        
    }
    else {
        $params.Add("TargetVMName", $targetMachineName)
    }

    $targetMachineSize = $csvItem.UPDATED_TARGET_MACHINE_SIZE
    if ([string]::IsNullOrEmpty($targetMachineSize)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_MACHINE_SIZE is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $params.Add("TargetVMSize", $targetMachineSize)
    }
    
    #Only one can be specified i.e, UPDATED_AVAILABILITYZONE_NUMBER or UPDATED_AVAILABILITYSET_NAME
    $availabilityZoneNbr = $csvItem.UPDATED_AVAILABILITYZONE_NUMBER
    if ([string]::IsNullOrEmpty($availabilityZoneNbr)) {
        $processor.Logger.LogTrace("UPDATED_AVAILABILITYZONE_NUMBER is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $params.Add("TargetAvailabilityZone", $availabilityZoneNbr)
    }
    $availabilitysetName = $csvItem.UPDATED_AVAILABILITYSET_NAME
    if ([string]::IsNullOrEmpty($availabilitysetName)) {
        $processor.Logger.LogTrace("UPDATED_AVAILABILITYSET_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        #lets check if $availabilityZoneNbr is also specified, if yes then both i.e, AVAILABILITYSET_NAME and AVAILABILITYZONE_NUMBER cannot be specified together so we will return and log this. if one is preferred over the other we can change this
        if (-not([string]::IsNullOrEmpty($availabilityZoneNbr))) {
            $processor.Logger.LogError("Both Availability Zone and Availability Set are mentioned. We can select any one for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "Both Availability Zone and Availability Set are mentioned. We can select any one for: '$($sourceMachineName)'"
            return
        }
        else {
            $avSet = Get-AzAvailabilitySet -Name $availabilitysetName -ResourceGroupName $targetResourceGroup
            if (-not $avSet){
                $processor.Logger.LogError("AvailabilitySet could not be retrieved for: '$($sourceMachineName)'")
                $reportItem.AdditionalInformation = "AvailabilitySet could not be retrieved for: '$($sourceMachineName)'"
                return
            }
            else {
                $params.Add("TargetAvailabilitySet", $avSet.Id)
            }
        }
    }

    #region NICMapping
    # NIC parameters to pass to New-AzMigrateServerReplication
    $NicMapping = @()
    $paramsNIC1 = @{}    
    $UpdatedNIC1ID = $csvItem.UPDATED_NIC1_ID
    if ([string]::IsNullOrEmpty($UpdatedNIC1ID)) {
        $processor.Logger.LogTrace("UPDATED_NIC1_ID is not mentioned for: '$($sourceMachineName)'")
        if ([string]::IsNullOrEmpty($ReplicatingServermachine.ProviderSpecificDetail.VMNic[0].NicId))
        {
            $processor.Logger.LogTrace("We didn't find NicId at the first VMNic in replicating server for: '$($sourceMachineName)'")
        }
        else {
            $processor.Logger.LogTrace("We found NicId at the first VMNic in replicating server, so we are going to use this for: '$($sourceMachineName)'")
            $paramsNIC1.Add("NicId", $ReplicatingServermachine.ProviderSpecificDetail.VMNic[0].NicId)
        }
    }
    else {
        $paramsNIC1.Add("NicId", $UpdatedNIC1ID)
    }

    $nic1Name = $csvItem.UPDATED_TARGET_NIC1_NAME
    if ([string]::IsNullOrEmpty($nic1Name)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_NIC1_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $paramsNIC1.Add("TargetNicName", $nic1Name)
    }

    $NIC1_SelectionType = $csvItem.UPDATED_TARGET_NIC1_SELECTIONTYPE
    #Specifies whether the NIC to be updated will be the Primary, Secondary or not migrated ("DoNotCreate")
    if ([string]::IsNullOrEmpty($NIC1_SelectionType)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_NIC1_SELECTIONTYPE is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $AllowedNic1Type = @("Primary","Secondary","DoNotCreate")
        if ($AllowedNic1Type.Contains($NIC1_SelectionType)){
            $paramsNIC1.Add("TargetNicSelectionType", $NIC1_SelectionType)    
        }
        else {
            $processor.Logger.LogTrace("UPDATED_TARGET_NIC1_SELECTIONTYPE is mentioned but it doesnt contain one of the following Primary, Secondary or DoNotCreate for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "UPDATED_TARGET_NIC1_SELECTIONTYPE is mentioned but it doesnt contain one of the following Primary, Secondary or DoNotCreate for: '$($sourceMachineName)'"
            return
        }
    }    

    $NIC1_TEST_SUBNET_NAME = $csvItem.UPDATED_TARGET_NIC1_TEST_SUBNET_NAME
    if ([string]::IsNullOrEmpty($NIC1_TEST_SUBNET_NAME)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_NIC1_TEST_SUBNET_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $paramsNIC1.Add("TestNicSubnet", $NIC1_TEST_SUBNET_NAME)
    }

    $NIC1_Subnet = $csvItem.UPDATED_TARGET_NIC1_SUBNET_NAME
    if ([string]::IsNullOrEmpty($NIC1_Subnet)) {$processor.Logger.LogTrace("UPDATED_TARGET_NIC1_SUBNET_NAME is not mentioned for: '$($sourceMachineName)'")}
    else {
        $paramsNIC1.Add("TargetNicSubnet", $NIC1_Subnet)
    }
    $NIC1_NICIP = $csvItem.UPDATED_TARGET_NIC1_IP
    if ([string]::IsNullOrEmpty($NIC1_NICIP)) {$processor.Logger.LogTrace("UPDATED_TARGET_NIC1_IP is not mentioned for: '$($sourceMachineName)'")}
    else {
        $paramsNIC1.Add("TargetNicIP", $NIC1_NICIP)
    }
    $NIC1_TEST_IP = $csvItem.UPDATED_TARGET_NIC1_TEST_IP
    if ([string]::IsNullOrEmpty($NIC1_TEST_IP)) {$processor.Logger.LogTrace("UPDATED_TARGET_NIC1_TEST_STATIC_IP is not mentioned for: '$($sourceMachineName)'")}
    else {
        $paramsNIC1.Add("TestNicIP", $NIC1_TEST_IP)
    }

    # NIC parameters to pass to New-AzMigrateServerReplication
    $paramsNIC2 = @{}    
    $UpdatedNIC2ID = $csvItem.UPDATED_NIC2_ID
    if ([string]::IsNullOrEmpty($UpdatedNIC2ID)) {
        $processor.Logger.LogTrace("UPDATED_NIC2_ID is not mentioned for: '$($sourceMachineName)'")
        if ([string]::IsNullOrEmpty($ReplicatingServermachine.ProviderSpecificDetail.VMNic[1].NicId))
        {
            $processor.Logger.LogTrace("We didn't find NicId at the second VMNic in replicating server for: '$($sourceMachineName)'")
        }
        else {
            $processor.Logger.LogTrace("We found NicId at the second VMNic in replicating server, so we are going to use this for: '$($sourceMachineName)'")
            $paramsNIC2.Add("NicId", $ReplicatingServermachine.ProviderSpecificDetail.VMNic[1].NicId)
        }
    }
    else {
        $paramsNIC2.Add("NicId", $UpdatedNIC2ID)
    }

    $nic2Name = $csvItem.UPDATED_TARGET_NIC2_NAME
    if ([string]::IsNullOrEmpty($nic2Name)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_NIC2_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $paramsNIC2.Add("TargetNicName", $nic2Name)
    }

    $NIC2_SelectionType = $csvItem.UPDATED_TARGET_NIC2_SELECTIONTYPE
    #Specifies whether the NIC to be updated will be the Primary, Secondary or not migrated ("DoNotCreate")
    if ([string]::IsNullOrEmpty($NIC2_SelectionType)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_NIC2_SELECTIONTYPE is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $AllowedNic2Type = @("Primary","Secondary","DoNotCreate")
        if ($AllowedNic2Type.Contains($NIC2_SelectionType)){
            $paramsNIC2.Add("TargetNicSelectionType", $NIC2_SelectionType)    
        }
        else {
            $processor.Logger.LogTrace("UPDATED_TARGET_NIC2_SELECTIONTYPE is mentioned but it doesnt contain one of the following Primary, Secondary or DoNotCreate for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "UPDATED_TARGET_NIC2_SELECTIONTYPE is mentioned but it doesnt contain one of the following Primary, Secondary or DoNotCreate for: '$($sourceMachineName)'"
            return
        }
    }

    $NIC2_TEST_SUBNET_NAME = $csvItem.UPDATED_TARGET_NIC2_TEST_SUBNET_NAME
    if ([string]::IsNullOrEmpty($NIC2_TEST_SUBNET_NAME)) {
        $processor.Logger.LogTrace("UPDATED_TARGET_NIC2_TEST_SUBNET_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $paramsNIC2.Add("TestNicSubnet", $NIC2_TEST_SUBNET_NAME)
    }

    $NIC2_Subnet = $csvItem.UPDATED_TARGET_NIC2_SUBNET_NAME
    if ([string]::IsNullOrEmpty($NIC2_Subnet)) {$processor.Logger.LogTrace("UPDATED_TARGET_NIC2_SUBNET_NAME is not mentioned for: '$($sourceMachineName)'")}
    else {
        $paramsNIC2.Add("TargetNicSubnet", $NIC2_Subnet)
    }
    $NIC2_NICIP = $csvItem.UPDATED_TARGET_NIC2_IP
    if ([string]::IsNullOrEmpty($NIC2_NICIP)) {$processor.Logger.LogTrace("UPDATED_TARGET_NIC2_IP is not mentioned for: '$($sourceMachineName)'")}
    else {
        $paramsNIC2.Add("TargetNicIP", $NIC2_NICIP)
    }
    $NIC2_TEST_NIC_IP = $csvItem.UPDATED_TARGET_NIC2_TEST_IP
    if ([string]::IsNullOrEmpty($NIC2_TEST_STATIC_IP)) {$processor.Logger.LogTrace("UPDATED_TARGET_NIC2_TEST_STATIC_IP is not mentioned for: '$($sourceMachineName)'")}
    else {
        $paramsNIC1.Add("TestNicIP", $NIC2_TEST_NIC_IP)
    }

    #Assumption is that if $UpdatedNIC1ID is not provided then probably it doesnt need to be added
    # we can also add the below code when we check this for the first time but it will be in a nested fashion so doing it here for simplicity 
    if (-not ([string]::IsNullOrEmpty($UpdatedNIC1ID) -and [string]::IsNullOrEmpty($ReplicatingServermachine.ProviderSpecificDetail.VMNic[0].NicId))) {
        $Nic1Mapping = New-AzMigrateNicMapping @paramsNIC1
        if(-not $Nic1Mapping){
            $processor.Logger.LogTrace("Nic1Mapping is not initialized for: '$($sourceMachineName)'")
        }
        else {      
            $NicMapping += $Nic1Mapping        
        }
    }
    #Assumption is that if $UpdatedNIC2ID is not provided then probably it doesnt need to be added
    # we can also add the below code when we check this for the first time but it will be in a nested fashion so doing it here for simplicity 
    if (-not ([string]::IsNullOrEmpty($UpdatedNIC2ID) -and [string]::IsNullOrEmpty($ReplicatingServermachine.ProviderSpecificDetail.VMNic[1].NicId))) {
        $Nic2Mapping = New-AzMigrateNicMapping @paramsNIC2
        if(-not $Nic2Mapping){
            $processor.Logger.LogTrace("Nic2Mapping is not initialized for: '$($sourceMachineName)'")
        }
        else {
            $NicMapping += $Nic2Mapping
        }
    }

    if ($NicMapping.Count -gt 0) {
        $params.Add("NicToUpdate", $NicMapping)
    }
    #endregion

    # Start replication for a discovered VM in an Azure Migrate project 
    $processor.Logger.LogTrace( "Starting Update Job for source '$($sourceMachineName)'")
    $UpdateJob = Set-AzMigrateServerReplication @params

    if (-not $UpdateJob){
        $processor.Logger.LogError("Update Job couldn't be initiated for the specified machine: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "Update Job couldn't be initiated for the specified machine: '$($sourceMachineName)'"
    }
    else {
        $processor.Logger.LogTrace("Update Job is initiated for the specified machine: '$($sourceMachineName)'")    
    }
}

Function ProcessItem($processor, $csvItem, $reportItem) {
    try {
        ProcessItemImpl $processor $csvItem $reportItem
    }
    catch {
        $exceptionMessage = $_ | Out-String
        $reportItem.Exception = $exceptionMessage
        $processor.Logger.LogErrorAndThrow($exceptionMessage)
    }
}

$logger = New-AzMigrate_LoggerInstance -CommandPath $PSCommandPath
$AzMigrateShared = New-AzMigrate_SharedInstance -Logger $logger
$processor = New-CsvProcessorInstance -logger $logger -processItemFunction $function:ProcessItem
$processor.ProcessFile($CsvFilePath)
