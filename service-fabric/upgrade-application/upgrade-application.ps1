## Variables
$ApplicationPackagePath = "C:\Users\sfuser\documents\visual studio 2017\Projects\Voting\Voting\pkg\Debug"
$ApplicationName = "fabric:/Voting"
$ApplicationTypeName = "VotingType"
$ApplicationTypeVersion = "1.3.0"
$imageStoreConnectionString = "fabric:ImageStore"
$CopyPackageTimeoutSec = 600
$CompressPackage = $false


## Check existence of the application
$oldApplication = Get-ServiceFabricApplication -ApplicationName $ApplicationName
        
if (!$oldApplication)
{
    $errMsg = "Application '$ApplicationName' doesn't exist in cluster."
    throw $errMsg
}
else
{
    ## Check upgrade status
    $upgradeStatus = Get-ServiceFabricApplicationUpgrade -ApplicationName $ApplicationName
    if ($upgradeStatus.UpgradeState -ne "RollingBackCompleted" -and $upgradeStatus.UpgradeState -ne "RollingForwardCompleted" -and $upgradeStatus.UpgradeState -ne "Failed")
    {
        $errMsg = "An upgrade for the application '$ApplicationTypeName' is already in progress."
        throw $errMsg
    }

    $reg = Get-ServiceFabricApplicationType -ApplicationTypeName $ApplicationTypeName | Where-Object  { $_.ApplicationTypeVersion -eq $ApplicationTypeVersion }
    if ($reg)
    {
        Write-Host 'Application Type '$ApplicationTypeName' and Version '$ApplicationTypeVersion' was already registered with Cluster, unregistering it...'
        $reg | Unregister-ServiceFabricApplicationType -Force
    }

    ## Copy application package to image store
    $applicationPackagePathInImageStore = $ApplicationTypeName
    Write-Host "Copying application package to image store..."
    Copy-ServiceFabricApplicationPackage -ApplicationPackagePath $ApplicationPackagePath -ImageStoreConnectionString $imageStoreConnectionString -ApplicationPackagePathInImageStore $applicationPackagePathInImageStore -TimeOutSec $CopyPackageTimeoutSec -CompressPackage:$CompressPackage 
    if(!$?)
    {
        throw "Copying of application package to image store failed. Cannot continue with registering the application."
    }
    
    ## Register application type
    Write-Host "Registering application type..."
    Register-ServiceFabricApplicationType -ApplicationPathInImageStore $applicationPackagePathInImageStore
    if(!$?)
    {
        throw "Registration of application type failed."
    }

    # Remove the application package to free system resources.
    Remove-ServiceFabricApplicationPackage -ImageStoreConnectionString $imageStoreConnectionString -ApplicationPackagePathInImageStore $applicationPackagePathInImageStore
    if(!$?)
    {
        Write-Host "Removing the application package failed."
    }
        
    ## Start monitored application upgrade
    try
    {
        Write-Host "Start upgrading application..." 
        Start-ServiceFabricApplicationUpgrade -ApplicationName $ApplicationName -ApplicationTypeVersion $ApplicationTypeVersion -HealthCheckStableDurationSec 60 -UpgradeDomainTimeoutSec 1200 -UpgradeTimeout 3000 -FailureAction Rollback -Monitored
    }
    catch
    {
        Write-Host ("Error starting upgrade. " + $_)

        Write-Host "Unregister application type '$ApplicationTypeName' and version '$ApplicationTypeVersion' ..."
        Unregister-ServiceFabricApplicationType -ApplicationTypeName $ApplicationTypeName -ApplicationTypeVersion $ApplicationTypeVersion -Force
        throw
    }

    do
    {
        Write-Host "Waiting for upgrade..."
        Start-Sleep -Seconds 3
        $upgradeStatus = Get-ServiceFabricApplicationUpgrade -ApplicationName $ApplicationName
    } while ($upgradeStatus.UpgradeState -ne "RollingBackCompleted" -and $upgradeStatus.UpgradeState -ne "RollingForwardCompleted" -and $upgradeStatus.UpgradeState -ne "Failed")
    
    if($upgradeStatus.UpgradeState -eq "RollingForwardCompleted")
    {
        Write-Host "Upgrade completed successfully."
    }
    elseif($upgradeStatus.UpgradeState -eq "RollingBackCompleted")
    {
        Write-Error "Upgrade was Rolled back."
    }
    elseif($upgradeStatus.UpgradeState -eq "Failed")
    {
        Write-Error "Upgrade Failed."
    }
}