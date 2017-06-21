# Variables
$endpoint = 'mysftestcluster.southcentralus.cloudapp.azure.com:19000'
$thumbprint = '2779F0BB9A969FB88E04915FFE7955D0389DA7AF'
$packagepath="C:\Users\sfuser\Documents\Visual Studio 2017\Projects\MyApplication\MyApplication\pkg\Release"

# Connect to the cluster using a client certificate.
Connect-ServiceFabricCluster -ConnectionEndpoint $endpoint `
          -KeepAliveIntervalInSec 10 `
          -X509Credential -ServerCertThumbprint $thumbprint `
          -FindType FindByThumbprint -FindValue $thumbprint `
          -StoreLocation CurrentUser -StoreName My

# Copy the application package to the cluster image store.
Copy-ServiceFabricApplicationPackage $packagepath -ImageStoreConnectionString fabric:ImageStore -ApplicationPackagePathInImageStore MyApplication

# Register the application type.
Register-ServiceFabricApplicationType MyApplication

# Create the application instance.
New-ServiceFabricApplication fabric:/MyApplication MyApplicationType 1.0.0