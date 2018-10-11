$gitdirectory="<Replace with path to local Git repo>"
$webappname="mywebapp$(Get-Random)"

cd $gitdirectory

# Create a web app and set up Git deployement.
New-AzureRmWebApp -Name $webappname

# Push your code to the new Azure remote
git push azure master
