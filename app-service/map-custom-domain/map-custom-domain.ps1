$fqdn="<Replace with your custom domain name>"
$webappname="mywebapp$(Get-Random)"
$location="West Europe"

# Create a resource group.
New-AzureRmResourceGroup -Name $webappname -Location $location

# Create an App Service plan in Free tier.
New-AzureRmAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName $webappname -Tier Free

# Create a web app.
New-AzureRmWebApp -Name $webappname -Location $location -AppServicePlan $webappname `
-ResourceGroupName $webappname

# Upgrade App Service plan to Shared tier (minimum required by custom domains)
Set-AzureRmAppServicePlan -Name $webappname -ResourceGroupName $webappname `
-Tier Shared

# Add a custom domain name to the web app. 
Set-AzureRmWebApp -Name $webappname -ResourceGroupName $webappname `
-HostNames $fqdn,$webappname.azurewebsites.net
