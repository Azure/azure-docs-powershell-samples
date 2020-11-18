# -------------------------------------------------------------------------------------------------
<#  © 2020 Microsoft Corporation. All rights reserved. This sample code is not supported under any Microsoft standard support program or service. 
This sample code is provided AS IS without warranty of any kind. Microsoft disclaims all implied warranties including, without limitation, 
any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance 
of the sample code and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, 
production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business 
profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the 
sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
#>
#  Version: 1.0.0.0

#  Requirements: 
#       Refer Readme.html for prerequisites and execution guidance 
#       Following files should be placed in the same folder as this script before execution:
#            Config  : CommonAssessmentProperties.json 
#                      AssessmentCombinations.json
#                      
#                      

# -------------------------------------------------------------------------------------------------
# Global variables
$global:contentType = 'application/json' 

<#
.SYNOPSIS
Creates multiple assessments in the specified Azure Migrate project within a specified Azure subscription.
.DESCRIPTION
The New-AssessmentCreation cmdlet creates multiple assessments based on the properties listed in the AssessmentCombination.json .
.PARAMETER subscriptionId
Specifies the Azure subscription to query.
.PARAMETER resourceGroupName
Specifies the Azure Resource Group to query.
.PARAMETER assessmentProjectName
Specifies the Azure Migrate assessment project to query.
.PARAMETER discoverySource
Specifies the Azure Migrate discovery source (Appliance/Import) to query.
.EXAMPLE
Create all assessments in Azure Migrate based on the properties listed in the AssessmentCombination.json
PS C:\Assessment_Utility> New-AssessmentCreation -subscriptionId "4bd2aa0f-2bd2-4d67-91a8-5a4533d58600" -resourceGroupName "rajosh-rg" -assessmentProjectName "rajoshSelfHost-Physical92c3project" -discoverySource "Appliance"

.NOTES
1. The function returns null.
2. Creates a new group based on discovery source and adds all machines in the project
3. Creates multiple assessments and exports the assessment reports in the same folder where the script is being run.
4. If the function returns no machines found, wait for atleast 1 day afetr starting discovery to run this script.
#>
function New-AssessmentCreation {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$subscriptionId,
        [Parameter(Mandatory = $true)][string]$resourceGroupName,
        [Parameter(Mandatory = $true)][string]$assessmentProjectName,
        [Parameter(Mandatory = $false)][string]$discoverySource
    )
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
    Set-AzContext -SubscriptionId $subscriptionid

    #Get Aunthenticaltion token to Azure and create header
    $token = Get-AccessToken
    $headers = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'
    $headers.Add("Authorization", "Bearer $token") 

    #Use appliance based discovery as default discovery source if user does not provide the parameter
    if($discoverySource -eq ""){
        $discoverySource = "Appliance"
    }

    <# If you wish to use an existing group, please specify the group namein $groupName and use the Get-Group cmdlet
        # $group = Get-Group -token $token -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -assessmentProjectName $assessmentProjectName -discoverySource $discoverySource -groupName $groupName 
    #>

    #Create a new group with all machines discovered in the project based on the mentioned discovery source
    $groupName = "AllMachines_"+$discoverySource
    $group = New-GroupAddMachines -token $token -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -assessmentProjectName $assessmentProjectName -discoverySource $discoverySource -groupName $groupName

    #Creating assessment on the newly created group
    ##PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/assessmentProjects/{projectName}/groups/{groupName}/assessments/{assessmentName}?api-version=2019-10-01
    
    ##Get common assessment properties from CommonAssessmentProperties.json  
    $assessmentCommonProperties = Get-Content -Path .\CommonAssessmentProperties.json | ConvertFrom-Json
    $assessmentProperties = $assessmentCommonProperties
    $azureLocation = $assessmentProperties.properties.azureLocation

    ##Get Assessment options for valid Target location, Reserved Instances and VM family combinations
    $assessmentOptionsURL ="https://management.azure.com/subscriptions/"+$subscriptionId+"/resourceGroups/"+$resourceGroupName+"/providers/Microsoft.Migrate/assessmentprojects/"+$assessmentProjectName+"/assessmentoptions/default?api-version=2019-10-01"
    try{
        $responseAssessmentOptions = Invoke-RestMethod -ContentType "application/json" -Uri $assessmentOptionsURL -Method "GET" -Headers $headers
    }
    catch{
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }
    
    ##Get properties in assessment combinations for which multiple assessments will be created
    $assessmentCombinations = Get-Content -Path .\AssessmentCombinations.json | ConvertFrom-Json
    Write-Host "Creating assessments for the following combinations:"
    Write-Host ($assessmentCombinations.properties | Format-Table | Out-String)

    ##Initialise an array of Assessment names
    $assessmentName = New-Object string[] ($assessmentCombinations.properties).count
    [int] $i= 0

    ##Create assessment for each property combination listen in the AssessmentCombinations.json file
    $assessmentCombinations.properties | ForEach-Object {
        $assessmentProperties = $assessmentCommonProperties

        ###Assign name, sizingCriterion, reservedInstance and azureHybridUseBenefit properties as in AssessmentCombinations.json file
        $assessmentProperties.properties.sizingCriterion = $_.sizingCriterion
        $assessmentProperties.properties.reservedInstance = $_.reservedInstance
        $assessmentProperties.properties.azureHybridUseBenefit = $_.azureHybridUseBenefit
        $assessmentName[$i] = $_.name

        ###If reserved Instances, do not add discount and VM uptime in properties and check if taregt location supports Reserved Instances
        if($assessmentProperties.properties.reservedInstance -ne "None"){
            if (-NOT $azureLocation -in $responseAssessmentOptions.properties.reservedInstanceSupportedLocations){
                Write-Host "Reserved Instances are not valid for this location. Please change the target Azure location in assesment properties"
                break
            }
            $assessmentProperties.properties.azureVmFamilies = $responseAssessmentOptions.properties.reservedInstanceVmFamilies
            ###If reserved Instances, do not add discount and VM uptime in properties 
            if($assessmentProperties.properties.vmUptime){
                $assessmentProperties.properties = $assessmentProperties.properties | Select-Object * -ExcludeProperty vmUptime
            }
            if($assessmentProperties.properties.discountPercentage){
                $assessmentProperties.properties = $assessmentProperties.properties | Select-Object * -ExcludeProperty discountPercentage
            }   
        }else{
            $responseAssessmentOptions.properties.vmfamilies | ForEach-Object{
                if($azureLocation -in $_.targetLocations){
                    $assessmentProperties.properties.azureVmFamilies += $_.familyName
                }
            }
        }
        
        ###If Sizing criteriion is As-on-premises, do not add performance duration and percentile
        if($assessmentProperties.properties.sizingCriterion -eq "AsOnPremises"){
            if($assessmentProperties.properties.timeRange){
                $assessmentProperties.properties = $assessmentProperties.properties | Select-Object * -ExcludeProperty timeRange
                }
                if($assessmentProperties.properties.percentile){
                    $assessmentProperties.properties = $assessmentProperties.properties | Select-Object * -ExcludeProperty percentile
                }   
        } 
        $assessmentProperties = $assessmentProperties | ConvertTo-Json
        
        ###Create assessment
        $assessmentURL = "https://management.azure.com/subscriptions/"+$subscriptionId+"/resourceGroups/"+$resourceGroupName+"/providers/Microsoft.Migrate/assessmentprojects/"+$assessmentProjectName+"/groups/"+$groupName+ "/assessments/"+$assessmentName[$i]+"?api-version=2019-05-01"
        try{
            Write-Host "Creating assessment:"$assessmentName[$i]
            $responseAssessmentList = Invoke-RestMethod -ContentType "$global:contentType" -Uri $assessmentURL -Method "PUT" -Headers $headers -Body $assessmentProperties
        }
        catch{
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        }
        $i = $i+1

        ###Pausing for 20s between every assessment creation request
        Start-Sleep -s 20
    }

    #Download Assessment reports in local folder
    Export-Assessment -token $token -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -assessmentProjectName $assessmentProjectName -groupName $groupName -assessmentName $assessmentName
    
    return $null
}


<#
.SYNOPSIS
Gets group status based on group name in the specified Azure Migrate project within a specified Azure subscription.
.DESCRIPTION
The Get-Group cmdlet checks the group status based on group name and returns the group object once the status is completed
.PARAMETER token
Specifies the Azure authentication token.
.PARAMETER subscriptionId
Specifies the Azure subscription to query.
.PARAMETER resourceGroupName
Specifies the Azure Resource Group to query.
.PARAMETER assessmentProjectName
Specifies the Azure Migrate assessment project to query.
.PARAMETER groupName
Specifies the group name to query.
.EXAMPLE
Check if the group status is completed and return the group details
PS C:\Assessment_Utility> Get-GroupStatus -subscriptionId "4bd2aa0f-2bd2-4d67-91a8-5a4533d58600" -resourceGroupName "rajosh-rg" -assessmentProjectName "rajoshSelfHost-Physical92c3project" -groupName "All_machines"

.NOTES
1. The function returns an object with group details.
2. This function needs to be called before assessment creation so that update machine operation has completed on the group
#>
function Get-GroupStatus {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$token,
        [Parameter(Mandatory = $true)][string]$subscriptionId,
        [Parameter(Mandatory = $true)][string]$resourceGroupName,
        [Parameter(Mandatory = $true)][string]$assessmentProjectName,
        [Parameter(Mandatory = $true)][string]$groupName
    )
    $headers = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'
    $headers.Add("Authorization", "Bearer $Token")
    
    #Check group status or Get group
    ##GET https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/assessmentProjects/{projectName}/groups/{groupName}?api-version=2019-10-01
    ## Poll the group response till the status is completed

    do{
        Start-Sleep -s 5
        Write-Host "Getting Group Status"
        try{
            $responseGroup = Invoke-RestMethod -ContentType "$global:contentType" -Uri $groupURI -Method "GET" -Headers $headers
        }
        catch{
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        }
        Write-Host $responseGroup.properties.groupStatus
        }while($responseGroup.properties.groupStatus -ne "Completed")
        return $responseGroup

}    

<#
.SYNOPSIS
Creates a new group in the specified Azure Migrate project within a specified Azure subscription.
.DESCRIPTION
The New-GroupAddMachines cmdlet creates a new group based on discovery source and adds all machines in the group from the Azure Migrate project.
.PARAMETER token
Specifies the Azure authentication token.
.PARAMETER subscriptionId
Specifies the Azure subscription to query.
.PARAMETER resourceGroupName
Specifies the Azure Resource Group to query.
.PARAMETER assessmentProjectName
Specifies the Azure Migrate assessment project to query.
.PARAMETER discoverySource
Specifies the Azure Migrate discovery source (Appliance/Import) to query.
.PARAMETER groupName
Specifies the group name to query.
.EXAMPLE
Cretae a new group with group name ALl_Machines
PS C:\Assessment_Utility> New-GroupAddMachines -subscriptionId "4bd2aa0f-2bd2-4d67-91a8-5a4533d58600" -resourceGroupName "rajosh-rg" -assessmentProjectName "rajoshSelfHost-Physical92c3project" -groupName "All_machines"

.NOTES
1. The function returns an object with group details.
2. This function needs to be called before assessment creation so that group creation has completed
#>
function New-GroupAddMachines {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$token,
        [Parameter(Mandatory = $true)][string]$subscriptionId,
        [Parameter(Mandatory = $true)][string]$resourceGroupName,
        [Parameter(Mandatory = $true)][string]$assessmentProjectName,
        [Parameter(Mandatory = $false)][string]$discoverySource,
        [Parameter(Mandatory = $true)][string]$groupName
    )
    $headers = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'
    $headers.Add("Authorization", "Bearer $token")

    #Use appliance based discovery as default discovery source if user does not provide the parameter
    if($discoverySource -eq ""){
        $discoverySource = "Appliance"
    }
    #Create group
    ##PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/assessmentProjects/{projectName}/groups/{groupName}?api-version=2019-10-01
    $groupURI= "https://management.azure.com/subscriptions/" + $subscriptionId + "/resourceGroups/"+ $resourceGroupName + "/providers/Microsoft.Migrate/assessmentProjects/"+ $assessmentProjectName + "/groups/"+$groupName+"?api-version=2019-10-01"
    ##Define the body JSON to be passed with th request
    $body = @"
    {   
        "properties": {
            "groupType": ""
        }
    }
"@

    $body = $body | ConvertFrom-Json

    ##Specify groupType as Import if the discovery source is import
    if($discoverySource -ceq "Import"){
        $body.properties.groupType = "Import"
    }
    $body = $body | ConvertTo-Json

    ##Create group
    try{
        $group = Invoke-RestMethod -ContentType "$global:contentType" -Uri $groupURI -Method "PUT" -Headers $headers -Body $body
        if($group.name){
            Write-Host "Group created:"$group.name
        }
    } 
    catch{
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }

    ##Remove quotes from the eTag field
    [String] $eTag = $group.eTag
    $eTag = $eTag.Replace("`"","")

    #Get list of machines in the assessment project to be added to the group
    ##GET https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/assessmentProjects/{projectName}/machines?api-version=2019-10-01 
   
$machinesByDiscoverySource = @"
{
    "properties": {
        "machines": [
        ]
     }
}
"@
    
    $machinesByDiscoverySource = $machinesByDiscoverySource | ConvertFrom-Json
    $machineURL = "https://management.azure.com/subscriptions/" + $subscriptionId + "/resourceGroups/"+ $resourceGroupName + "/providers/Microsoft.Migrate/assessmentProjects/"+ $assessmentProjectName +"/machines?api-version=2019-10-01"
    Write-Host "Getting all machines discovered via"$discoverySource
    ##Get all machines in the project till the nextLink in the response is blank
    try{
        do{
            $responseMachineList = Invoke-RestMethod -ContentType "$global:contentType" -Uri $machineURL -Method "GET" -Headers $headers
            if($responseMachineList){
                $responseMachineList.value | ForEach-Object{
                    if($discoverySource -ceq "Import"){
                        if($_.id.EndsWith('-import')){
                           $machinesByDiscoverySource.properties.machines += $_.id
                        }
                    }
                    if($discoverySource -ceq "Appliance"){
                        if(-Not $_.id.EndsWith('-import')){
                             $machinesByDiscoverySource.properties.machines += $_.id
                            }
                    }
                }
                if($responseMachineList.nextLink){
                    ###Assign the next link to machine URL to get the next set of machines
                    $machineURL = $responseMachineList.nextLink
                }
            }
        }while($responseMachineList.nextLink)
    }
    catch{
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }

    #Add/Update machines in the group
    ##POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/assessmentProjects/{projectName}/groups/{groupName}/updateMachines?api-version=2019-10-01
    $groupUpdateURI= "https://management.azure.com/subscriptions/" + $subscriptionId + "/resourceGroups/"+ $resourceGroupName + "/providers/Microsoft.Migrate/assessmentProjects/"+ $assessmentProjectName + "/groups/"+$groupName+"/updateMachines?api-version=2019-10-01"
    Write-Host "Adding machines to the group..."
    ## Adding machines to the group based on discovery source
    if($machinesByDiscoverySource.properties.machines){
        Write-Host "Number of machines to be added to the group:"$machinesByDiscoverySource.properties.machines.count
        if($machinesByDiscoverySource.properties.machines.count -ge 10000){
             ## POST calls to update machines in the group can only be sent for 10000 machines at a time
            $parts = [Math]::Ceiling($machinesByDiscoverySource.properties.machines.count / 10000)
            $numberOfMachines = 10000

        }
        else {
            $parts = 1
        }
    }
    else{
        Write-Host "No machines to add to the group. Please wait for some more time after the discovery has been initiated."
        break
    }    

     ## POST calls to update machines in the group can only be sent for 10000 machines at a time
    for($i=1; $i -le $parts; $i++){
         ##Define the body JSON to be passed with the update group request
        $body = @"
        {
            "eTag" : "",
            "properties": {
                "machines": [
                ],
                "operationType": "Add"
            }
    }
"@
        $body = $body | ConvertFrom-Json
        Write-Host "Making update machines call #"$i 
        if($machinesByDiscoverySource.properties.machines.count -le 10000){
            $numberOfMachines = $machinesByDiscoverySource.properties.machines.count
        }
        $body.properties.machines = $machinesByDiscoverySource.properties.machines | Select-Object -First $numberOfMachines
        $body = $body | ConvertTo-Json
        try{
            Invoke-RestMethod -ContentType "$global:contentType" -Uri $groupUpdateURI -Method "POST" -Headers $headers -Body $body
        } 
        catch{
            Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
            Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        }
        #Check group status before creating assessment
        $group = Get-GroupStatus -token $token -subscriptionId $subscriptionId -resourceGroupName $resourceGroupName -assessmentProjectName $assessmentProjectName -groupName $groupName
        $machinesByDiscoverySource.properties.machines = $machinesByDiscoverySource.properties.machines | Select-Object -Skip $numberOfMachines
        $body = $body | ConvertFrom-Json
    }
    return $group
} 

<#
.SYNOPSIS
Exports assessment reports in the specified Azure Migrate project within a specified Azure subscription.
.DESCRIPTION
The Export-Assessment cmdlet exports assessment reports into .xlsx files.
.PARAMETER token
Specifies the Azure authentication token.
.PARAMETER subscriptionId
Specifies the Azure subscription to query.
.PARAMETER resourceGroupName
Specifies the Azure Resource Group to query.
.PARAMETER assessmentProjectName
Specifies the Azure Migrate assessment project to query.
.PARAMETER groupName
Specifies the group name to query.
.PARAMETER assessmentName
Specifies the Azure Migrate assessment names to query.
.EXAMPLE
Export the assessment report for the first assessment name in array $assessmentName
PS C:\Assessment_Utility> Export-Assessment -subscriptionId "4bd2aa0f-2bd2-4d67-91a8-5a4533d58600" -resourceGroupName "rajosh-rg" -assessmentProjectName "rajoshSelfHost-Physical92c3project" -groupName "All_machines" -assessmentName $assessmentName[0]

.NOTES
1. The function returns null
2. This function needs to be called once assessment has been created in the Azure Migrate project
#>
function Export-Assessment {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$token,
        [Parameter(Mandatory = $true)][string]$subscriptionId,
        [Parameter(Mandatory = $true)][string]$resourceGroupName,
        [Parameter(Mandatory = $true)][string]$assessmentProjectName,
        [Parameter(Mandatory = $true)][string]$groupName,
        [Parameter(Mandatory = $true)][string[]]$assessmentName
    )
    $headers = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'
    $headers.Add("Authorization", "Bearer $Token")

    #Get Assessment download URL and export each of the assessment reports in .xlsx files
    if($assessmentName){
        [int]$i = 0
        $assessmentName | ForEach-Object {

            ##Get assessment URL to check assessment status before downloading the assessment report
            $AssessmentGetURL = "https://management.azure.com/subscriptions/"+$subscriptionId+"/resourceGroups/"+$resourceGroupName+"/providers/Microsoft.Migrate/assessmentprojects/"+$assessmentProjectName+"/groups/"+$groupName+"/assessments/"+$assessmentName[$i]+"?api-version=2019-05-01"
    
            #Check assessment status
            ##GET https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/assessmentProjects/{projectName}/groups/{groupName}/assessments/{assessmentName}?api-version=2019-10-01
            do{
               # Write-Host "Checking status to download assessment:$assessmentName[$i]..."
                Start-Sleep -s 20
                
                ##Get assessment to check status before downloading the assessment report
                $responseAssessmentList = Invoke-RestMethod -ContentType "$global:contentType" -Uri $AssessmentGetURL -Method "GET" -Headers $headers

                ##Get assessment to check status before downloading the assessment report
                if($responseAssessmentList.properties.status -eq "Completed"){
                    ###Download link for assessment
                    ###POST https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/assessmentProjects/{projectName}/groups/{groupName}/assessments/{assessmentName}/downloadUrl?api-version=2019-10-01
                    $assessmentDownloadURL = "https://management.azure.com/subscriptions/"+$subscriptionId+"/resourceGroups/"+$resourceGroupName+"/providers/Microsoft.Migrate/assessmentprojects/"+$assessmentProjectName+"/groups/"+$groupName+"/assessments/"+$assessmentName[$i]+"/downloadUrl?api-version=2019-05-01"
                    try{
                        $assessmentDownload = Invoke-RestMethod -ContentType "$global:contentType" -Uri $assessmentDownloadURL -Method "POST" -Headers $headers
                        $fileName = ".\"+$assessmentName[$i] + ".xlsx"
                        #### Download assessment report from the URL as a .xlsx file
                        Invoke-WebRequest -uri $assessmentDownload.assessmentReportUrl -OutFile $fileName
                        Write-Host "Download completed for assessment: "$assessmentName[$i]
                    }
                    catch{
                        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
                        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
                    }
                }
            }while($responseAssessmentList.properties.status -ne "Completed")
            $i = $i+1
        }
    return $null
    }
}

<#
.SYNOPSIS
Returns a bearer token for the currently logged in Azure user's context.
.DESCRIPTION
The Get-AccessToken cmdlet returns a bearer token for the currently logged in Azure user's context for use when calling Azure REST APIs.
.EXAMPLE
Get a bearer token for the current user's context
Get-AccessToken
#>
function Get-AccessToken()
{
    $ErrorActionPreference = 'Stop'

    if(-not (Get-Module Az.Accounts)) {
        Import-Module Az.Accounts
    }
    $Profile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $currentAzureContext = Get-AzContext
    if(!$currentAzureContext) {
        Write-Error "Please ensure that you have logged in to your Azure account before calling this function."
    }
    $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($Profile)
    $token = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)
    $token.AccessToken
}

<#
.SYNOPSIS
Returns all Azure Migrate projects within a specified Azure subscription.
.DESCRIPTION
The Get-AzMigrateProject cmdlet returns all Azure Migrate projects from a specified subscription.
.PARAMETER Token
Specifies an authentication token to use when retrieving information from Azure.
.PARAMETER SubscriptionID
Specifies the Azure subscription to query.
.EXAMPLE
Get all Azure Migrate projects within a specific Azure subscription.
PS C:\>Get-AzureMigrateProject -Token $token -SubscriptionID 45916f92-e9c3-4ed2-b8c2-d87aa129905f

.NOTES
TBD:
1. Consider returning 1 or multiple projects.
2. Return more meaningful object by extracting values from properties of a project.
3. Discern and return the displayname or a project as well as the internal name/ID.
#>
function Get-AzureMigrateAssessmentProject {
    [CmdletBinding()]
    Param(
      #  [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$resourceGroupName,
        [Parameter(Mandatory = $true)][string]$SubscriptionID
    )
    $token = Get-AccessToken
    $url = "https://management.azure.com/subscriptions/"+$SubscriptionID+ "/resourcegroups/"+$resourceGroupName+"/providers/Microsoft.Migrate/assessmentProjects?api-version=2019-10-01" 

    $headers = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'
    $headers.Add("Authorization", "Bearer $token")

    $response = Invoke-RestMethod -Uri $url -Headers $headers -ContentType "$global:contentType" -Method "GET" 
    return $response.value

}

<#
.SYNOPSIS
Gets group details based on group name in the specified Azure Migrate project within a specified Azure subscription.
.DESCRIPTION
The Get-Group cmdlet gets the group based on group name in the specified Azure Migrate project
.PARAMETER token
Specifies the Azure authentication token.
.PARAMETER subscriptionId
Specifies the Azure subscription to query.
.PARAMETER resourceGroupName
Specifies the Azure Resource Group to query.
.PARAMETER assessmentProjectName
Specifies the Azure Migrate assessment project to query.
.PARAMETER groupName
Specifies the group name to query.
.EXAMPLE
Get the group with group name All_machines
PS C:\Assessment_Utility> New-AssessmentCreation -subscriptionId "4bd2aa0f-2bd2-4d67-91a8-5a4533d58600" -resourceGroupName "rajosh-rg" -assessmentProjectName "rajoshSelfHost-Physical92c3project" -groupName "All_machines"

.NOTES
1. The function returns an object with group details.
#>
function Get-Group {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][string]$token,
        [Parameter(Mandatory = $true)][string]$subscriptionId,
        [Parameter(Mandatory = $true)][string]$resourceGroupName,
        [Parameter(Mandatory = $true)][string]$assessmentProjectName,
        [Parameter(Mandatory = $true)][string]$groupName
    )
    $headers = New-Object 'System.Collections.Generic.Dictionary[[string],[string]]'
    $headers.Add("Authorization", "Bearer $Token")
    
    #Get Group as per the group name specified in parameters
    ##GET https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Migrate/assessmentProjects/{projectName}/groups/{groupName}?api-version=2019-10-01
    try{
        $group = Invoke-RestMethod -ContentType "$global:contentType" -Uri $groupURI -Method "GET" -Headers $headers
    }
    catch{
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
    }
    return $group
}    
