#Variables for common values
$ResourceGroupName = "ResourceGroup01"
$SubscriptionID = "SubscriptionID"
$WorkspaceName = "DefaultWorkspace-" + (Get-Random -Maximum 99999) + "-" + $ResourceGroupName
$Location = "eastus"

# Stop the script if any errors occur
$ErrorActionPreference = "Stop"

# Connect to the current Azure account
Write-Output "Pulling Azure account credentials..."

# Login to Azure account
$Account = Add-AzureRmAccount

# If a subscriptionID has not been provided, select the first registered to the account
if ([string]::IsNullOrEmpty($SubscriptionID)) {
   
    # Get a list of all subscriptions
    $Subscription =  Get-AzureRmSubscription

    # Get the subscription ID
    $SubscriptionID = (($Subscription).SubscriptionId | Select -First 1).toString()

    # Get the tenant id for this subscription
    $TenantID = (($Subscription).TenantId | Select -First 1).toString()

} else {

    # Get a reference to the current subscription
    $Subscription = Get-AzureRmSubscription -SubscriptionId $SubscriptionID
    # Get the tenant id for this subscription
    $TenantID = $Subscription.TenantId
}

# Set the active subscription
$null = Set-AzureRmContext -SubscriptionID $SubscriptionID

# Check that the resource group is valid
$null = Get-AzureRmResourceGroup -Name $ResourceGroupName
# Create a new OMS workspace if needed
try {

    $Workspace = Get-AzureRmOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $ResourceGroupName  -ErrorAction Stop
    $ExistingtLocation = $Workspace.Location
    Write-Output "Workspace named $WorkspaceName in region $ExistingLocation already exists."
	Write-Output "No further action required, script quitting."

} catch {

    Write-Output "Creating new workspace named $WorkspaceName in region $Location..."
    # Create the new workspace for the given name, region, and resource group
    $Workspace = New-AzureRmOperationalInsightsWorkspace -Location $Location -Name $WorkspaceName -Sku Standard -ResourceGroupName $ResourceGroupName

}


