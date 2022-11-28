$fqdn="<Replace with your custom domain name>"
$webappname="mywebapp$(Get-Random)"
$location="West Europe"

# Create a resource group.
New-AzResourceGroup -Name $webappname -Location $location

# Create an App Service plan in Free tier.
New-AzAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName $webappname -Tier Free

# Create a web app.
$webapp = New-AzWebApp -Name $webappname -Location $location -AppServicePlan $webappname `
-ResourceGroupName $webappname

Write-Host "Sign in to your domain provider's website and configure the following records:"
Write-Host "A CNAME record that maps $fqdn to $webappname.azurewebsites.net"
Write-Host "A TXT record that maps asuid.$fqdn to the domain verification ID $($webapp.CustomDomainVerificationId)"
Read-Host "Press [Enter] key when ready ..."

# Before continuing, go to your DNS configuration UI for your custom domain and follow the 
# instructions at https://aka.ms/appservicecustomdns to configure a CNAME record for the 
# hostname "www" and point it your web app's default domain name.

# Upgrade App Service plan to Shared tier (minimum required by custom domains)
Set-AzAppServicePlan -Name $webappname -ResourceGroupName $webappname `
-Tier Shared

# Add a custom domain name to the web app. 
Set-AzWebApp -Name $webappname -ResourceGroupName $webappname `
-HostNames @($fqdn,"$webappname.azurewebsites.net")
