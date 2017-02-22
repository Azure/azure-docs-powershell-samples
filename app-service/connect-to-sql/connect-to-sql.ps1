
# Generates a Random Value
$Random=(New-Guid).ToString().Substring(0,8)

# Variables
$ResourceGroup="MyResourceGroup$Random"
$AppName="webappwithSQL$Random"
$Location="West US"
$ServerName="webappwithsql$Random"
$StartIP="0.0.0.0"
$EndIP="0.0.0.0"
$Username="ServerAdmin"
$Password="<provide-a-password>"
$SqlServerPassword=New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,(ConvertTo-SecureString -String $Password -AsPlainText -Force)

# Create a Resource Group
New-AzureRMResourceGroup -Name $ResourceGroup -Location $Location

# Create an App Service Plan
New-AzureRMAppservicePlan -Name WebAppwithSQLPlan -ResourceGroupName $ResourceGroup -Location $Location -Tier Basic

# Create a Web App in the App Service Plan
New-AzureRMWebApp -Name $AppName -ResourceGroupName $ResourceGroup -Location $Location -AppServicePlan WebAppwithSQLPlan

# Create a SQL Database Server
New-AzureRMSQLServer -ServerName $ServerName -Location $Location -SqlAdministratorCredentials $SqlServerPassword -ResourceGroupName $ResourceGroup

# Create Firewall Rule for SQL Database Server
New-AzureRmSqlServerFirewallRule -FirewallRuleName "AllowYourIp" -StartIpAddress $StartIP -EndIPAddress $EndIP -ServerName $ServerName -ResourceGroupName $ResourceGroup

# Create SQL Database in SQL Database Server
New-AzureRMSQLDatabase -ServerName $ServerName -DatabaseName MySampleDatabase -ResourceGroupName $ResourceGroup

# Assign Connection String to Connection String 
Set-AzureRMWebApp -ConnectionStrings @{ MyConnectionString = @{ Type="SQLAzure"; Value ="Server=tcp:$ServerName.database.windows.net;Database=MySampleDatabase;User ID=$Username@$ServerName;Password=$password;Trusted_Connection=False;Encrypt=True;" } } -Name $AppName -ResourceGroupName $ResourceGroup