# Run the following on your Azure Arc machines to get secrets from your Azure Key Vault.
# Please follow the instructions in the README for connecting your machine to Azure before running the script. 
function Get-AccessToken {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string] $audience,
        [string] $apiVersion = '2019-08-15'
    )

    $agentExePath = Get-Command -Type Application -Name 'azcmagent' -ErrorAction SilentlyContinue
    if (-not $agentExePath)
    {
        throw 'azcmagent not avaliable. Please follow the instructions in the README for connecting your machine to Azure.'
    }
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
    $params = @{
        Method = 'Get';
        Headers = @{metadata='true'};
        Uri = "$endpointUri";
        SkipHttpErrorCheck = $true
    }

    $response = Invoke-WebRequest @params
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
        throw "something went wrong during requesting to identity service. Response content: $response.Content"
    }

    $secret = Get-Content -Raw $secretFile
    $params = @{
        Method = 'Get';
        Headers = @{metadata='true'; Authorization="Basic $secret"};
        Uri = $endpointUri;
    }

    $response = Invoke-RestMethod @params -StatusCodeVariable status
    if ($status -eq '200')
    {
        return  $response.access_token
    }
    else 
    {
        throw  "unexpected response status code: $status"
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
$params = @{
    Method = 'Get';
    Headers = @{Authorization="Bearer $kvtoken"}
    Uri = $kvendpoint;
    SkipHttpErrorCheck = $true
}
$response = Invoke-RestMethod @params -StatusCodeVariable status 
if ($status -eq '200')
{
    # retrieve the secrects stored in your KeyVault
    $response.value
}
else 
{
    Write-Error -Message ("failed in accessing Azure Key Vault. Response received: {0}" -f $response.error)
}
