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
    $reportItem | Add-Member NoteProperty "TestFailoverCleanUpJobId" $null
    $reportItem | Add-Member NoteProperty "TestFailoverState" $null
    $reportItem | Add-Member NoteProperty "TestFailoverStateDescription" $null

    $vaultName = $csvItem.VAULT_NAME
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    $sourceConfigurationServer = $csvItem.CONFIGURATION_SERVER

    $protectedItem = $asrCommon.GetProtectedItemFromVault($vaultName, $sourceMachineName, $sourceConfigurationServer)
    if ($protectedItem -ne $null) {
        if ($protectedItem.AllowedOperations.Contains('TestFailoverCleanup')) {
            #Start the test failover operation
            $testFailoverCleanUpJob = Start-AzRecoveryServicesAsrTestFailoverCleanupJob `
                -ReplicationProtectedItem $protectedItem
            $reportItem.TestFailoverCleanUpJobId = $testFailoverCleanUpJob.ID
        } else {
            $processor.Logger.LogTrace("TestFailoverCleanup operation not allowed for item '$($sourceMachineName)'")
            $reportItem.TestFailoverState = $protectedItem.TestFailoverState
            $reportItem.TestFailoverStateDescription = $protectedItem.TestFailoverStateDescription
        }
    }
}

Function ProcessItem($processor, $csvItem, $reportItem)
{
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

