$filePath="<Replace with full file path>"
$webappname="mywebapp$(Get-Random)"
$location="West Europe"

# Create a resource group.
New-AzResourceGroup -Name myResourceGroup -Location $location

# Create an App Service plan in `Free` tier.
New-AzAppServicePlan -Name $webappname -Location $location `
-ResourceGroupName myResourceGroup -Tier Free

# Create a web app.
New-AzWebApp -Name $webappname -Location $location -AppServicePlan $webappname `
-ResourceGroupName myResourceGroup

# Get publishing profile for the web app
$xml = [xml](Get-AzWebAppPublishingProfile -Name $webappname `
-ResourceGroupName myResourceGroup `
-OutputFile null)

# Extract connection information from publishing profile
$username = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userName").value
$password = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@userPWD").value
$url = $xml.SelectNodes("//publishProfile[@publishMethod=`"FTP`"]/@publishUrl").value

# Upload file 
$file = Get-Item -Path $filePath
$uri = New-Object System.Uri("$url/$($file.Name)")

$request = [System.Net.FtpWebRequest]([System.net.WebRequest]::Create($uri))
$request.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$request.Credentials = New-Object System.Net.NetworkCredential($username,$password)

# Enable SSL for FTPS. Should be $false if FTP.
$request.EnableSsl = $true;

# Write the file to the request object.
$fileBytes = [System.IO.File]::ReadAllBytes($filePath)
$request.ContentLength = $fileBytes.Length;
$requestStream = $request.GetRequestStream()

try {
    $requestStream.Write($fileBytes, 0, $fileBytes.Length)
}
finally {
    $requestStream.Dispose()
}

Write-Host "Uploading to $($uri.AbsoluteUri)"

try {
    $response = [System.Net.FtpWebResponse]($request.GetResponse())
    Write-Host "Status: $($response.StatusDescription)"
}
finally {
    if ($null -ne $response) {
        $response.Close()
    }
}