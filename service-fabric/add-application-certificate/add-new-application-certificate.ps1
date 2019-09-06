
# Variables for common values.
$clusterloc="SouthCentralUS"
$groupname="mysfclustergroup"
$clustername = "mysfcluster"
$vaultname = "mykeyvault"
$subname="$clustername.$clusterloc.cloudapp.azure.com"
$subscriptionID = 'subscription ID'

# Login and select your subscription
Connect-AzAccount
Get-AzSubscription -SubscriptionId $subscriptionID | Select-AzSubscription

# Certificate variables.
$appcertpwd = ConvertTo-SecureString -String 'Password#1234' -AsPlainText -Force
$appcertfolder="c:\myappcertificates\"

# Create a new self-signed certificate and add it to all the VMs in the cluster.
Add-AzServiceFabricApplicationCertificate -ResourceGroupName $groupname -Name $clustername `
    -KeyVaultName $vaultname -KeyVaultResouceGroupName $groupname -CertificateSubjectName $subname `
    -CertificateOutputFolder $appcertfolder -CertificatePassword $appcertpwd