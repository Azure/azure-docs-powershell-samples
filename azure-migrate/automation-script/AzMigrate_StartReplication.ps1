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
    
    # parameters to pass to New-AzMigrateServerReplication
    $params = @{}

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

    #lets validate if we can/should initiate replication at all for this machine. Ptobably it never started replication and hence wont have any data under replicationserver
    if(($csvItem.OK_TO_MIGRATE -ne 'Y'))
    {
        $processor.Logger.LogError("We cannot initiate replication as it is not configured in csv file: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "We cannot initiate replication as it is not configured in csv file: '$($sourceMachineName)'" 
        return
    }

    $targetResourceGroup = $csvItem.TARGET_RESOURCE_GROUP_NAME
    if ([string]::IsNullOrEmpty($targetResourceGroup)) {
        $processor.Logger.LogTrace("TARGET_RESOURCE_GROUP_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "TARGET_RESOURCE_GROUP_NAME is not mentioned for: '$($sourceMachineName)'" 
        return
    }
    else {
        #Get the Target ResourceGroup where we want to provision the VM in Azure
        $Target_RG = Get-AzResourceGroup -name $targetResourceGroup
        if (-not $Target_RG) {
            $processor.Logger.LogError("Target ResourceGroup could not be retrieved for: '$($targetResourceGroup)'")
            $reportItem.AdditionalInformation = "Target ResourceGroup could not be retrieved for: '$($targetResourceGroup)'"
            return
        }
        else {
            $params.Add("TargetResourceGroupId", $Target_RG.ResourceId)
        }
    }

    $targetVnetName = $csvItem.TARGET_VNET_NAME
    if ([string]::IsNullOrEmpty($targetVnetName)) {
        $processor.Logger.LogTrace("TARGET_VNET_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "TARGET_VNET_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }
    else {
        #Get the Target VirtualNetwork Name where we want to provision the VM in Azure
        $Target_VNet = Get-AzVirtualNetwork -Name $targetVnetName
        if (-not $Target_VNet) {
            $processor.Logger.LogError("VNET could not be retrieved for: '$($targetVnetName)'")
            $reportItem.AdditionalInformation = "VNET could not be retrieved for: '$($targetVnetName)'"
            return
        }
        else {
            $params.Add("TargetNetworkId", $Target_VNet.Id)    
        }
    }

    $targetSubnetName = $csvItem.TARGET_SUBNET_NAME
    if ([string]::IsNullOrEmpty($targetSubnetName)) {
        #using default for subnet if not specified
        $processor.Logger.LogTrace("TARGET_SUBNET_NAME is not mentioned for: '$($sourceMachineName)'")
        $params.Add("TargetSubnetName", "default")
    }
    else {
        $params.Add("TargetSubnetName", $targetSubnetName)
    }

    #Get the Discovery Data for this machine
    $DiscoveredServer = $AzMigrateShared.GetDiscoveredServer($azMigrateRG, $azMigrateProjName, $sourceMachineName)
    $params.Add("InputObject", $DiscoveredServer)

    $azMigrateAssessmentName = $null
    $azMigrateGroupName = $null
    $AssessmentDetails = $null

    
    if (($csvItem.OK_TO_USE_ASSESSMENT -ne 'Y')) {
        $processor.Logger.LogTrace("OK_TO_USE_ASSESSMENT is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $azMigrateAssessmentName = $csvItem.AZMIGRATEASSESSMENT_NAME
        if ([string]::IsNullOrEmpty($azMigrateAssessmentName)) {
            $processor.Logger.LogTrace("AZMIGRATEASSESSMENT_NAME is not mentioned for: '$($sourceMachineName)'")
        }
        $azMigrateGroupName = $csvItem.AZMIGRATEGROUP_NAME
        if ([string]::IsNullOrEmpty($azMigrateGroupName)) {
            $processor.Logger.LogTrace("AZMIGRATEGROUP_NAME is not mentioned for: '$($sourceMachineName)'")
        }

        if (-not (([string]::IsNullOrEmpty($azMigrateAssessmentName)) -or ([string]::IsNullOrEmpty($azMigrateGroupName))))
        {
            #Lets get Azure Migrate project
            $MigPrj = Get-AzMigrateProject -Name $azMigrateProjName -ResourceGroupName $azMigrateRG
            if (-not $MigPrj) {
                $processor.Logger.LogTrace("For AssessmentDetails we need Projecy ID but we could not rerieve Azure Migrate Project for: '$($azMigrateProjName)'")
            }

            #Get Assessment Data for this machine
            $AssessmentDetails = $AzMigrateShared.GetAzMigAssessmentDetails($MigPrj.Id, $azMigrateGroupName, $azMigrateAssessmentName, $DiscoveredServer.Id)
            if (-not $AssessmentDetails) {
                $processor.Logger.LogTrace("Could not rerieve Assessment details for: '$($sourceMachineName)-$($azMigrateAssessmentName)-$($azMigrateGroupName)'")
            }
        }
    }

    $targetMachineName = $csvItem.TARGET_MACHINE_NAME 
    if ([string]::IsNullOrEmpty($targetMachineName)) {
        #we will default to source machine if this is not provided
        $processor.Logger.LogTrace("TARGET_MACHINE_NAME is not mentioned for so defaulting to source machine name: '$($sourceMachineName)'")
        $params.Add("TargetVMName", $sourceMachineName)
    }
    else {
        $params.Add("TargetVMName", $targetMachineName)
    }

    $targetMachineSize = $csvItem.TARGET_MACHINE_SIZE
    if ([string]::IsNullOrEmpty($targetMachineSize)) {
        $processor.Logger.LogTrace("TARGET_MACHINE_SIZE is not mentioned for: '$($sourceMachineName)'")
        if($AssessmentDetails)
        {
            #we have assessment done for this VM, so we will take the details from there
            $params.Add("TargetVMSize", $AssessmentDetails.properties.recommendedSize)
        }
    }
    else {
        $params.Add("TargetVMSize", $targetMachineSize)
    }

    $LicenseTypecsv = $csvItem.LICENSE_TYPE
    if ([string]::IsNullOrEmpty($LicenseTypecsv) -or ($LicenseTypecsv -eq "NoLicenseType")) {
        #defaulting to NoLicenseType
        $processor.Logger.LogTrace("LICENSE_TYPE is configued as NoLicenseType or not mentioned and hence defaulting to NoLicenseType for: '$($sourceMachineName)'")
        $params.Add("LicenseType", "NoLicenseType")
    }
    else {
        $params.Add("LicenseType", "WindowsServer")
    }

    #Availability Zone or Availability Set
    $availabilityZoneNbr = $csvItem.AVAILABILITYZONE_NUMBER
    if ([string]::IsNullOrEmpty($availabilityZoneNbr)) {
        $processor.Logger.LogTrace("AVAILABILITYZONE_NUMBER is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        $params.Add("TargetAvailabilityZone", $availabilityZoneNbr)
    }
    $availabilitysetName = $csvItem.AVAILABILITYSET_NAME
    if ([string]::IsNullOrEmpty($availabilitysetName)) {
        $processor.Logger.LogTrace("AVAILABILITYSET_NAME is not mentioned for: '$($sourceMachineName)'")
    }
    else {
        #lets check if $availabilityZoneNbr is also specified, if yes then both i.e, AVAILABILITYSET_NAME and AVAILABILITYZONE_NUMBER cannot be specified together so we will return and log this. if one is preferred over the other we can change this
        if (-not([string]::IsNullOrEmpty($availabilityZoneNbr))) {
            $processor.Logger.LogError("Both Availability Zone and Availability Set are mentioned. We can select any one for: '$($sourceMachineName)'""Both Availability Zone and Availability Set are mentioned. We can select any one for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "Both Availability Zone and Availability Set are mentioned. We can select any one for: '$($sourceMachineName)'"
            return
        }
        else {
            #Get the availability set
            $avSet = Get-AzAvailabilitySet -Name $availabilitysetName -ResourceGroupName $targetResourceGroup
            if (-not $avSet){
                $processor.Logger.LogTrace("AVAILABILITY Set could not be retrieved for: '$($sourceMachineName)'")
                $reportItem.AdditionalInformation = "AVAILABILITY Set could not be retrieved for: '$($sourceMachineName)'"
                return
            }
            else {
                $params.Add("TargetAvailabilitySet", $avSet.Id)
            }
        }
    }


    
    $disk_assessment_recommendations = $null
    if($AssessmentDetails)
    {
        #we have assessment done for this VM, so we will take the details from there
        $disk_assessment_recommendations = $AssessmentDetails.properties.disks
    }

    
    $OSDiskID = $csvItem.OS_DISK_ID
    if ([string]::IsNullOrEmpty($OSDiskID)) {
        $processor.Logger.LogTrace("OS_DISK_ID is not mentioned for: '$($sourceMachineName)'")
    }
    

    [bool] $OSDiskFound = $false
    $DisktoInclude = @()
    foreach($tmpdisk in $DiscoveredServer.Disk)
    {
        $recommended_diskdetails = $null
        if($AssessmentDetails)
        {
            $recommended_diskdetails = $disk_assessment_recommendations | Select-Object -ExpandProperty $tmpdisk.uuid
            if(-not $recommended_diskdetails)
            {
                $processor.Logger.LogError("Disk details in assessment doesnt match with the this specific disk for: '$($sourceMachineName)-$($tmpdisk.uuid)'")
            }
        }

        $Disk = @{}
        if($OSDiskID -eq $tmpdisk.Uuid)
        {
            $OSDiskFound = $true
            $Disk.Add("IsOSDisk", "true")            
        }
        else {
            $Disk.Add("IsOSDisk", "false")
        }
        $Disk.Add("DiskID", $tmpdisk.Uuid)


        $targetDiskType = $null
        if ($recommended_diskdetails) {
            if ($recommended_diskdetails.recommendedDiskType -eq "Standard") {
                $targetDiskType = "Standard_LRS"
            } elseif ($recommended_diskdetails.recommendedDiskType -eq "Premium") {
                $targetDiskType = "Premium_LRS"
            } elseif ($recommended_diskdetails.recommendedDiskType -eq "StandardSSD") {
                $targetDiskType = "StandardSSD_LRS"
            } else {
                $processor.Logger.LogError("Unknown disk type in assessment recommendation for this specific disk for: '$($sourceMachineName)-$($tmpdisk.uuid)'")
            }
        }
        else {
            $targetDiskType = $csvItem.TARGET_DISKTYPE            
        }

        if ([string]::IsNullOrEmpty($targetDiskType)) {
            $processor.Logger.LogTrace("TARGET_DISKTYPE is not mentioned in csv file OR in assessment details, so we are defaulting it to Standard_LRS for: '$($sourceMachineName)'")
            $Disk.Add("DiskType", "Standard_LRS")
        }
        else {
            $AllowedDiskType = @("Premium_LRS","StandardSSD_LRS","Standard_LRS")
            if ($AllowedDiskType.Contains($targetDiskType)){
                $Disk.Add("DiskType", $targetDiskType)    
            }
            else {
                $processor.Logger.LogTrace("TARGET_DISKTYPE is mentioned but it doesnt contain one of the following Premium_LRS, StandardSSD_LRS, Standard_LRS. So we are defaulting it to Standard_LRS for: '$($sourceMachineName)'")
                $Disk.Add("DiskType", "Standard_LRS")
            }        
        }

        $DiskMap = New-AzMigrateDiskMapping @Disk
        if($DiskMap)
        {
            $DisktoInclude += $DiskMap
        }
        else {
            $processor.Logger.LogError("DISK couldn't be added for: '$($sourceMachineName)-$($tmpdisk.Uuid)'")
        }
        
    }

    
    if ($DisktoInclude.Count -gt 0) {
        if (-not $OSDiskFound) {
            #No OSDisk found, so marking the first disk as OSDisk
            $DisktoInclude[0].IsOSDisk = "true"
            $OSDiskFound = $true
        }
        $params.Add("DiskToInclude", $DisktoInclude)
    }
    else {
        $processor.Logger.LogTrace("We were unable to add at least one disk for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "We were unable to add at least one disk for: '$($sourceMachineName)'"
        return
    }      
    
    # Start replication for a discovered VM in an Azure Migrate project 
    $processor.Logger.LogTrace( "Starting replication Job for source '$($sourceMachineName)'")
    $MigrateJob =  New-AzMigrateServerReplication @params

    if (-not $MigrateJob){
        $processor.Logger.LogError("Replication Job couldn't be initiated for the specified machine: '$($sourceMachineName)'")  
        $reportItem.AdditionalInformation = "Replication Job couldn't be initiated for the specified machine: '$($sourceMachineName)'. Please Run AzMigrate_UpdateReplicationStatus.ps1 and look at the output csv file which may provide more details)"      
    }
    else {
        $processor.Logger.LogTrace("Replication Job is initiated for the specified machine: '$($sourceMachineName)'")    
        $reportItem.AdditionalInformation = "Replication Job is initiated for the specified machine: '$($sourceMachineName)'"
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
