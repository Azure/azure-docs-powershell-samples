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
    $reportItem | Add-Member NoteProperty "TargetMachine" $null
    $reportItem | Add-Member NoteProperty "NsgId" $null

    $targetPostFailoverResourceGroup = $csvItem.TARGET_RESOURCE_GROUP
    $sourceMachineName = $csvItem.SOURCE_MACHINE_NAME
    $targetMachineName = $csvItem.TARGET_MACHINE_NAME
    $targetNsgName = $csvItem.TARGET_NSG_NAME
    $targetNsgResourceGroup = $csvItem.TARGET_NSG_RESOURCE_GROUP

    #Get target VM obj
    $processor.Logger.LogTrace("Getting target VM reference for VM '$($targetMachineName)' in resource group $($targetPostFailoverResourceGroup)")
    $targetVmObj = Get-AzureRmVm `
        -Name $targetMachineName `
        -ResourceGroupName $targetPostFailoverResourceGroup

    $processor.Logger.LogTrace("Getting Network Security Group reference for '$($targetNsgName)' in resource group '$($targetNsgResourceGroup)'")
    $targetNsgObj = Get-AzureRmNetworkSecurityGroup `
        -Name $targetNsgName `
        -ResourceGroupName $targetNsgResourceGroup

    $networkInterfaceId = $targetVmObj.NetworkProfile[0].NetworkInterfaces[0].Id
    $processor.Logger.LogTrace("Getting Raw Resource information for network interface '$($networkInterfaceId)'")
    $networkInterfaceResourceObj = Get-AzureRmResource `
        -ResourceId $networkInterfaceId

    $processor.Logger.LogTrace("Getting Network Interface reference for network interface '$($networkInterfaceResourceObj.Name)' in resource group '$($networkInterfaceResourceObj.ResourceGroupName)'")
    $networkInterfaceObj = Get-AzureRmNetworkInterface `
        -Name $networkInterfaceResourceObj.Name `
        -ResourceGroupName $networkInterfaceResourceObj.ResourceGroupName

    $processor.Logger.LogTrace("Setting Network Security Group to Network Interface '$($networkInterfaceResourceObj.Name)'")
    $networkInterfaceObj.NetworkSecurityGroup = $targetNsgObj
    Set-AzureRmNetworkInterface -NetworkInterface $networkInterfaceObj

    $processor.Logger.LogTrace("Network Security Group set for item '$($sourceMachineName)' in VM '$($targetMachineName)'")
    
    $reportItem.TargetMachine = $targetMachineName
    $reportItem.NsgId = $targetNsgObj.Id
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

