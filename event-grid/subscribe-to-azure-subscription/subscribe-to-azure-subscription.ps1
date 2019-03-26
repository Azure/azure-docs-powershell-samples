# Provide an endpoint for handling the events. Must be formatted "https://your-endpoint-URL"
$myEndpoint = "<your-endpoint-URL>"

# Select the Azure subscription you want to subscribe to. You need this command only if the 
# current subscription is not the one you wish to subscribe to.
Set-AzContext -Subscription "<subscription-name-or-ID>"

# Subscribe to the Azure subscription. The command creates the subscription for the currently selected Azure subscription. 
New-AzEventGridSubscription -Endpoint $myEndpoint -EventSubscriptionName demoSubscriptionToAzureSub
