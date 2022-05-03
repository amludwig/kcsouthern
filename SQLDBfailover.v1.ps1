<#
    .DESCRIPTION
        A runbook which fails over your Azure SQL Failover group to the secondary with allow data loss
        This can be used for triggered emergency failovers.
    .NOTES
        AUTHOR: Cameron Battagler
        LASTEDIT: Apr 18, 2019
#>


Param(
 [string]$resourceGroup,
 [string]$VMName,
 [string]$method,
 [string]$UAMI 
)

$resourceGroup = "primary-rg"
$VMName = "primary-server"
$method = "SA"
$UAMI = "xUAMI"


#Failover Group
$failoverGroupName = "primaryfg"

#Server 1 Resource Group and Server Name
$resourceGroup1 = "primary-rg"
$serverName1 = "primary-server1"

#Server 2 Resource Group and Server Name
$resourceGroup2 = "secondary-rg"
$serverName2 = "secondary-server1"
    

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

if ($method -eq "SA")
    {
        Write-Output "Using system-assigned managed identity"
    }
elseif ($method -eq "UA")
    {
        Write-Output "Using user-assigned managed identity"
    }
else {
        Write-Output "Invalid method. Choose UA or SA."
        exit
	}



$failoverGroup1 = Get-AzSqlDatabaseFailoverGroup -ResourceGroupName $resourceGroup1 -ServerName $serverName1 -FailoverGroupName $failoverGroupName

$failoverGroup2 = Get-AzSqlDatabaseFailoverGroup -ResourceGroupName $resourceGroup2 -ServerName $serverName2 -FailoverGroupName $failoverGroupName

if ($failoverGroup1.ReplicationRole -eq "Secondary") {
    #Failover to Server 1
    $failoverGroup1 | Switch-AzSqlDatabaseFailoverGroup -AllowDataLoss
    $serverName = $failoverGroup1.ServerName
    Write-Output "Initiated failback to $serverName"
} else {
    #Failover to Server 2
    $failoverGroup2 | Switch-AzSqlDatabaseFailoverGroup -AllowDataLoss
    $serverName = $failoverGroup2.ServerName
    Write-Output "Initiated failover to $serverName"
}