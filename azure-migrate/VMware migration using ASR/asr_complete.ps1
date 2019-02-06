Param(
    [parameter(Mandatory=$true)]
    $CsvFilePath,
    $TimeOutInCommitJobInSeconds = 120
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
    $reportItem | Add-Member NoteProperty "CommitJobId" $null
    $reportItem | Add-Member NoteProperty "DisableReplicationJobId" $null

    $vaultName = $csvItem.VAULT_NAME
    $sourceConfigurationServer = $csvItem.CONFIGURATION_SERVER
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME

    $protectedItem = $asrCommon.GetProtectedItemFromVault($vaultName, $sourceMachineName, $sourceConfigurationServer)
    if ($protectedItem -ne $null) {
        if ($protectedItem.AllowedOperations.Contains('Commit')) {
            #Start the failover operation
            $processor.Logger.LogTrace("Starting Commit operation for item '$($sourceMachineName)'")
            $commitFailoverJob = Start-AzureRmRecoveryServicesAsrCommitFailoverJob `
                -ReplicationProtectedItem $protectedItem
            $initialStartDate = Get-Date
            while (($commitFailoverJob.State -ne 'Succeeded') -and ($diffInMilliseconds -le $TimeOutInCommitJobInSeconds)) {
                Write-Host "." -NoNewline 
                $commitFailoverJob = Get-AzureRmRecoveryServicesAsrJob -Name $commitFailoverJob.Name
                $currentDate = Get-Date

                $diff = $currentDate - $initialStartDate
                $diffInMilliseconds = $diff.TotalSeconds
            }
            $reportItem.CommitJobId = $commitFailoverJob.ID
            if ($commitFailoverJob.State -ne 'Succeeded') {
                $processor.Logger.LogErrorAndThrow("Commit job did not reach 'Succeeded' status in a timely manner, DisableProtection will not be executed for '$($sourceMachineName)' ")
            }
        } else {
            $processor.Logger.LogTrace("Commit operation not allowed for item '$($sourceMachineName)'")
        }
        if ($protectedItem.AllowedOperations.Contains('DisableProtection')) {
            #Start the failover operation
            $processor.Logger.LogTrace("Starting DisableProtection operation for item '$($sourceMachineName)'")
            $disableReplicationJob = Remove-AzureRmRecoveryServicesAsrReplicationProtectedItem `
                -InputObject $protectedItem

            $reportItem.DisableReplicationJobId = $disableReplicationJob.ID
        } else {
            $processor.Logger.LogTrace("DisableProtection operation not allowed for item '$($sourceMachineName)'")
        }
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
