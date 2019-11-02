#Requires -Module Az.Compute
#Requires -Module Az.Accounts
#Requires -Module Az.SqlVirtualMachine
#Requires -Module Az.Resources
#Requires -Module Microsoft.PowerShell.Security

<#
	.SYNOPSIS
    Register all Azure VM running SQL Server on Windows with SQL VM Resource provider.

    .DESCRIPTION
    Identify and register all Azure VM running SQL Server on Windows in a list of subscriptions, resource group list, particular resource group
    or a particular VM with SQL VM Resource provider.
    The cmdlet registers the VMs and generates a report and a log file at the end of the execution. The report is generated as a txt file named
    RegisterSqlVMScriptReport<Timestamp>.txt. Errors are logged in the log file named VMsNotRegisteredDueToError<Timestamp>.log. Timestamp is the
    time when the cmdlet was started. A summary is displayed at the end of the script run.
    The Output summary contains the number of VMs that successfully registered, failed or were skipped because of various reasons. The detailed list
    of VMs can be found in the report and the details of error can be found in the log.

    Prerequisites:
    - The script needs to be run on Powershell 5.1 (Windows Only) and is incompatible with Powershell 6.x
    - The subscription whose VMs are to be registered, needs to be registered to Microsoft.SqlVirtualMachine resource provider first. This link describes
      how to register to a resource provider: https://docs.microsoft.com/azure/azure-resource-manager/resource-manager-supported-services
    - Run 'Connect-AzAccount' to first connect the powershell session to the azure account.
    - The Client credentials must have one of the following RBAC levels of access over the virtual machine being registered: Virtual Machine Contributor,
      Contributor or Owner
    - The script requires Az powershell module (>=2.8.0) to be installed. Details on how to install Az module can be found 
      here : https://docs.microsoft.com/powershell/azure/install-az-ps?view=azps-2.8.0
      It specifically requires Az.Compute, Az.Accounts and Az.Resources module which comes as part of Az module (>=2.8.0) installation.
    - The script also requires Az.SqlVirtualMachine module. Details on how to install Az.SqlVirtualMachine can be
      found here: https://www.powershellgallery.com/packages/Az.SqlVirtualMachine/0.1.0

    .PARAMETER SubscriptionList
    List of Subscriptions whose VMs need to be registered

    .PARAMETER Subscription
    Single subscription whose VMs will be registered

    .PARAMETER ResourceGroupList
    List of Resource Groups in a single subscription whose VMs need to be registered

    .PARAMETER ResourceGroupName
    Name of the ResourceGroup whose VMs need to be registered

    .PARAMETER VmList
    List of VMs in a single resource group that needs to be registered

    .PARAMETER Name
    Name of the VM to be registered

    .EXAMPLE
    #To register all VMs in a list of subscriptions
    Register-SqlVMs -SubscriptionList SubscriptionId1,SubscriptionId2
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Summary
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Number of Subscriptions registration failed for because you do not have access or credentials are wrong: 1
    Total VMs Found: 10
    VMs Already registered: 1
    Number of VMs registered successfully: 4
    Number of VMs failed to register due to error: 1
    Number of VMs skipped as VM or the guest agent on VM is not running: 3
    Number of VMs skipped as they are not running SQL Server On Windows: 1
    
    Please find the detailed report in file RegisterSqlVMScriptReport1571314821.txt
    Please find the error details in file VMsNotRegisteredDueToError1571314821.log
    -----------------------------------------------------------------------------------------------------------------------------------------------

    .EXAMPLE
    #To register all VMs in a single subscription
    Register-SqlVMs -Subscription SubscriptionId1
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Summary
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Total VMs Found: 10
    VMs Already registered: 1
    Number of VMs registered successfully: 5
    Number of VMs failed to register due to error: 1
    Number of VMs skipped as VM or the guest agent on VM is not running: 2
    Number of VMs skipped as they are not running SQL Server On Windows: 1
    
    Please find the detailed report in file RegisterSqlVMScriptReport1571314821.txt
    Please find the error details in file VMsNotRegisteredDueToError1571314821.log
    -----------------------------------------------------------------------------------------------------------------------------------------------

    .EXAMPLE
    #To register all VMs in a single subscription and multiple resource groups
    Register-SqlVMs -Subscription SubscriptionId1 -ResourceGroupList ResourceGroup1,ResourceGroup2

    -----------------------------------------------------------------------------------------------------------------------------------------------
    Summary
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Total VMs Found: 4
    VMs Already registered: 1
    Number of VMs registered successfully: 1
    Number of VMs failed to register due to error: 1
    Number of VMs skipped as they are not running SQL Server On Windows: 1
    
    Please find the detailed report in file RegisterSqlVMScriptReport1571314821.txt
    Please find the error details in file VMsNotRegisteredDueToError1571314821.log
    -----------------------------------------------------------------------------------------------------------------------------------------------

    .EXAMPLE
    #To register all VMs in a resource group
    Register-SqlVMs -Subscription SubscriptionId1 -ResourceGroupName ResourceGroup1

    -----------------------------------------------------------------------------------------------------------------------------------------------
    Summary
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Total VMs Found: 4
    VMs Already registered: 1
    Number of VMs registered successfully: 1
    Number of VMs failed to register due to error: 1
    Number of VMs skipped as VM or the guest agent on VM is not running: 1
    
    Please find the detailed report in file RegisterSqlVMScriptReport1571314821.txt
    Please find the error details in file VMsNotRegisteredDueToError1571314821.log
    -----------------------------------------------------------------------------------------------------------------------------------------------

    .EXAMPLE
    #To register multiple VMs in a single subscription and resource group
    Register-SqlVMs -Subscription SubscriptionId1 -ResourceGroupName ResourceGroup1 -VmList VM1,VM2,VM3

    -----------------------------------------------------------------------------------------------------------------------------------------------
    Summary
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Total VMs Found: 3
    VMs Already registered: 0
    Number of VMs registered successfully: 1
    Number of VMs skipped as VM or the guest agent on VM is not running: 1
    Number of VMs skipped as they are not running SQL Server On Windows: 1
    
    Please find the detailed report in file RegisterSqlVMScriptReport1571314821.txt
    Please find the error details in file VMsNotRegisteredDueToError1571314821.log
    -----------------------------------------------------------------------------------------------------------------------------------------------

    .EXAMPLE
    #To register a particular VM
    Register-SqlVMs -Subscription SubscriptionId1 -ResourceGroupName ResourceGroup1 -Name VM1

    -----------------------------------------------------------------------------------------------------------------------------------------------
    Summary
    -----------------------------------------------------------------------------------------------------------------------------------------------
    Total VMs Found: 1
    VMs Already registered: 0
    Number of VMs registered successfully: 1
    
    Please find the detailed report in file RegisterSqlVMScriptReport1571314821.txt
    -----------------------------------------------------------------------------------------------------------------------------------------------

    .LINK
    https://aka.ms/RegisterSqlVMs

    .LINK
    https://www.powershellgallery.com/packages/Az.SqlVirtualMachine/0.1.0
#>
function Register-SqlVMs {
    [CmdletBinding(DefaultParameterSetName = 'SubscriptionList')]
    Param
    (
        [Parameter(Mandatory = $true, ParameterSetName = 'SubscriptionList')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $SubscriptionList,
        [Parameter(Mandatory = $true, ParameterSetName = 'SingleSubscription')]
        [Parameter(Mandatory = $true, ParameterSetName = 'ResourceGroupList')]
        [Parameter(Mandatory = $true, ParameterSetName = 'VmList')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Subscription,
        [Parameter(Mandatory = $true, ParameterSetName = 'ResourceGroupList')]
        [string[]]
        $ResourceGroupList,
        [Parameter(Mandatory = $true, ParameterSetName = 'VmList')]
        [Parameter(ParameterSetName = 'SingleSubscription')]
        [string]
        $ResourceGroupName,
        [Parameter(Mandatory = $true, ParameterSetName = 'VmList')]
        [string[]]
        $VmList,
        [Parameter(ParameterSetName = 'SingleSubscription')]
        [string]
        $Name)

    # give disclaimer
    $accepted = Get-DisclaimerAcceptance
    if (!$accepted) {
        return
    }

    #get credential for connecting to subscription
    $credential = Get-Credential -Credential $null

    #Update Globals
    update-Globals

    if ($PsCmdlet.ParameterSetName -eq 'SubscriptionList') {
        $subsCompleted = 0
        #loop over all subscriptions to register VMs
        foreach ($SubscriptionName in $SubscriptionList) {
            [int]$percent = ($subsCompleted * 100) / $SubscriptionList.Count
            Write-Progress -Activity "Register SQL VMs in $($SubscriptionName) $($subsCompleted+1)/$($SubscriptionList.Count)" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "RegisterVMsInSub" -Id 1;
            if (assert-Subscription -Subscription $SubscriptionName -Credential $credential) {
                register-SqlVMForSubscription -Subscription $SubscriptionName -Credential $credential
            }
            $subsCompleted++
        }
        Write-Progress -Activity "Register SQL VMs" -Status "100% Complete:" -PercentComplete 100 -CurrentOperation "RegisterVMsInSub" -Id 1 -Completed;
    }
    elseif (assert-Subscription -Subscription $Subscription -Credential $credential) {
        if ($PsCmdlet.ParameterSetName -eq 'ResourceGroupList') {
            $rgsCompleted = 0
            foreach ($RgName in $ResourceGroupList) {
                [int]$percent = ($rgsCompleted * 100) / $ResourceGroupList.Count
                Write-Progress -Activity "Register SQL VMs in $($RgName) $($rgsCompleted+1)/$($ResourceGroupList.Count)" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "RegisterVMsInRG" -Id 1;
                register-SqlVMForSubscription -Subscription $Subscription -ResourceGroup $RgName -Credential $credential
                $rgsCompleted++
            }
            Write-Progress -Activity "Register SQL VMs" -Status "100% Complete:" -PercentComplete 100 -CurrentOperation "RegisterVMsInRG" -Id 1 -Completed;
        }
        elseif ($PsCmdlet.ParameterSetName -eq 'VmList') {
            $vmsCompleted = 0
            foreach ($VmName in $VmList) {
                [int]$percent = ($vmsCompleted * 100) / $VmList.Count
                Write-Progress -Activity "Register SQL VMs $($vmsCompleted+1)/$($VmList.Count)" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "RegisterVMsInList" -Id 1;
                register-SqlVMForSubscription -Subscription $Subscription -Credential $credential `
                    -ResourceGroupName $ResourceGroupName -Name $VmName
                $vmsCompleted++
            }
            Write-Progress -Activity "Register SQL VMs in List" -Status "100% Complete:" -PercentComplete 100 -CurrentOperation "RegisterVMsInList" -Id 1 -Completed;
        }
        else {
            register-SqlVMForSubscription -Subscription $Subscription -Credential $credential `
                -ResourceGroupName $ResourceGroupName -Name $Name
        }
    }

    #Report 
    new-Report
}

#Globals for reporting and logging
$Global:TotalVMs = 0
$Global:AlreadyRegistered = 0
$Global:SubscriptionsFailedToRegister = 0
$Global:SubscriptionsFailedToConnect = [System.Collections.ArrayList]@()
$Global:SubscriptionsFailedToRegister = [System.Collections.ArrayList]@()
$Global:RegisteredVMs = [System.Collections.ArrayList]@()
$Global:FailedVMs = [System.Collections.ArrayList]@()
$Global:SkippedVMs = [System.Collections.ArrayList]@()
$Global:UntriedVMs = [System.Collections.ArrayList]@()
$Global:LogFile = $null
$Global:ReportFile = $null

<#
	.SYNOPSIS
    Reset Global Variables
#>
function update-Globals() {
    [int]$timestamp = Get-Date (Get-Date)  -UFormat %s
    $Global:TotalVMs = 0
    $Global:AlreadyRegistered = 0
    $Global:SubscriptionsFailedToRegister = 0
    $Global:SubscriptionsFailedToConnect = [System.Collections.ArrayList]@()
    $Global:SubscriptionsFailedToRegister = [System.Collections.ArrayList]@()
    $Global:RegisteredVMs = [System.Collections.ArrayList]@()
    $Global:FailedVMs = [System.Collections.ArrayList]@()
    $Global:SkippedVMs = [System.Collections.ArrayList]@()
    $Global:UntriedVMs = [System.Collections.ArrayList]@()
    $Global:LogFile = "VMsNotRegisteredDueToError" + $timestamp + ".log"
    $Global:ReportFile = "RegisterSqlVMScriptReport" + $timestamp + ".txt"
    Remove-Item $Global:LogFile -ErrorAction Ignore
    Remove-Item $Global:ReportFile -ErrorAction Ignore
    $txtLogHeader = "Subscription,[Resource Group],[VM Name],[ErrorCode],Error Message"
    Write-Output $txtLogHeader | Out-File $Global:LogFile -Append
}

<#
	.SYNOPSIS
    Get list of VM in a subscription or resourcegroup

    .PARAMETER ResourceGroupName
    Resource Group whose VMs need to be returned

    .PARAMETER Name
    Name of the VM to be returned

    .OUTPUTS
    System.Collections.ArrayList list of VMs
#>
function getVmList(
    [string] $ResourceGroupName,
    [string] $Name
) {
    $vmList = [System.Collections.ArrayList]@()
    #if resource group is passed, look inside the group only
    if ($ResourceGroupName) {
        if ($Name) {
            $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $Name
            $tmp = $vmList.Add($vm)
        }
        else {
            $vmsInRg = Get-AzVM -ResourceGroupName $ResourceGroupName
            foreach ($vm in $vmsInRg) {
                $tmp = $vmList.Add($vm)
            }
        }
    }
    else {
        $vmsInSub = Get-AzVM
        foreach ($vm in $vmsInSub) {
            $tmp = $vmList.Add($vm)
        }
    }
    return , $vmList
}

<#
	.SYNOPSIS
    Get License Type based on the Publisher of the VM image

    .PARAMETER VmObject
    VM Object

    .OUTPUTS
    System.String License Type
#>
function getLicenseType($VmObject) {
    $License = 'AHUB'

    # If published by SQL Server and is not BYOL then treat as PAYG
    if (($VmObject.StorageProfile.ImageReference.Publisher -eq 'MicrosoftSQLServer') -and ($VmObject.StorageProfile.ImageReference.Offer -notmatch '-BYOL')) {
        $License = 'PAYG'
    }
    else {
        $License = 'AHUB'
    }
    return $License
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
        'SqlExtensionNotInstalled' {
            return $true
        }
        'UnExpectedErrorOccurred' {
            return $true
        }
        'Ext_ComputeError' {
            return $true
        }     
        'VmAgentNotRunning' {
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

        #else return false
        Default {
            return $false
        }
    }
}

<#
	.SYNOPSIS
    Checks if vm could not be tried to be registered.

    .PARAMETER ErrorObject
    Error Object

    .OUTPUTS
    System.Boolean true if the command did not try registering VM
#>
function isNotTriedRegistering() {
    switch ($ErrorObject.Exception.Body.Code) {
        'VmNotRunning' {
            return $true
        }
        'VmAgentNotRunning' {
            return $true
        }
        Default {
            return $false
        }
    }
}

<#
	.SYNOPSIS
    Check if the error can be ignored

    .PARAMETER ErrorObject
    Error Object

    .OUTPUTS
    System.Boolean True if we can ignore the error, otherwise false
#>
function isIgnorableError($ErrorObject) {
    switch ($ErrorObject.Exception.Body.Code) {
        'NotSupportedSqlVmOSVersion' { 
            return $true
        }
        'Ext_SqlInstanceIsNotInstalled' {
            return $true
        }
        'CannotConvertToAhub' {
            return $true
        }
        Default {
            return $false
        }
    }
}

<#
	.SYNOPSIS
    Check if registration failed because it is not possible to register as AHUB

    .PARAMETER ErrorObject
    Error Object

    .OUTPUTS
    System.Boolean True if failure was due to registering as AHUB, otherwise false
#>
function isUnableToRegisterAsAHUB($ErrorObject) {
    switch ($ErrorObject.Exception.Body.Code) {
        'CannotConvertToAhub' {
            return $true
        }
        Default {
            return $false
        }
    }
}

<#
	.SYNOPSIS
    Logs error and removes dangling SQL VM resources

    .PARAMETER ErrorObject
    Error Object

    .PARAMETER VmObject
    VM for which the error occured
#>
function handleError(
    [Parameter(Mandatory = $true)]
    $ErrorObject,
    $VmObject) {
    $sqlvm = Get-AzSqlVM -ResourceGroupName $VmObject.ResourceGroupName -Name $VmObject.Name  -ErrorAction Ignore
    # delete if a sql vm resource was created before erroring out
    if ($sqlvm) {
        $tmp = Remove-AzSqlVM -ResourceGroupName $VmObject.ResourceGroupName -Name $VmObject.Name -ErrorAction SilentlyContinue
    }

    #if Ignorable error do not log
    if (isIgnorableError -ErrorObject $ErrorObject) {
        $tmp = $Global:SkippedVMs.Add($VmObject)
    }
    else {
        $subID = $VmObject.Id.Split("/")[2]
        $errorMessage = $ErrorObject.Exception.Message

        #modify error message if required
        if ($ErrorObject.Exception.Body.Code -eq 'AuthorizationFailed') {
            $errorMessage += " Client requires either of Virtual Machine Contributor, Contributor or Owner access over the scope."
        }
        Write-Output "$($subID), $($VmObject.ResourceGroupName), $($VmObject.Name), $($ErrorObject.Exception.Body.Code), $($errorMessage)" | Out-File $Global:LogFile -Append
        if (isNotTriedRegistering -ErrorObject $ErrorObject) {
            $tmp = $Global:UntriedVMs.Add($VmObject)
        }
        else {
            $tmp = $Global:FailedVMs.Add($VmObject)
        }
    }
}

<#
    .SYNOPSIS
    Display the disclaimer and ask for confirmation

    .OUTPUTS
    System.Boolean True if accepted, else false
#>
function Get-DisclaimerAcceptance() {
    $confirmation = $null
    new-DashSeperator
    Write-Host "The script will register all Virtual Machines in the provided scope that are running SQL Server, with Azure SQL VM Resource Provider."
    Write-Host "If the Virtual Machine was created from a SQL Server marketplace Pay-As-You-Go image, it will be registered with Pay-As-You-Go License"
    Write-Host "If the Virtual Machine was created using SQL Server marketplace BYOL image Or Customized image Or SQL Server was self-installed on the Azure VM,"
    Write-Host "it will be registered with Azure Hybrid Benefit License."
    Write-Host
    Write-Host "By running this script I confirm that I have sufficient SQL Server license with Software Assurance to apply this Azure Hybrid Benefit for SQL Server on Azure VM"
    Write-Host "Are you sure you want to perform this action?"
    Do {
        $response = Read-Host "[Y] Yes [N] No (default is 'No')"
        switch ($response) {
            'Y' { $confirmation = $true }
            'Yes' { $confirmation = $true }
            'N' { $confirmation = $false }
            'No' { $confirmation = $false }
        }
    } While ($null -eq $confirmation)
    new-DashSeperator
    return $confirmation
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

    if ($Global:SubscriptionsFailedToRegister.count -gt 0) {
        $errorMessage = "Number of Subscriptions that could not be tried because they are not registered to RP: $($Global:SubscriptionsFailedToRegister.count)"
        show-SubscriptionListForError -ErrorMessage $errorMessage -FailedSubList $Global:SubscriptionsFailedToRegister
    }

    $txtTotalVMsFound = "Total VMs Found: $($Global:TotalVMs)" 
    Write-Output $txtTotalVMsFound | Out-File $Global:ReportFile -Append
    Write-Output $txtTotalVMsFound

    $txtAlreadyRegistered = "VMs Already registered: $($Global:AlreadyRegistered)"
    Write-Output $txtAlreadyRegistered | Out-File $Global:ReportFile -Append
    Write-Output $txtAlreadyRegistered

    #display success
    $txtSuccessful = "Number of VMs registered successfully: $($Global:RegisteredVMs.Count)"
    show-VMDetailsInReport -Message $txtSuccessful -VMList $Global:RegisteredVMs

    #display failure
    if ($Global:FailedVMs.Count -gt 0) {
        $txtFailed = "Number of VMs failed to register due to error: $($Global:FailedVMs.Count)"
        show-VMDetailsInReport -Message $txtFailed -VMList $Global:FailedVMs
    }

    #display VMs not tried
    if ($Global:UntriedVMs.Count -gt 0) {
        $txtNotRunning = "Number of VMs skipped as VM or the guest agent on VM is not running: $($Global:UntriedVMs.Count)"
        show-VMDetailsInReport -Message $txtNotRunning -VMList $Global:UntriedVMs
    }

    #display VMs skipped
    if ($Global:SkippedVMs.Count -gt 0) {
        $txtNotSql = "Number of VMs skipped as they are not running SQL Server On Windows: $($Global:SkippedVMs.Count)"
        show-VMDetailsInReport -Message $txtNotSql -VMList $Global:SkippedVMs
    }

    Write-Host
    Write-Host "Please find the detailed report in file $($Global:ReportFile)"
    if (($Global:FailedVMs.count -gt 0) -or ($Global:UntriedVMs.count -gt 0) -or ($Global:SubscriptionsFailedToRegister.count -gt 0) -or ($Global:SubscriptionsFailedToConnect.count -gt 0)) {
        Write-Host "Please find the error details in file $($Global:LogFile)"
    }
    new-DashSeperator
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
        $outputObject.Subscription = $vm.Id.Split("/")[2]
        $outputObject.ResourceGroup = $vm.ResourceGroupName
        $outputObject.VmName = $vm.Name
        $tmp = $outputObjectList.Add($outputObject)
    }

    $outputObjectList | Format-Table -AutoSize
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
function assert-Subscription(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Subscription,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $Credential
) {
    #connect to the subscription
    $Global:Error.clear()
    $tmp = Connect-AzAccount -Subscription $Subscription -Credential $Credential -ErrorAction SilentlyContinue
    if ($Global:Error) {
        $connectionError = $Global:Error[0]
        $errorMessage = "$($Subscription), $($connectionError[0].Exception.Message)"
        Write-Output $errorMessage | Out-File $Global:LogFile -Append
        $tmp = $Global:SubscriptionsFailedToConnect.Add($Subscription)
        return $false
    }

    # register Subscription with SQL VM RP
    $registration = Get-AzResourceProvider -ProviderNamespace Microsoft.SqlVirtualMachine -ErrorAction SilentlyContinue
    if ((!$registration) -or ($registration[0].RegistrationState -ne 'Registered')) {
        # try register subscription to the SqlVirtualMachine
        $register = Register-AzResourceProvider -ProviderNamespace Microsoft.SqlVirtualMachine -ErrorAction SilentlyContinue
        if ((!$register) -or ($register.RegistrationState -ne 'Registering')) {
            $errorMessage = "$($Subscription), Subscription $($Subscription) should be registered to 'Microsoft.SqlVirtualMachine'. Steps to register can be found here: https://docs.microsoft.com/azure/azure-resource-manager/resource-manager-supported-services. This registration may take around 5 mins to propagate."
        }
        else {
            $errorMessage = "$($Subscription), Subscription $($Subscription) is registering to 'Microsoft.SqlVirtualMachine'. This registration may take around 5 mins to propagate. Run the script again for this subscription."
        }
        Write-Output $errorMessage | Out-File $Global:LogFile -Append
        $tmp = $Global:SubscriptionsFailedToRegister.Add($Subscription)
        return $false
    }
    return $true
}

<#
	.SYNOPSIS
    Registers VMs in a given subscription

    .PARAMETER Subscription
    Subscription for searching the VM

    .PARAMETER Credential
    Credential to connect to subscription

    .PARAMETER ResourceGroupName
    Name of the resourceGroup which needs to be searched for VMs

    .PARAMETER Name
    Name of the VM which is to be registered
#>
function register-SqlVMForSubscription (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Subscription,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $Credential,
    [string] $ResourceGroupName,
    [string] $Name) {
    [System.Collections.ArrayList]$vmList = getVmList -ResourceGroupName $ResourceGroupName -Name $Name
    #update vm count
    $Global:TotalVMs += $vmList.Count

    #Retry options
    Set-Variable MAX_RETRIES -option ReadOnly -value 3
    $retryCount = 0
    $retryIfRequired = $true

    # Try registering VMs and retry if required
    while (($retryCount -le $MAX_RETRIES) -and ($vmList.Count -gt 0)) {
        if ($retryCount -gt 0) {
            [int]$percent = ($retryCount * 100) / $MAX_RETRIES
            Write-Progress -Activity "Retrying registration" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "Retrying" -Id 2;
        }
        $retryCount++
        if ($retryCount -eq $MAX_RETRIES) {
            $retryIfRequired = $false 
        }
        [System.Collections.ArrayList]$vmList = createSqlVmFromList -VMList $vmList -RetryIfRequired $retryIfRequired
        if (($vmList.Count -eq 0) -or ($retryCount -eq $MAX_RETRIES )) {
            Write-Progress -Activity "Retrying registration" -Status "100% Complete:" -PercentComplete 100 -CurrentOperation "Retrying" -Completed -Id 2;
        }
    }
}

<#
    .SYNOPSIS
    Given a list of VMs, create SQL VMs

    .PARAMETER VMList
    List of Compute VMs for which SQL VM is to be created

    .PARAMETER RetryIfRequired
    Flag to specify if resource creation needs to be retried

    .OUTPUTS
    System.Collections.ArrayList List of VMs whose creation failed with retryable errors
#>
function createSqlVmFromList(
    [ValidateNotNullOrEmpty()]
    [array]
    $VMList,
    [bool]
    $RetryIfRequired = $false) {
    $retryableVMs = [System.Collections.ArrayList]@()
    [Int32]$numberOfVMs = $VMList.Count
    $completed = 0
    Write-Progress -Activity "Register SQL VM" -Status "0% Complete:" -PercentComplete 0 -CurrentOperation "RegisteringVMs" -Id 3
    # for each vm in the list try registering to RP
    foreach ($vm in $VMList) {
        # writeprogress of the loop
        [int]$percent = ($completed * 100) / $numberOfVMs
        Write-Progress -Activity "Register SQL VM $($completed+1)/$($VMList.count)" -Status "$percent% Complete:" -PercentComplete $percent -CurrentOperation "RegisteringVMs" -Id 3

        $name = $vm.Name
        $resourceGroupName = $vm.ResourceGroupName
        $location = $vm.Location
        $sqlVm = Get-AzSqlVM -Name $name -ResourceGroupName $resourceGroupName -ErrorAction Ignore
        
        # If already registered
        if ($sqlVm) {
            # Remove Sql VM and continue if the registration failed from the script
            if (($sqlVm.Sku -eq 'Unknown') -and (!$sqlVm.Offer)) {
                #remove sql vm successfully else log
                $isSqlVmRemoved = assert-RemoveSqlVmWithoutError -VmObject $vm
                if (!$isSqlVmRemoved) {
                    $completed++
                    continue
                }
            }
            else {
                # skip the VM if already successfully registered
                $Global:AlreadyRegistered++
                $completed++
                continue
            }
        }

        $SqlManagementType = "LightWeight"
        $LicenseType = getLicenseType -VmObject $vm

        $tmp = $Global:Error.Clear()
        $tmp = New-AzSqlVM -Name $name -ResourceGroupName $resourceGroupName -Location $location `
            -SqlManagementType $SqlManagementType  -LicenseType $LicenseType -ErrorAction SilentlyContinue

        # try re-registering if the error was due to Web, Express or Developer registering as AHUB
        if ($Global:Error) {
            if (isUnableToRegisterAsAHUB -ErrorObject $Global:Error[0]) {
                $tmp = handleError -ErrorObject $Global:Error[0] -VmObject $vm
                $tmp = $Global:Error.Clear()
                $LicenseType = 'PAYG'
                $tmp = New-AzSqlVM -Name $name -ResourceGroupName $resourceGroupName -Location $location `
                    -SqlManagementType $SqlManagementType  -LicenseType $LicenseType -ErrorAction SilentlyContinue
            }
        }

        if ($Global:Error) {
            $LastError = $Global:Error[0]
            $isRetryable = isRetryableError -ErrorObject $LastError

            #Add the vm to the retry list if error is retryable
            if ($isRetryable -and $RetryIfRequired) {
                $sqlVm = Get-AzSqlVM -Name $name -ResourceGroupName $resourceGroupName -ErrorAction Ignore
                if ($sqlVm) {
                    $isSqlVmRemoved = assert-RemoveSqlVmWithoutError -VmObject $vm
                    if (!$isSqlVmRemoved) {
                        $completed++
                        continue
                    }
                }
                $tmp = $retryableVMs.Add($vm)
            }
            else {
                $tmp = handleError -ErrorObject $LastError -VmObject $vm
            }
        }
        else {
            $tmp = $Global:RegisteredVMs.Add($vm)
        }
        $completed++
    }
    Write-Progress -Activity "Register SQL VM" -Completed -CurrentOperation "RegisteringVMs" -Id 3
    return , $retryableVMs;
}

<#
    .SYNOPSIS
    Remove Sql VM and handle errors

    .PARAMETER VmObject
    VmObject for the SQL VM to be removed

    .OUTPUTS
    System.Boolean True if SQL VM was removed successfully else False
#>
function assert-RemoveSqlVmWithoutError(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    $VmObject
) {
    $Global:Error.Clear()
    $tmp = Remove-AzSqlVM -Name $VmObject.Name -ResourceGroupName $VmObject.ResourceGroupName -ErrorAction SilentlyContinue
    if ($Global:Error) {
        $tmp = handleError -ErrorObject $Global:Error[0] -VmObject $VmObject
        return $false
    }
    return $true
}
