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
        $processor.Logger.LogError("AZMIGRATEPROJECT_RESOURCE_GROUP_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "AZMIGRATEPROJECT_RESOURCE_GROUP_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }
    $azMigrateProjName = $csvItem.AZMIGRATEPROJECT_NAME
    if ([string]::IsNullOrEmpty($azMigrateProjName)) {
        $processor.Logger.LogError("AZMIGRATEPROJECT_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "AZMIGRATEPROJECT_RESOURCE_GROUP_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }
    $azMigrateApplianceName = $csvItem.AZMIGRATE_APPLIANCE_NAME
    if ([string]::IsNullOrEmpty($azMigrateApplianceName)) {
        $processor.Logger.LogError("AZMIGRATE_APPLIANCE_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "AZMIGRATE_APPLIANCE_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }
    #Retreiving the information if we should turn off the source server
    $TurnOff_SrcServer = $csvItem.TURNOFF_SOURCESERVER
    if ([string]::IsNullOrEmpty($TurnOff_SrcServer)) {$processor.Logger.LogTrace("TURNOFF_SOURCESERVER is not mentioned for: '$($sourceMachineName)'")}

    #lets validate if we can/should run TestMigrate at all for this machine
    $ReplicatingServermachine = $AzMigrateShared.GetReplicationServer($azMigrateRG, $azMigrateProjName, $sourceMachineName, $azMigrateApplianceName)
    
    if((-not $ReplicatingServermachine) -or ($csvItem.OK_TO_MIGRATE -ne 'Y') `
        -or (($ReplicatingServermachine.MigrationState -ne "Replicating") -and ($ReplicatingServermachine.MigrationStateDescription -ne "Ready to migrate")) `
        -or (-not $ReplicatingServermachine.AllowedOperation -contains "Migrate")){

        $processor.Logger.LogError("We cannot initiate Migration as either it is not configured in csv file OR OR the state of this machine replication is not suitable for initiating Migration Now: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "We cannot initiate Migration as either it is not configured in csv file OR the state of this machine replication is not suitable for initiating Migration Now: '$($sourceMachineName)'. Please Run AzMigrate_UpdateReplicationStatus.ps1 and look at the output csv file which may provide more details"
        $processor.Logger.LogTrace("Current Migration State of machine: '$($ReplicatingServermachine.MigrationState)'")
        $processor.Logger.LogTrace("Current Migration State Description of machine: '$($ReplicatingServermachine.MigrationStateDescription)'")
        foreach($AO in $ReplicatingServermachine.AllowedOperation)
        {
            $processor.Logger.LogTrace("Allowed Operation: '$($AO)'")
        }
        return
    }

    $osUpgradeVersion = $csvItem.OS_UPGRADE_VERSION

    #start the migration
    if ([string]::IsNullOrEmpty($TurnOff_SrcServer) -or ($TurnOff_SrcServer -eq 'N') -or ($TurnOff_SrcServer -eq 'No')){
        #we are defaulting to this if Turn off Source Server is not mentioned
        if([string]::IsNullOrEmpty($osUpgradeVersion)){
            $processor.Logger.LogTrace("OS_UPGRADE_VERSION is not mentioned for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "OS_VERSION_UPGRADE is not mentioned for: '$($sourceMachineName)'"
            $MigrateJob = Start-AzMigrateServerMigration -InputObject $ReplicatingServermachine
        } else{
            $MigrateJob = Start-AzMigrateServerMigration -InputObject $ReplicatingServermachine -OsUpgradeVersion $osUpgradeVersion
        }
    }
    else {
        if([string]::IsNullOrEmpty($osUpgradeVersion)){
            $processor.Logger.LogTrace("OS_UPGRADE_VERSION is not mentioned for: '$($sourceMachineName)'")
            $reportItem.AdditionalInformation = "OS_VERSION_UPGRADE is not mentioned for: '$($sourceMachineName)'"
            $MigrateJob = Start-AzMigrateServerMigration -InputObject $ReplicatingServermachine -TurnOffSourceServer
        } 
        else {
            $MigrateJob = Start-AzMigrateServerMigration -InputObject $ReplicatingServermachine -TurnOffSourceServer -OsUpgradeVersion $osUpgradeVersion
        }
    }
    
    if (-not $MigrateJob){
        $processor.Logger.LogError("Migration Job couldn't be initiated for the specified machine: '$($sourceMachineName)'")   
        $reportItem.AdditionalInformation = "Migration Job couldn't be initiated for the specified machine: '$($sourceMachineName)'. Please Run AzMigrate_UpdateReplicationStatus.ps1 and look at the output csv file which may provide more details)"                  
    }
    else {
        $processor.Logger.LogTrace("Migration Job is initiated for the specified machine: '$($sourceMachineName)'")    
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
