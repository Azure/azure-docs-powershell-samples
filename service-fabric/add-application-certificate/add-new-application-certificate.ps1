
# Variables for common values.
$clusterloc="SouthCentralUS"
$groupname="mysfclustergroup"
$clustername = "mysfcluster"
$vaultname = "mykeyvault"
$subname="$clustername.$clusterloc.cloudapp.azure.com"

# Certificate variables.
$appcertpwd = ConvertTo-SecureString -String 'Password#1234' -AsPlainText -Force
$appcertfolder="c:\myappcertificates\"

# Create a new self-signed certificate and add it to all the VMs in the cluster.
Add-AzureRmServiceFabricApplicationCertificate -ResourceGroupName $groupname -Name $clustername `
    -KeyVaultName $vaultname `-KeyVaultResouceGroupName $groupname -CertificateSubjectName $subname 
    -CertificateOutputFolder $appcertfolder -CertificatePassword $appcertpwd