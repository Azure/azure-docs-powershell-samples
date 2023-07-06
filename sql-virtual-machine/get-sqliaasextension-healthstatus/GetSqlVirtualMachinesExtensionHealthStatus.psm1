#Requires -Module Az.Compute
#Requires -Module Az.Accounts
#Requires -Module Az.SqlVirtualMachine
#Requires -Module Az.Resources
#Requires -Module Microsoft.PowerShell.Security

<#
    .SYNOPSIS
    Get Extension Health status of SQL VMs

    .DESCRIPTION
    Get status of IaaS Extension of all Azure SQL VMs from list of subscriptions or unique subscription. 
    A summary is displayed at the end of the script run.
    The Output summary contains the number of SQL VMs that have Extension in Healthy status, skipped due to old extension version, unhealhty or were failed to get status because of various reasons.
    Reasons may include extension provisioning failed on the VM, status of the VM not available at the time of the script.
    Errored VMs may also correspond to authorization issues, SQL Server not running on the VM, VM not running or Guest Agent on the VM not running.

    Prerequisites:
    - Run 'Connect-AzAccount' to first connect the powershell session to the azure account.
    - If your tenant has MFA enabled, you will have to re-login per subscription, TenantId may also be required.
    - Strongly adviced to have SQL Server running on the machine.
    - The Client credentials must have one of the following RBAC levels of access over the virtual machine being registered: Virtual Machine Contributor,
      Contributor or Owner
    - The script requires Az powershell module (>=2.8.0) to be installed. Details on how to install Az module can be found 
      here : https://docs.microsoft.com/powershell/azure/install-az-ps
      It specifically requires Az.Compute, Az.Accounts and Az.Resources module which comes as part of Az module (>=2.8.0) installation.
    - The script also requires Az.SqlVirtualMachine module. Details on how to install Az.SqlVirtualMachine can be
      found here: https://www.powershellgallery.com/packages/Az.SqlVirtualMachine

    .PARAMETER SubscriptionList
    List of Subscriptions whose SQL VMs need to get Extension Health status
    
    .PARAMETER TenantId
    Tenant id where the subscriptions are hosted
    
    .EXAMPLE
    #To get Extension status of all SQL VMs in a single subscription
    Get-SqlVMsExtensionHealthStatus -SubscriptionList SubscriptionId1
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Summary
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Total VMs Found: 70
    Number of SQL VMs having Extension Service Status as Healthy: 56
    Number of SQL VMs having Extension Service Status as UnHealthy: 4
    Number of VMs having older extension version (extension health check not supported) : 3
    Number of VMs failed to get extension health status due to error : 7
    
    Please find the detailed report in file SqlVirtualMachinesExtensionHealthReport1681511288.txt
    Please find the error details in file SqlVMsFailedToGetExtensionHealthDueToError1681511288.log
    -----------------------------------------------------------------------------------------------------------------------------------------------

    .NOTES
    https://www.powershellgallery.com/packages/Az.SqlVirtualMachine
#>
function Get-SqlVMsExtensionHealthStatus {
    [CmdletBinding(DefaultParameterSetName = 'SubscriptionList')]
    Param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'SubscriptionList')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $SubscriptionList,
        [string]
        $TenantId
    )

    #get credential for connecting to subscription
    $credential = Get-Credential -Credential $null

    Update-Globals

    $subsCompleted = 0
    #loop over all subscriptions to check Extension Service Health Status of Sql VMs
    foreach ($SubscriptionId in $SubscriptionList) {
        [int]$percent = ($subsCompleted * 100) / $SubscriptionList.Count
        Write-Progress -Activity "Get Extension Service Health Status of SQL VMs in $($SubscriptionId) $($subsCompleted+1)/$($SubscriptionList.Count)" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "Get Extension Service Health Status of SQL VMs in Subscription" -Id 1;

        $isSubValid = $false
        if ($TenantId){
            $isSubValid = Assert-SubscriptionMFA -Subscription $SubscriptionId -TenantId $TenantId
        }else{
            $isSubValid = Assert-Subscription -Subscription $SubscriptionId -Credential $credential
        }

        if ($isSubValid) {
            Get-SqlVMHealthStatusForSubscription -Subscription $SubscriptionId -Credential $credential
        }
        $subsCompleted++
    }
    Write-Progress -Activity "Get Extension Service Health Status" -Status "100% Complete:" -PercentComplete 100 -CurrentOperation "Get Extension Service Health Status of SQL VMs in Subscription" -Id 1 -Completed;

    #Report 
    new-Report
}

<#
    .SYNOPSIS
    Get Extension Health Status of SQL VMs in a given subscription

    .PARAMETER Subscription
    Subscription for searching the VM

    .PARAMETER Credential
    Credential to connect to subscription
#>
function Get-SqlVMHealthStatusForSubscription (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Subscription,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $Credential) {
    [System.Collections.ArrayList]$vmList = Get-SqlVmList
    #Total vm count
    $Global:TotalVMs += $vmList.Count

    if ($vmList -ne $null -and $vmList.Count -gt 0) {
      Get-SqlVmExtensionStatusFromList -VMList $vmList
    }
}

<#
    .SYNOPSIS
    Get list of SQL VMs in a subscription

    .OUTPUTS
    System.Collections.ArrayList list of VMs
#>
function Get-SqlVmList() {
    $vmList = [System.Collections.ArrayList]@()

    $vmsInSub = Get-AzSqlVM
    # We will get all VMs that are Windows
    if ($PSVersionTable.PSVersion.Major -eq 7)
    {

    foreach ($vm in $vmsInSub) {
    $vmObject = $vm | ConvertFrom-Json    
    $sqlImageOffer = $vmObject.properties.sqlImageOffer
    $sqlImageSku = $vmObject.properties.sqlImageSku
        if (($sqlImageSku -ne 'Unknown') -and ($sqlImageOffer -like '*WS*')) {
            $tmp = $vmList.Add($vm)
        }
    }
    }
    elseif ($PSVersionTable.PSVersion.Major -eq 5)
    {
        foreach ($vm in $vmsInSub) {
           if (($vm.Sku -ne 'Unknown') -and ($vm.Offer -like '*WS*')) {
            $tmp = $vmList.Add($vm)
           }
        }
    }

    return , $vmList
}

<#
    .SYNOPSIS
    Given a list of SQL VMs, Get Extension Health Status of SQL VMs

    .PARAMETER VMList
    List of SQL VMs for which Extension Health Status need to be fetched

    .PARAMETER RetryIfRequired
    Flag to specify if operation needs to be retried
#>
function Get-SqlVmExtensionStatusFromList(
    [ValidateNotNullOrEmpty()]
    [array]
    $VMList,
    [bool]
    $RetryIfRequired = $false) {

    [Int32]$numberOfVMs = $VMList.Count
    $completed = 0
    Write-Progress -Activity "Get Extension Service Health Status" -Status "0% Complete:" -PercentComplete 0 -CurrentOperation "Fetching Extension Service Health Status of SQL VMs" -Id 2

    # for each vm in the list try to get extension service health status
    foreach ($vm in $VMList) {
        # write progress of the loop
        [int]$percent = ($completed * 100) / $numberOfVMs
        Write-Progress -Activity "Get Extension Service Health Status $($completed+1)/$($VMList.count)" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "Fetching Extension Service Health Status of SQL VMs" -Id 2

        $name = $vm.Name
        $resourceGroupName = $vm.ResourceGroupName

        # Check the Extension Health Status
        $Global:Error.Clear()
        $result = Get-ExtensionHealthStatusOfSingleVM -VmName $name -ResourceGroup $resourceGroupName

        switch ($result) {
        'Healthy' {
            $tmp = $Global:HealthyVMs.Add($vm)
        }
        'UnHealthy' {
            $tmp = $Global:UnHealthyVMs.Add($vm)
        }
        'Failed to retrieve health status' {
            $tmp = $Global:FailedVMs.Add($vm)
        }
        'Not supported Extension version' {
            $tmp = $Global:NotSupportedVMs.Add($vm)
        }
		'Lightweight VM' {
            $tmp = $Global:LightweightVMs.Add($vm)
        }
        Default {
            $tmp = $Global:FailedVMs.Add($vm)
        }
        }

        $completed++

    }
    Write-Progress -Activity "Get Extension Service Health Status" -Completed -CurrentOperation "Fetching Extension Service Health Status of SQL VMs" -Id 2    
}

<#
    .SYNOPSIS
    Successfully connect to subscription

    .PARAMETER Subscription
    Subscription for searching the VM

    .PARAMETER Credential
    Credential to connect to subscription

    .OUTPUTS
    System.Boolean true if successfully connected, else false
#>
function Assert-Subscription(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Subscription,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $Credential
) {
    #Connect to the subscription
    $Global:Error.clear()
    $tmp = Connect-AzAccount -Subscription $Subscription -Credential $Credential -ErrorAction SilentlyContinue
    if ($Global:Error) {
        $connectionError = $Global:Error[0]
        $errorMessage = "$($Subscription), $($connectionError[0].Exception.Message)"
        Write-Output $errorMessage | Out-File $Global:LogFile -Append

        # Check if MFA is required, then ask again for login again
        if ($connectionError[0].Exception.DesensitizedErrorMessage -eq "MFA is required to access tenant"){
            return Assert-SubscriptionMFA -Subscription $Subscription
        }

        $tmp = $Global:SubscriptionsFailedToConnect.Add($Subscription)
        return $false 
    }
    return $true
}

<#
    .SYNOPSIS
    Successfully connect to subscription with MultiFactor Authentication

    .PARAMETER Subscription
    Subscription for searching the SQL VM

    .PARAMETER Credential
    TenantId to connect to subscription

    .OUTPUTS
    System.Boolean true if successfully connected and RP is registered, else false
#>
function Assert-SubscriptionMFA(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Subscription,
    [Parameter(Mandatory = $false)]
    [string]
    $TenantId
) {
    #Connect to the subscription
    $Global:Error.clear()

    if ($TenantId){
        $tmp = Connect-AzAccount -Subscription $Subscription -Tenant $TenantId -ErrorAction SilentlyContinue
    } else {
        $tmp = Connect-AzAccount -Subscription $Subscription -ErrorAction SilentlyContinue
    }

    if ($Global:Error) {
        $connectionError = $Global:Error[0]
        $errorMessage = "$($Subscription), $($connectionError[0].Exception.Message)"
        Write-Output $errorMessage | Out-File $Global:LogFile -Append
        $tmp = $Global:SubscriptionsFailedToConnect.Add($Subscription)
        return $false  
    }
    return $true
}

#Globals for reporting and logging
$Global:TotalVMs = 0
$Global:SubscriptionsFailedToConnect = [System.Collections.ArrayList]@()
$Global:HealthyVMs = [System.Collections.ArrayList]@()
$Global:UnHealthyVMs = [System.Collections.ArrayList]@()
$Global:NotSupportedVMs = [System.Collections.ArrayList]@()
$Global:LightweightVMs = [System.Collections.ArrayList]@()
$Global:FailedVMs = [System.Collections.ArrayList]@()
$Global:LogFile = $null
$Global:ReportFile = $null

<#
    .SYNOPSIS
    Reset Global Variables
#>
function Update-Globals() {
    [int]$timestamp = Get-Date (Get-Date)  -UFormat %s
    $Global:TotalVMs = 0
    $Global:SubscriptionsFailedToConnect = [System.Collections.ArrayList]@()
    $Global:HealthyVMs = [System.Collections.ArrayList]@()
    $Global:UnHealthyVMs = [System.Collections.ArrayList]@()
    $Global:NotSupportedVMs = [System.Collections.ArrayList]@()
	$Global:LightweightVMs = [System.Collections.ArrayList]@()
    $Global:FailedVMs = [System.Collections.ArrayList]@()
    $Global:LogFile = "SqlVMsFailedToGetExtensionHealthDueToError" + $timestamp + ".log"
    $Global:ReportFile = "SqlVirtualMachinesExtensionHealthReport" + $timestamp + ".txt"
    Remove-Item $Global:LogFile -ErrorAction Ignore
    Remove-Item $Global:ReportFile -ErrorAction Ignore
    $txtLogHeader = "Subscription,[Resource Group],[VM Name],[ErrorCode],Error Message"
    Write-Output $txtLogHeader | Out-File $Global:LogFile -Append
}

<#
    .SYNOPSIS
    Creates a new line dashed separator
#>
function new-DashSeperator() {
    Write-Host
    Write-Host "-----------------------------------------------------------------------------------------------------------------------------------------------"
}

<#
    .SYNOPSIS
    Generates the report
#>
function new-Report() {
    new-DashSeperator
    Write-Host "Summary"
    new-DashSeperator

    if ($Global:SubscriptionsFailedToConnect.count -gt 0) {
        $errorMessage = "Number of Subscriptions reporting failed for because you do not have access or credentials are incorrect: $($Global:SubscriptionsFailedToConnect.count)"
        show-SubscriptionListForError -ErrorMessage $errorMessage -FailedSubList $Global:SubscriptionsFailedToConnect
    }


    $txtTotalVMsFound = "Total VMs Found: $($Global:TotalVMs)" 
    Write-Output $txtTotalVMsFound | Out-File $Global:ReportFile -Append
    Write-Output $txtTotalVMsFound


    #display healthy VMs
    $txtHealthy = "Number of SQL VMs having Extension Service Status as Healthy: $($Global:HealthyVMs.Count)"
    show-VMDetailsInReport -Message $txtHealthy -VMList $Global:HealthyVMs

    #display unhealthy VMs
    if ($Global:UnHealthyVMs.Count -gt 0) {
        $txtUnHealthy = "Number of SQL VMs having Extension Service Status as UnHealthy: $($Global:UnHealthyVMs.Count)"
        show-VMDetailsInReport -Message $txtUnHealthy -VMList $Global:UnHealthyVMs
    }

    #display VMs for which Extension is older version
    if ($Global:NotSupportedVMs.Count -gt 0) {
        $txtNotSupported = "Number of VMs having older extension version (extension health check not supported) : $($Global:NotSupportedVMs.Count)"
        show-VMDetailsInReport -Message $txtNotSupported -VMList $Global:NotSupportedVMs
    }
	
	#display Lightweight VMs for which Extension is not deployed
    if ($Global:LightweightVMs.Count -gt 0) {
        $txtLightweightVMs = "Number of VMs Extension is not in operation (Lightweight VMs) : $($Global:LightweightVMs.Count)"
        show-VMDetailsInReport -Message $txtLightweightVMs -VMList $Global:LightweightVMs
    }

    #display VMs for which failed to get Extension status
    if ($Global:FailedVMs.Count -gt 0) {
        $txtFailed = "Number of VMs failed to get extension health status due to error : $($Global:FailedVMs.Count)"
        show-VMDetailsInReport -Message $txtFailed -VMList $Global:FailedVMs
    }

    Write-Host
    Write-Host "Please find the detailed report in file $($Global:ReportFile)"    
    if (($Global:UnHealthyVMs.count -gt 0) -or ($Global:NotSupportedVMs.count -gt 0) -or ($Global:FailedVMs.count -gt 0) -or
         ($Global:SubscriptionsFailedToConnect.count -gt 0)) { 
        Write-Host "Please find the error details in file $($Global:LogFile)"
    }
    Write-Host "For troubleshooting extension related errors, visit: https://learn.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-agent-extension-troubleshoot-known-issues?view=azuresql"
    new-DashSeperator
}

<#
    .SYNOPSIS
    show subscription list with error

    .PARAMETER ErrorMessage
    Description of error

    .PARAMETER FailedSubList
    List of subscriptions
#>
function show-SubscriptionListForError(
    [string]
    $ErrorMessage,
    [System.Collections.ArrayList]
    $FailedSubList
) {
    $txtSubscription = "Subscription"
    $txtSubSeparator = "------------"
    Write-Output $ErrorMessage | Out-File $Global:ReportFile -Append
    Write-Output $ErrorMessage
    Write-Output $txtSubscription | Out-File $Global:ReportFile -Append
    Write-Output $txtSubSeparator | Out-File $Global:ReportFile -Append
    Write-Output $FailedSubList | Out-File $Global:ReportFile -Append
    Write-Output `n | Out-File $Global:ReportFile -Append
}

<#
    .SYNOPSIS
    Write Details of VM to the report file

    .PARAMETER Message
    Message to be written

    .PARAMETER VMList
    List of VMs
#>
function show-VMDetailsInReport(
    [string]
    $Message,
    [System.Collections.ArrayList]
    $VMList
) {
    Write-Output $Message | Out-File $Global:ReportFile -Append
    Write-Output $Message
    new-ReportHelper -VmArray $VMList | Out-File $Global:ReportFile -Append
}

<#
    .SYNOPSIS
    Helper to Generate the report
#>
function new-ReportHelper(
    [System.Collections.ArrayList]
    $VmArray
) {
    $outputObjectTemplate = New-Object -TypeName psobject
    $outputObjectTemplate | Add-Member -MemberType NoteProperty -Name Subscription -Value $null
    $outputObjectTemplate | Add-Member -MemberType NoteProperty -Name ResourceGroup -Value $null
    $outputObjectTemplate | Add-Member -MemberType NoteProperty -Name VmName -Value $null

    $outputObjectList = [System.Collections.ArrayList]@()

    foreach ($vm in $VmArray) {
        $outputObject = $outputObjectTemplate | Select-Object *
        if ($PSVersionTable.PSVersion.Major -eq 7)
        {
        $outputObject.Subscription = $vm.id.Split("/")[2]
        }
        elseif ($PSVersionTable.PSVersion.Major -eq 5)
        {
        $outputObject.Subscription = $vm.ResourceId.Split("/")[2]
        }
        $outputObject.ResourceGroup = $vm.ResourceGroupName
        $outputObject.VmName = $vm.Name
        $tmp = $outputObjectList.Add($outputObject)
    }

    $outputObjectList | Format-Table -AutoSize
}

<#
    .SYNOPSIS
    Given a VM, check if Extension is healthy

    .PARAMETER VmName
    Name of the VM

    .PARAMETER ResourceGroup
    Name of the resource group

    .OUTPUTS
    bool if the extension is Healthy or not
#>
function Get-ExtensionHealthStatusOfSingleVM(
    [Parameter(Mandatory = $true)]
    $VmName,
    [Parameter(Mandatory = $true)]
    $ResourceGroup){

        try{
            # Get extension current status
            $tmp = $Global:Error.Clear()
            $tmp = (Get-AzVM -ResourceGroupName $ResourceGroup -Name $VmName -Status -ErrorAction SilentlyContinue).Extensions | Where-Object { $_.Name -eq 'SqlIaasExtension' }

            $extVersion = $tmp.TypeHandlerVersion
            if ($tmp -eq $null -or $tmp -eq "" -or $extVersion -eq $null) {
                return "Failed to retrieve health status"
            }

            if (-not (Assert-ExtensionVersion -extVersion $extVersion)) {
                return "Not supported Extension version"
            }
            
            # Read ExtensionServiceHealthReport from SqlIaasExtension status
            $RPPluginReport = $tmp.SubStatuses | Where-Object { $_.Code -like '*Resource Provider Plugin*' } | Select-Object -ExpandProperty Message | ConvertFrom-Json
            
            $IsSqlManagement = $RPPluginReport.IsSqlManagement
			$MainServiceLastReportedTime = $RPPluginReport.ExtensionServiceHealthReport.MainServiceLastReportedTime
            $QueryServiceHealthStatus = $RPPluginReport.ExtensionServiceHealthReport.QueryServiceHealthStatus

            if ($IsSqlManagement -eq $false) {
                return "Lightweight VM"
            }
			
            # Get the current UTC time for comparison
            $utcTime = [System.DateTime]::UtcNow
            $utcTimeMinus1Hour = $utcTime.AddHours(-1)           
            
            if ($PSVersionTable.PSVersion.Major -eq 7) {
                $formatString = "MM/dd/yyyy HH:mm:ss"
                $lastReportedTime = [datetime]::ParseExact($MainServiceLastReportedTime, $formatString, [System.Globalization.CultureInfo]::InvariantCulture)
            } else {
                $lastReportedTime = [DateTime]::Parse($MainServiceLastReportedTime).ToUniversalTime()
            }

            # Extension is Healthy if last reported within 1 hr and QueryServiceHealthStatus =1
            if (($lastReportedTime -ge $utcTimeMinus1Hour) -and ($QueryServiceHealthStatus -eq 1))
              { return "Healthy" }
            else 
              { return "UnHealthy" }
        }
        catch {
                return "Failed to retrieve health status"
              }
}

<#
    .SYNOPSIS
    validate extension version can support Health status reporting

    .PARAMETER VersionString
    Current version of Extension

    .OUTPUTS
    bool if the extension version is >= 2.0.129.0

#>
function Assert-ExtensionVersion(
    [string]
    $extVersion
) {
    $versionArray = $extVersion.Split('.')

    # Extension health status is available starting version 2.0.129.0
    if (($versionArray[0] -eq 2) -and ([int]$versionArray[2] -ge 129)) {
        return $true
    }
    else {
        return $false
    }
}

Export-ModuleMember -Function Get-SqlVMsExtensionHealthStatus