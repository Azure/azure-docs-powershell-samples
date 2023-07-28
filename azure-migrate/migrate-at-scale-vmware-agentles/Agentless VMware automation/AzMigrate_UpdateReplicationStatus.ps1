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

    $reportItem | Add-Member NoteProperty "MIGRATION_STATE_FOR_REPLICATION" $null
    $reportItem | Add-Member NoteProperty "MIGRATION_STATE_DESCRIPTION_FOR_REPLICATION" $null
    $reportItem | Add-Member NoteProperty "INITIALREPLICATION_PROGRESS_PERCENTAGE" $null
    $reportItem | Add-Member NoteProperty "TEST_MIGRATE_STATE" $null
    $reportItem | Add-Member NoteProperty "TEST_MIGRATE_STATE_DESCRIPTION" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_SCENARIONAME" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_NAME" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_ID" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_STATE" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_STATE_DESCRIPTION" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_ERROR_CODE" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_ERROR_DESCRIPTION" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_ERROR_POSSIBLECAUSE" $null
    $reportItem | Add-Member NoteProperty "LAST_JOB_ERROR_RECOMMENDEDACTION" $null
    $reportItem | Add-Member NoteProperty "AdditionalInformation" $null

    
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    if ([string]::IsNullOrEmpty($sourceMachineName)) {
        $processor.Logger.LogError("SOURCE_MACHINE_NAME is not mentioned in the csv file")
        $reportItem.AdditionalInformation = "SOURCE_MACHINE_NAME is not mentioned in the csv file" 
        return
    }
    if($csvItem.OK_TO_RETRIEVE_REPLICATIONSTATUS -ne 'Y')
    {
        $processor.Logger.LogTrace("We cannot retrieve replication status as it is not configured in csv file for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "We cannot retrieve replication status as it is not configured in csv file for: '$($sourceMachineName)'"
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
        $reportItem.AdditionalInformation = "AZMIGRATEPROJECT_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }
    $azMigrateApplianceName = $csvItem.AZMIGRATE_APPLIANCE_NAME
    if ([string]::IsNullOrEmpty($azMigrateApplianceName)) {
        $processor.Logger.LogError("AZMIGRATE_APPLIANCE_NAME is not mentioned for: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "AZMIGRATE_APPLIANCE_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }
    
    $ReplicatingServermachine = $AzMigrateShared.GetReplicationServer($azMigrateRG, $azMigrateProjName, $sourceMachineName, $azMigrateApplianceName)
    if (-not $ReplicatingServermachine)
    {
        $this.Logger.LogError("Azure Migrate Replicating Server could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "Azure Migrate Replicating Server could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'"
        return
    }

    #Retrieving various states and replication progress
    $reportItem.MIGRATION_STATE_FOR_REPLICATION = $ReplicatingServermachine.MigrationState
    $reportItem.MIGRATION_STATE_DESCRIPTION_FOR_REPLICATION = $ReplicatingServermachine.MigrationStateDescription
    $reportItem.INITIALREPLICATION_PROGRESS_PERCENTAGE = $ReplicatingServermachine.ProviderSpecificDetail.InitialSeedingProgressPercentage
    $reportItem.TEST_MIGRATE_STATE = $ReplicatingServermachine.TestMigrateState
    $reportItem.TEST_MIGRATE_STATE_DESCRIPTION = $ReplicatingServermachine.TestMigrateStateDescription
    

    $Migratejobs = $null
    #Filter on time for last 2 months of jobs to be retrieved. We can put this as a configuration to be inserted into csv file too for each individual machine as they might have ran a job quite some time back on it.
    $currentDate = Get-Date
    $currentDateUTC = $currentDate.ToUniversalTime()
    $filterTime = "StartTime eq '$($currentDateUTC.AddDays(-60).ToString("yyyy-MM-ddTHH:mm:ssZ"))' and EndTime eq '$($currentDateUTC.ToString("yyyy-MM-ddTHH:mm:ssZ"))'"
    try {
        $Migratejobs = Get-AzMigrateJob -ProjectName $azMigrateProjName -ResourceGroupName $azMigrateRG -Filter $filterTime | Where-Object {($_.TargetObjectName -eq $sourceMachineName)}
    } catch {
        $this.Logger.LogError("Exception while trying to get Migrate jobs")
        $exceptionMessage = $_ | Out-String
        $this.Logger.LogError($exceptionMessage)
        $this.Logger.LogError("Azure Migrate jobs could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "Azure Migrate jobs could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'"
        return
    }
    
    if (-not $Migratejobs)
    {
        $this.Logger.LogError("Azure Migrate jobs could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "Azure Migrate jobs could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'"
        return
    }

    $JobByid = $null
    try {
        #Get the Jobs by ID as it will then have all the error state
        $JobByid = Get-AzMigrateJob -JobID $MigrateJobs[0].Id 
    }
    catch {
        $this.Logger.LogError("Exception while trying to get Migrate jobs by ID")
        $exceptionMessage = $_ | Out-String
        $this.Logger.LogError($exceptionMessage)
        $this.Logger.LogError("Azure Migrate jobs could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "Azure Migrate jobs could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'"
        return
    }
    
    if (-not $JobByid)
    {
        $this.Logger.LogError("Azure Migrate jobs could not be retrieved by JobId for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "Azure Migrate jobs could not be retrieved for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'"
        return
    }

    #get the job information which was last run
    $reportItem.LAST_JOB_NAME = $JobByid.Name
    $reportItem.LAST_JOB_ID = $JobByid.Id        
    $reportItem.LAST_JOB_STATE = $JobByid.State
    $reportItem.LAST_JOB_STATE_DESCRIPTION = $JobByid.StateDescription
    $reportItem.LAST_JOB_SCENARIONAME = $JobByid.ScenarioName

    
    if ($JobByid.State -eq 'Failed') {
        $processor.Logger.LogError("Error in replication job with below details")
        $processor.Logger.LogError("ServiceErrorDetailCode: '$($JobByid.Error.ServiceErrorDetailCode)'")
        $processor.Logger.LogError("ServiceErrorDetailMessage: '$($JobByid.Error.ServiceErrorDetailMessage)'")
        $processor.Logger.LogError("ServiceErrorDetailPossibleCause: '$($JobByid.Error.ServiceErrorDetailPossibleCaus)'")
        $processor.Logger.LogError("ServiceErrorDetailRecommendedAction: '$($JobByid.Error.ServiceErrorDetailRecommendedAction)'")
        $reportItem.LAST_JOB_ERROR_CODE = $JobByid.Error.ServiceErrorDetailCode
        $reportItem.LAST_JOB_ERROR_DESCRIPTION = $JobByid.Error.ServiceErrorDetailMessage
        $reportItem.LAST_JOB_ERROR_POSSIBLECAUSE = $JobByid.Error.ServiceErrorDetailPossibleCaus
        $reportItem.LAST_JOB_ERROR_RECOMMENDEDACTION = $JobByid.Error.ServiceErrorDetailRecommendedAction            
    } else {
        $processor.Logger.LogTrace("ReplicationJob is active for '$($azMigrateRG)-$($azMigrateProjName)-$($sourceMachineName)'")
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
