function New-HDInsightAndVNet {
    # Script should stop on failures
    $ErrorActionPreference = "Stop"

    # Login to your Azure subscription
    $context = Get-AzContext
    if ($context -eq $null)  {
        Connect-AzAccount
    }
    $context

    # If you have multiple subscriptions, uncomment the following
    # and use it to set the subscription used in this script
    # Select-AzSubscription -SubscriptionName "Name of subscription"

    # Prompt for the information
    $resourceGroupName = Read-Host -Prompt "Enter the Azure Resource Group name"
    $location = Read-Host -Prompt "Enter the Azure region to use"
    $networkName = Read-Host -Prompt "Enter the name of the virtual network"
    $storageName = Read-Host -Prompt "Enter the storage account name"
    $clusterName = Read-Host -Prompt "Enter the HDInsight cluster name"
    # Prompt for HDInsight credentials
    $adminCreds = Get-Credential -Message "Enter the HTTPS user name and password for the HDInsight cluster" -UserName "admin"
    $sshCreds = Get-Credential -Message "Enter the SSH user name and password for the HDInsight cluster" -UserName "sshuser"
    
    # Set some values
    $defaultContainerName = $clusterName
    $hdiWorkerNodes = 4
    $hdiVersion = "3.5"
    $hdiType = "Hadoop"
    
    # Network settings
    $defaultSubnetName = "default"
    $networkAddressPrefix = "10.0.0.0/16"
    $defaultSubnetPrefix = "10.0.0.0/24"

    # Create the resource group that will contain everything
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    # Create the subnet configuration
    $defaultSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $defaultSubnetName `
        -AddressPrefix $defaultSubnetPrefix

    # Create the subnet
    New-AzVirtualNetwork -Name $networkName `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -AddressPrefix $networkAddressPrefix `
        -Subnet $defaultSubnetConfig

    # Get the network & subnet that were created
    $network = Get-AzVirtualNetwork -Name $networkName `
        -ResourceGroupName $resourceGroupName

    $defaultSubnet = Get-AzVirtualNetworkSubnetConfig -Name $defaultSubnetName `
        -VirtualNetwork $network

    # Create the storage account
    New-AzStorageAccount `
        -ResourceGroupName $resourceGroupName `
        -Name $storageName `
        -Type Standard_GRS `
        -Location $location

    # Get the storage account keys and create a context
    $defaultStorageKey = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName `
        -Name $storageName)[0].Value
    $storageContext = New-AzStorageContext -StorageAccountName $storageName `
        -StorageAccountKey $defaultStorageKey

    # Create the default storage container
    New-AzStorageContainer -Name $defaultContainerName `
        -Context $storageContext

    # Create the HDInsight cluster
    New-AzHDInsightCluster `
        -ResourceGroupName $resourceGroupName `
        -ClusterName $clusterName `
        -Location $location `
        -ClusterSizeInNodes $hdiWorkerNodes `
        -ClusterType $hdiType `
        -OSType Linux `
        -Version $hdiVersion `
        -HttpCredential $adminCreds `
        -SshCredential $sshCreds `
        -DefaultStorageAccountName "$storageName.blob.core.windows.net" `
        -DefaultStorageAccountKey $defaultStorageKey `
        -DefaultStorageContainer $defaultContainerName `
        -VirtualNetworkId $network.Id `
        -SubnetName $defaultSubnet.Id
}

function New-VPNGateway {
    # Prompt for the information
    $resourceGroupName = Read-Host -Prompt "Enter the Azure Resource Group name"
    $location = Read-Host -Prompt "Enter the Azure region to use"
    $networkName = Read-Host -Prompt "Enter the name of the virtual network"
    $rootCert = Read-Host -Prompt "Enter the path to the VPN root certificate"

    # Network settings
    $defaultSubnetName = "default"
    $networkAddressPrefix = "10.0.0.0/16"
    $gatewaySubnetPrefix = "10.0.1.0/24"
    $vpnClientAddressPool = "172.16.201.0/24"
    $gatewaySubnetName = "GatewaySubnet"
    $gatewayPublicIpName = "GatewayIp"
    $gatewayIpConfigName = "GatewayConfig"
    $vpnRootCertName = "rootcert"
    $vpnName = "VPNGateway"

    # Get the certificate info
    # Get the full path in case a relative path was passed
    $rootCertFile = Get-ChildItem $rootCert
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($rootCertFile)
    $certBase64 = [System.Convert]::ToBase64String($cert.RawData)
    $p2sRootCert = New-AzVpnClientRootCertificate `
        -Name $vpnRootCertName `
        -PublicCertData $certBase64
    
    # Create the subnet configuration
    $defaultSubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $defaultSubnetName `
        -AddressPrefix $defaultSubnetPrefix
    $gatewaySubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $gatewaySubnetName `
        -AddressPrefix $gatewaySubnetPrefix

    # Create the subnet
    New-AzVirtualNetwork -Name $networkName `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -AddressPrefix $networkAddressPrefix `
        -Subnet $defaultSubnetConfig, $gatewaySubnetConfig

    # Get the network & subnet that were created
    $network = Get-AzVirtualNetwork -Name $networkName `
        -ResourceGroupName $resourceGroupName
    $gatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name $gatewaySubnetName `
        -VirtualNetwork $network
    $defaultSubnet = Get-AzVirtualNetworkSubnetConfig -Name $defaultSubnetName `
        -VirtualNetwork $network

    # Set a dynamic public IP address for the gateway subnet
    $gatewayPublicIp = New-AzPublicIpAddress -Name $gatewayPublicIpName `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -AllocationMethod Dynamic

    $gatewayIpConfig = New-AzVirtualNetworkGatewayIpConfig -Name $gatewayIpConfigName `
        -Subnet $gatewaySubnet `
        -PublicIpAddress $gatewayPublicIp

    # Create the VPN gateway
    New-AzVirtualNetworkGateway -Name $vpnName `
        -ResourceGroupName $resourceGroupName `
        -Location $location `
        -IpConfigurations $gatewayIpConfig `
        -GatewayType Vpn `
        -VpnType RouteBased `
        -EnableBgp $false `
        -GatewaySku Standard `
        -VpnClientAddressPool $vpnClientAddressPool `
        -VpnClientRootCertificates $p2sRootCert

    # Get the URI for the the Windows VPN client installer download
    Get-AzVpnClientPackage -ResourceGroupName $resourceGroupName `
        -VirtualNetworkGatewayName $vpnName `
        -ProcessorArchitecture Amd64
}
