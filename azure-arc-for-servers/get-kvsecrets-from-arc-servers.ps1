# run the following on your Azure ARC machines to get secrets from you Key Vault
function Get-AccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $audience,
        [string] $apiVersion = '2019-08-15'
    )

    $azcmagent = azcmagent show
    if (-not ($azcmagent -like "*: Connected"))
    {
        Write-Error 'Ensure Azure Arc machine is onboarded and himds sevice is running.'
        return
    }
        
    $identityEndpoint = $env:IDENTITY_ENDPOINT
    if(-not ($identityEndpoint)) {
        $identityEndpoint = 'http://localhost:40342/metadata/identity/oauth2/token'
    }

    $endpointUri = "{0}?resource={1}&api-version={2}" -f $identityEndpoint, $audience, $apiVersion
    $args = @{
        'Method' = 'GET';
        'Headers' = @{metadata='true'};
        'Uri' = $endpointUri;
    }

    $response = Invoke-WebRequest @args -SkipHttpErrorCheck
    if (!$response)
    {
        throw "something went wrong during requesting to identity service."
    }
    if ($response.StatusCode -ne '401')
    {
        throw "unexpected response code from Azure Arc agent. Response content: $response.Content"
    }
    #check response code
    $challenge = $response.Headers['WWW-Authenticate']
    $secretFile = if ($challenge -match "Basic realm=.+") {($challenge -split "Basic realm=")[1]}
    if (!$secretFile)
    {
        throw "something went wrong during requesting to identity service. Resposne content: $response.Content" 
    }

    $secret = Get-Content -Raw $secretFile
    $args = @{
        'Method' = 'GET';
        'Headers' = @{metadata='true'; Authorization="Basic $secret"};
        'Uri' = $endpointUri;
    }

    $response = Invoke-WebRequest @args
    if ($response -and $response.StatusCode -eq '200')
    {
       return (ConvertFrom-Json -InputObject $response.Content).access_token
    }
}

# try to access your keyvault. If you got access denied, run grant-permission.ps1 to grant permission to your machine
try 
{
    $kvtoken = Get-AccessToken -apiVersion "2019-08-15" -audience "https://vault.azure.net"
} catch {
    Write-Error $_
    return
}

# connect to your Key Vault
$kvendpoint = "https://<yourKeyVault>.vault.azure.net/secrets/mysecret/b9f60f97d20545f18c0552460af2f822?api-version=7.0"
$response = Invoke-RestMethod -Method Get -Uri $kvendpoint -Headers @{ Authorization="Bearer $kvtoken"}
if ($response)
{
    # retrieve the secrects stored in your KeyVault
    $response.value
}
else 
{
    Write-Error "Failed in accessing Key Vault. Response received: $response"
}
