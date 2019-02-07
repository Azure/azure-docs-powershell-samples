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
    #Add additional fields to the $reportItem object to report execution details
    #It will be included in the out.<script_name>.<csv_name>.<date>.csv reporting file
    $reportItem | Add-Member NoteProperty "AdditionalInfoForReporting" $null
    $processor.Logger.LogTrace("Sample log - $($csvItem.SOURCE_MACHINE_NAME)")
    $reportItem.AdditionalInfoForReporting = "test_info" 
}

Function ProcessItem($processor, $csvItem, $reportItem) {
    try {
        #This method will be invoked for each row in the CSV file
        ProcessItemImpl $processor $csvItem $reportItem
    }
    catch {
        $exceptionMessage = $_ | Out-String
        $processor.Logger.LogError($exceptionMessage)
        throw
    }
}

#logger to report information in file 'out.<script_name>.<date>.txt'
$logger = New-AsrLoggerInstance -CommandPath $PSCommandPath

#common functions to interact with Azure Site Recovery cmdlets
$asrCommon = New-AsrCommonInstance -Logger $logger

#Common implementation to process the CsvFile and invoke the function for each row
$processor = New-CsvProcessorInstance -Logger $logger -ProcessItemFunction $function:ProcessItem
$processor.ProcessFile($CsvFilePath)
