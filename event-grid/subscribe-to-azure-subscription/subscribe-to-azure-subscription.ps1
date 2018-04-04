# Provide an endpoint for handling the events.
$myEndpoint = "<endpoint URL>"

# Select the Azure subscription you want to subscribe to.
Set-AzureRmContext -Subscription "Contoso Subscription"

# Subscribe to the Azure subscription. The command creates the subscription for the currently selected Azure subscription. 
New-AzureRmEventGridSubscription -Endpoint $myEndpoint -EventSubscriptionName demoSubscriptionToAzureSub