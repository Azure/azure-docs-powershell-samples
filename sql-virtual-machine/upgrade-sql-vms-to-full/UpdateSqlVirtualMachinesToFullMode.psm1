#Requires -Module Az.Compute
#Requires -Module Az.Accounts
#Requires -Module Az.SqlVirtualMachine
#Requires -Module Az.Resources
#Requires -Module Microsoft.PowerShell.Security

<#
    .SYNOPSIS
    Updates all Azure SQL VM running LightWeight to Full mode.

    .DESCRIPTION
    Identify and update all Azure SQL VM running LightWeight extension from list of subscriptions or unique subscription. 
    A summary is displayed at the end of the script run.
    The Output summary contains the number of SQL VMs that successfully updated, failed or were skipped because of various reasons.
    Reasons may include Multiple Instances on the VM, Failover Cluster VM, status of the VM not available at the time of the script.
    Failed VMs may correspond to authorization issues, SQL Server not running on the VM, VM not running or Guest Agent on the VM not running.

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
    List of Subscriptions whose SQL VMs need to be updated
    
    .PARAMETER TenantId
    Tenant id where the subscriptions are hosted
    
    .EXAMPLE
    #To update all SQL VMs in a single subscription
    Update-SqlVMsToFullMode -SubscriptionList SubscriptionId1
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Summary
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Total VMs Found: 10
    Number of VMs updated successfully: 5
    Number of VMs failed to update due to VMNotRunning or AuthorizationErrors: 1
    Number of VMs skipped: 2
    
    Please find the detailed report in file UpdateSqlVMToFullScriptReport1571314821.txt
    Please find the error details in file VMsNotUpdatedDueToError1571314821.log
    -----------------------------------------------------------------------------------------------------------------------------------------------

    .NOTES
    https://www.powershellgallery.com/packages/Az.SqlVirtualMachine
#>
function Update-SqlVMsToFullMode {
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
    #loop over all subscriptions to update VMs
    foreach ($SubscriptionId in $SubscriptionList) {
        [int]$percent = ($subsCompleted * 100) / $SubscriptionList.Count
        Write-Progress -Activity "Update SQL VMs in $($SubscriptionId) $($subsCompleted+1)/$($SubscriptionList.Count)" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "UpdateVMsInSub" -Id 1;

        $isSubValid = $false
        if ($TenantId){
            $isSubValid = Assert-SubscriptionMFA -Subscription $SubscriptionId -TenantId $TenantId
        }else{
            $isSubValid = Assert-Subscription -Subscription $SubscriptionId -Credential $credential
        }

        if ($isSubValid) {
            Update-SqlVMForSubscription -Subscription $SubscriptionId -Credential $credential
        }
        $subsCompleted++
    }
    Write-Progress -Activity "Update SQL VMs to Full mode" -Status "100% Complete:" -PercentComplete 100 -CurrentOperation "UpdateVMsInSub" -Id 1 -Completed;

    #Report 
    new-Report
}

<#
    .SYNOPSIS
    Update SQL VMs in a given subscription

    .PARAMETER Subscription
    Subscription for searching the VM

    .PARAMETER Credential
    Credential to connect to subscription
#>
function Update-SqlVMForSubscription (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Subscription,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $Credential) {
    [System.Collections.ArrayList]$vmList = Get-SqlVmList
    #update vm count
    $Global:TotalVMs += $vmList.Count

    #Retry options
    Set-Variable MAX_RETRIES -option ReadOnly -value 2
    $retryCount = 0
    $retryIfRequired = $true

    # Try upgrading VMs and retry if required
    while (($retryCount -le $MAX_RETRIES) -and ($vmList.Count -gt 0)) {
        if ($retryCount -gt 0) {
            [int]$percent = ($retryCount * 100) / $MAX_RETRIES
            Write-Progress -Activity "Retrying update" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "Retrying" -Id 2;
        }
        $retryCount++
        if ($retryCount -eq $MAX_RETRIES) {
            $retryIfRequired = $false 
        }
        [System.Collections.ArrayList]$vmList = Update-SqlVmFromList -VMList $vmList -RetryIfRequired $retryIfRequired
        if (($vmList.Count -eq 0) -or ($retryCount -eq $MAX_RETRIES )) {
            Write-Progress -Activity "Retrying update" -Status "100% Complete:" -PercentComplete 100 -CurrentOperation "Retrying" -Completed -Id 2;
        }
    }
}

<#
    .SYNOPSIS
    Get list of SQL VMs in a subscription with lightWeight mode

    .OUTPUTS
    System.Collections.ArrayList list of VMs
#>
function Get-SqlVmList() {
    $vmList = [System.Collections.ArrayList]@()

    $vmsInSub = Get-AzSqlVM
    # We will get all VMs that are Windows, since they're the only allowed to update to Full
    # also all the VMs that were properly registered
    foreach ($vm in $vmsInSub) {
        if (($vm.Sku -ne 'Unknown') -and ($vm.Offer -like '*WS*') -and ($vm.SqlManagementType -eq 'LightWeight')) {
            $tmp = $vmList.Add($vm)
        }
    }
    return , $vmList
}

<#
    .SYNOPSIS
    Successfully connect to subscription

    .PARAMETER Subscription
    Subscription for searching the VM

    .PARAMETER Credential
    Credential to connect to subscription

    .OUTPUTS
    System.Boolean true if successfully connected and RP is registered, else false
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
$Global:UpdatedVMs = [System.Collections.ArrayList]@()
$Global:FailedVMs = [System.Collections.ArrayList]@()
$Global:SkippedVMs = [System.Collections.ArrayList]@()
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
    $Global:UpdatedVMs = [System.Collections.ArrayList]@()
    $Global:FailedVMs = [System.Collections.ArrayList]@()
    $Global:SkippedVMs = [System.Collections.ArrayList]@()
    $Global:LogFile = "VMsNotUpdatedDueToError" + $timestamp + ".log"
    $Global:ReportFile = "UpdateSqlVMToFullScriptReport" + $timestamp + ".txt"
    Remove-Item $Global:LogFile -ErrorAction Ignore
    Remove-Item $Global:ReportFile -ErrorAction Ignore
    $txtLogHeader = "Subscription,[Resource Group],[VM Name],[ErrorCode],Error Message"
    Write-Output $txtLogHeader | Out-File $Global:LogFile -Append
}

<#
    .SYNOPSIS
    Checks if given error is retryable or not

    .PARAMETER ErrorObject
    Error Object

    .OUTPUTS
    System.boolean True if the error is retryable
#>
function isRetryableError(
    [Parameter(Mandatory = $true)]
    $ErrorObject) {
    $errorCode = $ErrorObject.Exception.Body.Code
    switch ($errorCode) {
        # retryable
        'UnExpectedErrorOccurred' {
            return $true
        }
        'Ext_ComputeError' {
            return $true
        }
        'GatewayTimeout' {
            return $true
        }
        'CRPNotAllowedOperation' {
            return $true
        }
        'InternalServerError' {
            return $true
        }
        # non retryable
        'Ext_SqlMultipleNamedInstancesFound' {
            return $false
        }
        'UnsupportedSqlManagementMode' {
            return $false
        }
        Default {
            return $false
        }
    }
}

<#
    .SYNOPSIS
    Checks if vm could not be tried because VM is not running, or there are no permissions.

    .PARAMETER ErrorObject
    Error Object

    .OUTPUTS
    System.Boolean true if the command did not try registering VM
#>
function CannotBeRetried(    
    [Parameter(Mandatory = $true)]
    $ErrorObject) {
    $errorCode = $ErrorObject.Exception.Body.Code
    switch ($errorCode) {
        'VmNotRunning' {
            return $true
        }
        'VmAgentNotRunning' {
            return $true
        }
        'AuthorizationFailed'{
            return $true
        }
        'LinkedAuthorizationFailed'{
            return $true
        }
        'Ext_SqlIaasExtensionError'{
            return $true
        }
        Default {
            return $false
        }
    }
}

<#
    .SYNOPSIS
    Given a list of SQL VMs, update SQL VMs to Full

    .PARAMETER VMList
    List of SQL VMs for which will be updated to Full

    .PARAMETER RetryIfRequired
    Flag to specify if resource creation needs to be retried

    .OUTPUTS
    System.Collections.ArrayList List of SQL VMs whose creation failed with retryable errors
#>
function Update-SqlVmFromList(
    [ValidateNotNullOrEmpty()]
    [array]
    $VMList,
    [bool]
    $RetryIfRequired = $false) {

    $retryableVMs = [System.Collections.ArrayList]@()
    [Int32]$numberOfVMs = $VMList.Count
    $completed = 0
    Write-Progress -Activity "Update SQL VM" -Status "0% Complete:" -PercentComplete 0 -CurrentOperation "UpgradingVMs" -Id 3

    # for each vm in the list try upgrading to Full
    foreach ($vm in $VMList) {
        # write progress of the loop
        [int]$percent = ($completed * 100) / $numberOfVMs
        Write-Progress -Activity "Update SQL VM $($completed+1)/$($VMList.count)" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "UpdatingVMs" -Id 3

        $name = $vm.Name
        $resourceGroupName = $vm.ResourceGroupName
        $SqlManagementType = 'Full'

        # assert that in fact we can update
        if (Assert-CanUpdateToFull -VmName $name -ResourceGroup $resourceGroupName){
            $tmp = $Global:Error.Clear()
            $tmp = Update-AzSqlVM -Name $name -ResourceGroupName $resourceGroupName -SqlManagementType $SqlManagementType -ErrorAction SilentlyContinue

            if ($Global:Error) {
                $LastError = $Global:Error[0]
                $isRetryable = isRetryableError -ErrorObject $LastError
           
                if ($isRetryable -and $RetryIfRequired) {

                    #Add the vm to the retry list if error is retryable
                    $tmp = $retryableVMs.Add($vm)
                }else {
                    $cantRetry = CannotBeRetried -ErrorObject $LastError

                    #Check if it's an authorization issue and or VM not running and skip
                    if ($cantRetry){
                        $tmp = $Global:FailedVMs.Add($vm)
                    }
                }
            }else {
                $tmp = $Global:UpdatedVMs.Add($vm)
            }
        }else{
            $tmp = $Global:SkippedVMs.Add($vm)
        }

        $completed++
    }
    Write-Progress -Activity "Updating VMs" -Completed -CurrentOperation "UpdatingVMs" -Id 3
    return , $retryableVMs;
}

<#
    .SYNOPSIS
    Given a VM, check if Extension can update to Full

    .PARAMETER VmName
    Name of the VM

    .PARAMETER ResourceGroup
    Name of the resource group

    .OUTPUTS
    bool if you can update or not
#>
function Assert-CanUpdateToFull(
    [Parameter(Mandatory = $true)]
    $VmName,
    [Parameter(Mandatory = $true)]
    $ResourceGroup){

    # Get extension status first to check if update is possible
    $tmp = $Global:Error.Clear()
    $tmp = Get-AzVMExtension -Name "SqlIaaSExtension" -VMName $VmName -ResourceGroupName $ResourceGroup -Status -ErrorAction SilentlyContinue
    if ($Global:Error) {
        return $false     
    }

    if ($tmp.SubStatuses.Message){
        try{

            $managementType = $tmp.SubStatuses.Message | ConvertFrom-Json
            switch ($managementType.SqlManagementType) {
                'OK' {
                    return $true
                }
                'MultipleNamedInstances' {
                    return $false
                }
                'FailoverClusterInstance'{
                    return $false
                }
                'WS2008'{
                    return $false
                }
                Default {
                    return $true
                }
            }

        } catch {}
    }
    return $true
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
        $errorMessage = "Number of Subscriptions registration failed for because you do not have access or credentials are incorrect: $($Global:SubscriptionsFailedToConnect.count)"
        show-SubscriptionListForError -ErrorMessage $errorMessage -FailedSubList $Global:SubscriptionsFailedToConnect
    }


    $txtTotalVMsFound = "Total VMs Found: $($Global:TotalVMs)" 
    Write-Output $txtTotalVMsFound | Out-File $Global:ReportFile -Append
    Write-Output $txtTotalVMsFound


    #display success
    $txtSuccessful = "Number of VMs updated successfully: $($Global:UpdatedVMs.Count)"
    show-VMDetailsInReport -Message $txtSuccessful -VMList $Global:UpdatedVMs

    #display failure
    if ($Global:FailedVMs.Count -gt 0) {
        $txtFailed = "Number of VMs failed to update due to VMNotRunning or AuthorizationErrors: $($Global:FailedVMs.Count)"
        show-VMDetailsInReport -Message $txtFailed -VMList $Global:FailedVMs
    }

    #display VMs that cannot update from LightWeight
    if ($Global:SkippedVMs.Count -gt 0) {
        $txtFailed = "Number of VMs skipped: $($Global:SkippedVMs.Count)"
        show-VMDetailsInReport -Message $txtFailed -VMList $Global:SkippedVMs
    }

    Write-Host
    Write-Host "Please find the detailed report in file $($Global:ReportFile)"
    if (($Global:FailedVMs.count -gt 0) -or ($Global:SubscriptionsFailedToConnect.count -gt 0)) {
        Write-Host "Please find the error details in file $($Global:LogFile)"
    }
    new-DashSeperator
}

<#
    .SYNOPSIS
    Registers VMs in a given subscription

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
        $outputObject.Subscription = $vm.ResourceId.Split("/")[2]
        $outputObject.ResourceGroup = $vm.ResourceGroupName
        $outputObject.VmName = $vm.Name
        $tmp = $outputObjectList.Add($outputObject)
    }

    $outputObjectList | Format-Table -AutoSize
}

Export-ModuleMember -Function Update-SqlVMsToFullMode