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


    #lets validate if we can/should Update properties at all for this machine
    $ReplicatingServermachine = $AzMigrateShared.GetReplicationServer($azMigrateRG, $azMigrateProjName, $sourceMachineName)
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
