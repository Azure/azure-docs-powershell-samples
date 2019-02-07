class AsrCommon
{
    [psobject]$Logger

    AsrCommon($logger)
    {
        $this.Logger = $logger
    }

    [psobject] GetAndEnsureVaultContext($vaultName)
    {
        $this.Logger.LogTrace("Ensuring services vault context '$($vaultName)'")
        $targetVault = Get-AzureRmRecoveryServicesVault -Name $vaultName
        if ($targetVault -eq $null)
        {
            $this.Logger.LogError("Vault with name '$($vaultName)' unable to find")
        }
        Set-AzureRmRecoveryServicesAsrVaultContext -Vault $targetVault
        return $targetVault
    }

    [psobject] GetFabricServer($sourceConfigurationServer)
    {
        $this.Logger.LogTrace("Getting fabric server for configuration server '$($sourceConfigurationServer)'")
        $fabricServer = Get-AzureRmRecoveryServicesAsrFabric -FriendlyName $sourceConfigurationServer
        return $fabricServer
    }

    [psobject] GetProtectionContainer($fabricServer)
    {
        $this.Logger.LogTrace("Getting protection container reference for fabric server '$($fabricServer.Name)-$($fabricServer.FriendlyName)'")
        $protectionContainer = Get-AzureRmRecoveryServicesAsrProtectionContainer -Fabric $fabricServer
        return $protectionContainer
    }

    [psobject] GetProtectableItem($protectionContainer, $sourceMachineName)
    {
        $this.Logger.LogTrace("Getting protectable item reference '$($sourceMachineName)'")
        $protectableVM = Get-AzureRmRecoveryServicesAsrProtectableItem `
            -ProtectionContainer $protectionContainer `
            -FriendlyName $sourceMachineName
        return $protectableVM
    }

    [psobject] GetProtectedItem($protectionContainer, $sourceMachineName)
    {
        $this.Logger.LogTrace("Getting protected item reference '$($sourceMachineName)'")
        $protectedItem = Get-AzureRmRecoveryServicesAsrReplicationProtectedItem `
            -ProtectionContainer $protectionContainer `
            -FriendlyName $sourceMachineName
        return $protectedItem
    }

    [psobject] GetProtectedItemFromVault($vaultName, $sourceMachineName, $sourceConfigurationServer) {

        $vaultServer = $this.GetAndEnsureVaultContext($vaultName)
        $fabricServer = $this.GetFabricServer($sourceConfigurationServer)
        $protectionContainer = $this.GetProtectionContainer($fabricServer)
        $protectableVM = $this.GetProtectableItem($protectionContainer, $sourceMachineName)
    
        $this.Logger.LogTrace("ProtectableStatus: '$($protectableVM.ProtectionStatus)'")
    
        if ($protectableVM.ReplicationProtectedItemId -ne $null) {
            $protectedItem = $this.GetProtectedItem($protectionContainer, $sourceMachineName)
    
            $this.Logger.LogTrace("ProtectionState: '$($protectedItem.ProtectionState)'")
            $this.Logger.LogTrace("ProtectionDescription: '$($protectedItem.ProtectionStateDescription)'")
    
            return $protectedItem
        } else {
            $this.Logger.LogTrace("'$($sourceMachineName)' protectable item is not in a protected state ready for replication")
    
            return $null
        }        
    }
}

Function New-AsrCommonInstance($Logger)
{
  return [AsrCommon]::new($Logger)
}
