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
        $processor.Logger.LogErrorAndThrow($exceptionMessage)
        #throw
    }
}

#logger to report information in file 'out.<script_name>.<date>.txt'
$logger = New-AzMigrate_LoggerInstance -CommandPath $PSCommandPath

#Shared functions to interact commonly or frequently used cmdlets
$AzMigrateShared = New-AzMigrate_SharedInstance -Logger $logger

#Common implementation to process the CsvFile and invoke the function for each row.
#passing the logger and ProcessItem function which is stored in the Function: drive.
$processor = New-CsvProcessorInstance -Logger $logger -ProcessItemFunction $function:ProcessItem
$processor.ProcessFile($CsvFilePath)
