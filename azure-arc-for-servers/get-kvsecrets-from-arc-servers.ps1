# run the following on your Azure ARC machines to get secrets from you Key Vault
function Get-AccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $audience,
        [string] $apiVersion = "2019-08-15"
    )

    $azcmagent = azcmagent show
    if (-not ($azcmagent -like "*: Connected"))
    {
        Write-Error "Ensure Azure ARC machine is onboarded and himds sevice is running."
        return
    }
        
    $identityEndpoint = $env:IDENTITY_ENDPOINT
    if(-not ($identityEndpoint)) {
        $identityEndpoint = "http://localhost:40342/metadata/identity/oauth2/token"
    }

    $secretFile = $null
    $endpointUri = "{0}?resource={1}&api-version={2}" -f $identityEndpoint, $audience, $apiVersion

    $response = Invoke-WebRequest -Method GET -Uri $endpointUri `
     -Headers @{Metadata="True"} -UseBasicParsing -SkipHttpErrorCheck
    $challenge = $response.Headers["WWW-Authenticate"]
    if ($challenge -match "Basic realm=.+")
    {
        $secretFile = ($challenge -split "Basic realm=")[1]
    }

    if (!$secretFile)
    {
        throw "something went wrong during requesting to identity service. Resposne content: $response.Content" 
    }

    $secret = Get-Content -Raw $secretFile
    $response = Invoke-WebRequest -Method GET -Uri $endpointUri -Headers @{Metadata="True"; Authorization="Basic $secret"} -UseBasicParsing

    if ($response)
    {
       return (ConvertFrom-Json -InputObject $response.Content).access_token
    }
}

# try to access your keyvault. If you got access denied, run grant-permission.ps1 to grant permission to your machine
$kvtoken = Get-AccessToken -apiVersion "2019-08-15" -audience "https://vault.azure.net"

# connect to your Key Vault
$kvendpoint = "https://<yourKeyVault>.vault.azure.net/secrets/mysecret/b9f60f97d20545f18c0552460af2f822?api-version=7.0"
$response = Invoke-WebRequest -Method GET -Uri $kvendpoint -Headers @{ Authorization="Bearer $kvtoken"} -UseBasicParsing -SkipHttpErrorCheck

if ($response.StatusCode -eq '200')
{
    # retrieve the secrects stored in your KeyVault
    $mysecret = ($response.Content | ConvertFrom-Json).value
    $mysecret
}
else 
{
    Write-Error "Failed in accessing Key Vault. Response received: $response"
}


