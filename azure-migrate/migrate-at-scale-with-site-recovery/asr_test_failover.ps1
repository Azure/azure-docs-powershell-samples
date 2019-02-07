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
    $reportItem | Add-Member NoteProperty "TestFailoverJobId" $null
    $reportItem | Add-Member NoteProperty "TestFailoverState" $null
    $reportItem | Add-Member NoteProperty "TestFailoverStateDescription" $null

    $vaultName = $csvItem.VAULT_NAME
    $sourceAccountName = $csvItem.ACCOUNT_NAME
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    $sourceConfigurationServer = $csvItem.CONFIGURATION_SERVER
    $targetTestFailoverVNET = $csvItem.TESTFAILOVER_VNET
    $targetVNETRG = $csvItem.TARGET_VNET_RG


    $protectedItem = $asrCommon.GetProtectedItemFromVault($vaultName, $sourceMachineName, $sourceConfigurationServer)
    if ($protectedItem -ne $null) {
        if ($protectedItem.AllowedOperations.Contains('TestFailover')) {
            $processor.Logger.LogTrace("Starting TestFailover operation for item '$($sourceMachineName)'")
            #Get details of the test failover virtual network to be used
            $targetTestFailoverVNETObj = Get-AzureRmVirtualNetwork `
                -Name $targetTestFailoverVNET `
                -ResourceGroupName $targetVNETRG 

            #Start the test failover operation
            $testFailoverJob = Start-AzureRmRecoveryServicesAsrTestFailoverJob `
                -ReplicationProtectedItem $protectedItem `
                -AzureVMNetworkId $targetTestFailoverVNETObj.Id `
                -Direction PrimaryToRecovery
            $reportItem.TestFailoverJobId = $testFailoverJob.ID
        } else {
            $processor.Logger.LogTrace("TestFailover operation not allowed for item '$($sourceMachineName)'")
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

