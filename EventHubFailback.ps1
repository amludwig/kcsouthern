# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process | Out-Null

# Connect using a Managed Service Identity
try {
        $AzureContext = (Connect-AzAccount -Identity).context
    }
catch{
        Write-Output "There is no system-assigned user identity. Aborting."; 
        exit
    }

# set and store context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription `
    -DefaultProfile $AzureContext

#Step2 - Following parameters are used while creating the resources
#geo location where the primary namespace is
$location1 = "NorthCentralUS"

#geo location where the secondary namespace should be created
$location2 = "SouthCentralUS"

#provide your existing resourcegroup which has the primary namespace
$resourcegroup1 = "primary-rg"

#provide your existing secondary resource group which will have the secondary namespace
$resourcegroup2 = "secondary-rg"

#provide your existing primary namespace
$primarynamespace = "primaryeh"

$secondarynamespace = "secondaryeh"

#your primary namespace is you alias here (provide your primary namespace name)
$aliasname = "drconfig"

$alternatename = "primaryaltname"

Get-AzEventHubNamespace -ResourceGroup $resourcegroup2 –NamespaceName $secondarynamespace

#Step 3 - create your secondary namespace. Copy the ARM ID from the output as you need it later for -PartnerPartnernamespace. 
# sample ARM ID looks like this - /subscriptions/your subscriptionid/resourceGroups/$resourcegroup/providers/Microsoft.EventHub/namespaces/secondarynamespace
#New-AzEventHubNamespace –ResourceGroup $resourceGroup2 –NamespaceName $secondarynamespace -Location $location2 -SkuName Standard

#Step 4 - Create a geo-dr configuration with primarynamespace name as the alias name and pair the namespaces. Note, you will also provide the alternatename here.
# It is using this alternatename that you will access your old primary once you have triggered the failover
New-AzEventHubGeoDRConfiguration -Name $aliasname -Namespace $secondarynamespace -ResourceGroupName $resourcegroup2 -PartnerNamespace "/subscriptions/36220f64-3101-46e8-b119-fa718c07dffe/resourceGroups/primary-rg/providers/Microsoft.EventHub/namespaces/primaryeh"


#Optional - Once your geo-dr configurations are set, you can get the details using this'
Get-AzEventHubGeoDRConfiguration -ResourceGroup $resourceGroup2 -Namespace $secondarynamespace

#Step 5 - you can now do a failover on your secondary namespace with the following command
Set-AzEventHubGeoDRConfigurationFailOver -ResourceGroup $resourceGroup1 -Name $aliasname -Namespace $primarynamespace

#Optional - check you geo-dr configuration details to reflect the fail-over
#Note - your secondarynamespace after the failover will be your new primary, but the connection string remains the same
Get-AzEventHubGeoDRConfiguration -ResourceGroup $resourceGroup1 -Namespace $primarynamespace 

#Step 6 - Create a geo-dr configuration with primarynamespace name as the alias name and pair the namespaces.
New-AzEventHubGeoDRConfiguration -Name $aliasname -Namespace $primarynamespace -ResourceGroupName $resourcegroup1 -PartnerNamespace "/subscriptions/36220f64-3101-46e8-b119-fa718c07dffe/resourceGroups/secondary-rg/providers/Microsoft.EventHub/namespaces/secondaryeh"


#/*$failoverGroup1 = Get-AzSqlDatabaseFailoverGroup -ResourceGroupName $resourceGroup1 -ServerName $serverName1 -FailoverGroupName $failoverGroupName


#if ($failoverGroup1.ReplicationRole -eq "Secondary") {
    #Failover to Server 1
   # $failoverGroup1 | Switch-AzSqlDatabaseFailoverGroup -AllowDataLoss
   # $serverName = $failoverGroup1.ServerName
   # Write-Output "Initiated failback to $serverName"
#} else {
    #Failover to Server 2
  #  $failoverGroup2 | Switch-AzSqlDatabaseFailoverGroup -AllowDataLoss
  #  $serverName = $failoverGroup2.ServerName
   # Write-Output "Initiated failover to $serverName"
#}