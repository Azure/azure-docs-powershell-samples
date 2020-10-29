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
        $reportItem.AdditionalInformation = "AZMIGRATEPROJECT_NAME is not mentioned for: '$($sourceMachineName)'"
        return
    }



    #lets validate if we can/should run TestMigrate at all for this machine
    $ReplicatingServermachine = $AzMigrateShared.GetReplicationServer($azMigrateRG, $azMigrateProjName, $sourceMachineName)
    if((-not $ReplicatingServermachine) -or (($csvItem.OK_TO_TESTMIGRATE -ne 'Y')  -and ($csvItem.OK_TO_TESTMIGRATE_CLEANUP -ne 'Y')) `
        -or (($ReplicatingServermachine.TestMigrateState -ne "TestMigrationSucceeded") -and ($ReplicatingServermachine.TestMigrateStateDescription -ne "Test clean up pending")) `
        -or (-not $ReplicatingServermachine.AllowedOperation -contains "TestMigrateCleanup")){

        $processor.Logger.LogError("We cannot initiate Clean up Test Migration as either is it not configured for Test Migration in csv file OR the state of this machine replication is not suitable for running clean up on Test Migration Now: '$($sourceMachineName)'")
        $reportItem.AdditionalInformation = "We cannot initiate Clean up Test Migration as either is it not configured for Test Migration in csv file OR the state of this machine replication is not suitable for running clean up on Test Migration Now: '$($sourceMachineName)'. Please Run AzMigrate_UpdateReplicationStatus.ps1 and look at the output csv file which may provide more details"
        $processor.Logger.LogTrace("Current Test Migration State of machine: '$($ReplicatingServermachine.TestMigrateState)'")
        $processor.Logger.LogTrace("Current Test Migration State Description of machine: '$($ReplicatingServermachine.TestMigrateStateDescription)'")
        foreach($AO in $ReplicatingServermachine.AllowedOperation)
        {
            $processor.Logger.LogTrace("Allowed Operation: '$($AO)'")
        }
        return
    }

    # Clean-up test migration for a replicating server
    $CleanupTestMigrationJob = Start-AzMigrateTestMigrationCleanup -InputObject $ReplicatingServermachine
    if (-not $CleanupTestMigrationJob){
        $processor.Logger.LogError("Clean up for Test Migration Job couldn't be initiated for the specified machine: '$($sourceMachineName)'") 
        $reportItem.AdditionalInformation = "Clean up for Test Migration Job couldn't be initiated for the specified machine: '$($sourceMachineName)'. Please Run AzMigrate_UpdateReplicationStatus.ps1 and look at the output csv file which may provide more details)"             
    }
    else {
        $processor.Logger.LogTrace("Clean up for Test Migration Job is initiated for the specified machine: '$($sourceMachineName)'")    
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
