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
    $reportItem | Add-Member NoteProperty "ProtectableStatus" $null
    $reportItem | Add-Member NoteProperty "ProtectionState" $null
    $reportItem | Add-Member NoteProperty "ProtectionStateDescription" $null
    
    $vaultName = $csvItem.VAULT_NAME
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    $sourceConfigurationServer = $csvItem.CONFIGURATION_SERVER

    $vaultServer = $asrCommon.GetAndEnsureVaultContext($vaultName)
    $fabricServer = $asrCommon.GetFabricServer($sourceConfigurationServer)
    $protectionContainer = $asrCommon.GetProtectionContainer($fabricServer)
    $protectableVM = $asrCommon.GetProtectableItem($protectionContainer, $sourceMachineName)

    $processor.Logger.LogTrace("ProtectableStatus: '$($protectableVM.ProtectionStatus)'")
    $reportItem.ProtectableStatus = $protectableVM.ProtectionStatus

    if ($protectableVM.ReplicationProtectedItemId -ne $null) {
        $protectedItem = $asrCommon.GetProtectedItem($protectionContainer, $sourceMachineName)

        $reportItem.ProtectionState = $protectedItem.ProtectionState
        $reportItem.ProtectionStateDescription = $protectedItem.ProtectionStateDescription
        $processor.Logger.LogTrace("ProtectionState: '$($protectedItem.ProtectionState)'")
        $processor.Logger.LogTrace("ProtectionDescription: '$($protectedItem.ProtectionStateDescription)'")
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
