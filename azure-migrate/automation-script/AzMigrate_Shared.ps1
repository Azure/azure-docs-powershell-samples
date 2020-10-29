class AzMigrate_Shared
{
    [psobject]$Logger

    AzMigrate_Shared($logger)
    {
        $this.Logger = $logger
    }


    #Setting version information which can be leveraged for making appropriate REST API call
    $AMH_APIVERSION = "?api-version=2018-09-01-preview"
    $SDS_APIVERSION = "?api-version=2020-01-01"
    $SAS_APIVERSION = "?api-version=2019-10-01"
    $RSV_APIVERSION = "?api-version=2018-07-10"

    [psobject] GetRequestPropertiesForAPICalls()
    {        
        if(-not (Get-Module Az.Accounts)) {
            Import-Module Az.Accounts
        }
        
        $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
        if(-not $azProfile.Accounts.Count) {
            $this.Logger.LogError("Ensure you have logged in before calling GetRequestProperties")
            return $null
        }

        $currentAzureContext = Get-AzContext
        if (-not $currentAzureContext) {
            $this.Logger.LogError("Not logged in. Use Connect-AzAccount to log in")
            return $null
        }
        $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azProfile)
        $SubscriptionId = $currentAzureContext.Subscription.Id
        if (-not $SubscriptionId) {
            $this.Logger.LogError("No subscription selected. Make sure that the csv processor's EnsureSubscription has run before this")
            return $null
        }
        $this.Logger.LogTrace("Getting access token for tenant: '$($currentAzureContext.Tenant.TenantId)'")
        
        $Result = $profileClient.AcquireAccessToken($currentAzureContext.Tenant.TenantId)        

        #setting the Authorizationheaders from the AccessToken 
        $AuthorizationHeader = "Bearer " + $Result.AccessToken
        $Headers = [ordered]@{Accept = "application/json"; Authorization = $AuthorizationHeader} 
        
        #returns the Name value pair for SubscriptionID, Headers including Authorization->Bearer Token and a base URL
        return [ordered]@{
                    SubscriptionId = $SubscriptionId
                    Headers = $Headers
                    baseurl = "https://management.azure.com"
                    }   
    }


    [psobject] GetAzMigAssessmentDetails(
            [string]$MigrateProjectId,
            [string]$GroupName,
            [string]$AssessmentName,
            [string]$DiscoveredServerId)
    {
        #region Validation-Errorlogging
        if ([string]::IsNullOrEmpty($MigrateProjectId)) {
            $this.Logger.LogError("Azure Migrate ProjectID is not specified")
            return $null
        }
        if ([string]::IsNullOrEmpty($GroupName)) {
            $this.Logger.LogError("Azure Migrate Group Name is not specified")
            return $null
        }
        if ([string]::IsNullOrEmpty($AssessmentName)) {
            $this.Logger.LogError("Azure Migrate Assessment Name is not specified")
            return $null
        }
        if ([string]::IsNullOrEmpty($DiscoveredServerId)) {
            $this.Logger.LogError("Azure Migrate Discover ServerID is not specified")
            return $null
        }
        #endregion

        #Call GetRequestProperties to get the required information and token to make the RESTAPI call
        $Properties = $this.GetRequestPropertiesForAPICalls()
    
        #Get all Server Assessment Solution for a specific project ID
        $requesturi = $Properties['baseurl'] + $MigrateProjectId + "/solutions/Servers-Assessment-ServerAssessment" + $this.AMH_APIVERSION;
        $this.Logger.LogTrace("Trying to get an assessment solution with requesturi as '$($requesturi)'")
        
        $response = $null
        $response = Invoke-Restmethod -Method Get -Headers $Properties['Headers'] $requesturi;
        if (-not $response) {
            $this.Logger.LogError("Server Assessment Solution not added to the project")
            return $null
        }
    
        #Get Assessment Project corresponding to this assessment done for ProjectID
        $Assessmentsolution = $response
        $AssessmentProject = $Assessmentsolution.properties.details.extendedDetails.projectId
        $this.Logger.LogTrace("Assessment ProjecID: '$($AssessmentProject)'")
    
        $AssessedMachine = $null
        if($AssessmentProject) {
            #Get all Assessed Server/machines information for a particular group name and assessment name that is passed in as an argument
            $requesturi = $Properties['baseurl'] + $AssessmentProject + '/groups/' + $GroupName + '/assessments/' + $AssessmentName + '/assessedmachines' + $this.SAS_APIVERSION
            $this.Logger.LogTrace("Trying to get assessment details for machine with requesturi as '$($requesturi)'")
            $response = $null
            $response = Invoke-Restmethod -Method Get -Headers $Properties['Headers'] $requesturi;
            if (-not $response) {
                $this.Logger.LogError("Failed to get Assessment details")
                return $null
            }
    
            #Get Machine specific assement details for Server/VM which is passed in as an argument
            foreach ($machine in $response.value) {
                if($machine.properties.datacenterMachineArmId -ne $DiscoveredServerId) {
                    continue;
                } else {
                    $AssessedMachine = $machine;
                    break;
                }
            }
                
            while ((-not $AssessedMachine) -and $response.nextLink) {
                $response = Invoke-Restmethod -Method Get -Headers $Properties['Headers'] $response.nextLink
                if (-not $response) {
                    $this.Logger.LogError("Failed to get Assessment details")
                    return $null
                }
                foreach ($machine in $response.value) {
                    if($machine.properties.datacenterMachineArmId -ne $DiscoveredServerId) {
                        continue;
                    } else {
                        $AssessedMachine = $machine;
                        break;
                    }
                }
            }
        }
    
        #return Assessment details for specific machine/server/VM
        return $AssessedMachine        
    }


    [psobject] GetDiscoveredServer([string] $AzMigrateResourceGroupName,
                                        [string] $AzMigrateProjectName,
                                        [string] $machineName)
    {
        #region Validation-Errorlogging
        if ([string]::IsNullOrEmpty($AzMigrateResourceGroupName)) {
            $this.Logger.LogError("Azure Migrate Resource Group Name is not specified")            
        }
        if ([string]::IsNullOrEmpty($AzMigrateProjectName)) {
            $this.Logger.LogError("Azure Migrate Project Name is not specified")
        }
        if ([string]::IsNullOrEmpty($machineName)) {
            $this.Logger.LogError("Azure machine name is not specified")
        }
        #endregion

        $DiscoveredServer = $null
        # Get a specific Discovered VM in an Azure Migrate project
        $DiscoveredServer = Get-AzMigrateDiscoveredServer -ProjectName $AzMigrateProjectName `
                                                        -ResourceGroupName $AzMigrateResourceGroupName `
                                                        -DisplayName $machineName

        if (-not $DiscoveredServer)
        {
            $this.Logger.LogTrace("Discovery Details for the Server could not be retrieved for '$($AzMigrateResourceGroupName)-$($AzMigrateProjectName)-$($machineName)'")
        }

        return $DiscoveredServer

    }

    [psobject] GetReplicationServer([string] $AzMigrateResourceGroupName,
                                        [string] $AzMigrateProjectName,
                                        [string] $machineName)
    {
        
        #region Validation-Errorlogging
        if ([string]::IsNullOrEmpty($AzMigrateResourceGroupName)) {
            $this.Logger.LogError("Azure Migrate Resource Group Name is not specified")            
        }
        if ([string]::IsNullOrEmpty($AzMigrateProjectName)) {
            $this.Logger.LogError("Azure Migrate Project Name is not specified")
        }
        if ([string]::IsNullOrEmpty($machineName)) {
            $this.Logger.LogError("Azure machine name is not specified")
        }
        #endregion

        $DiscoveredServerMachine = $null
        # Get a specific Discovered VM in an Azure Migrate project
        $DiscoveredServerMachine = $this.GetDiscoveredServer($AzMigrateResourceGroupName, $AzMigrateProjectName, $machineName)
        

        $ReplicatingServer = $null
        try {
            # Retrieve the replicating VM details by using the discovered VM identifier
            $ReplicatingServer = Get-AzMigrateServerReplication -DiscoveredMachineId $DiscoveredServerMachine.ID
        }
        catch {
            $this.Logger.LogError("Replication Server is not available. This might be due to where replication was not started at all OR Migration and cleanup activity was done for '$($AzMigrateResourceGroupName)-$($AzMigrateProjectName)-$($machineName)'")
        }
        
        if (-not $ReplicatingServer)
        {
            $this.Logger.LogTrace("Azure Migrate Replicating Server could not be retrieved for '$($AzMigrateResourceGroupName)-$($AzMigrateProjectName)-$($machineName)'")
        }

        return $ReplicatingServer
    }

    [psobject] GetReplicationServerList([string] $AzMigrateResourceGroupName,
                                        [string] $AzMigrateProjectName)
    {
        
        #region Validation-Errorlogging
        if ([string]::IsNullOrEmpty($AzMigrateResourceGroupName)) {
            $this.Logger.LogErrorAndThrow("Azure Migrate Resource Group Name is not specified")
        }
        if ([string]::IsNullOrEmpty($AzMigrateProjectName)) {
            $this.Logger.LogErrorAndThrow("Azure Migrate Project Name is not specified")
        }
        #endregion

        $ReplicatingServerList = Get-AzMigrateServerReplication `
                                    -ProjectName $AzMigrateProjectName -ResourceGroupName $AzMigrateResourceGroupName
        
        if (-not $ReplicatingServerList)
        {
            $this.Logger.LogTrace("Azure Migrate Replicating Server List could not be retrieved for '$($AzMigrateResourceGroupName)-$($AzMigrateProjectName)'")
        }
        return $ReplicatingServerList
    }
}

Function New-AzMigrate_SharedInstance($Logger)
{
  return [AzMigrate_Shared]::new($Logger)
}
