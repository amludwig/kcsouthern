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

$automationAccount = "kcfailover"

$SubscriptionName="Azure Team Sandbox Subscription 1"
$ResourceGroupName="primary-rg"
$ServerName="primary-server"  # Without database.windows.net
$TargetResourceGroupName="secondary-rg" # uncomment to restore to a different server.
$TargetServerName="secondary-server"  
$DatabaseName="primary-pool"
$NewDatabaseName="secondary-pool-failover"
$Label = Get-Date -format g


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


# Get last restore point
Get-AzSqlDatabaseRestorePoint -ResourceGroupName $ResourceGroupName -DataBaseName $DatabaseName -ServerName $ServerName | Select -Last 1 
$RestorePointCreationDate =(Get-AzSqlDatabaseRestorePoint -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DataBaseName $DataBaseName | Select -Last 1).RestorePointCreationDate
 
# Create a restore point of the original database
New-AzSqlDatabaseRestorePoint -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -RestorePointLabel $Label

# Get the specific database to restore
$Database = Get-AzSqlDatabase -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName

#Start-Sleep -second 300

# Pick desired restore point using RestorePointCreationDate "xx/xx/xxxx xx:xx:xx xx"
$PointInTime = $RestorePointCreationDate

# Restore to a different server
$RestoredDatabase = Restore-AzSqlDatabase –FromPointInTimeBackup –PointInTime $PointInTime -ResourceGroupName $TargetResourceGroupName -ServerName $TargetServerName -TargetDatabaseName $NewDatabaseName –ResourceId $Database.ResourceID

# Verify the status of restored database
#$Database.status
#$Database.location

$status = $RestoredDatabase.status
$location = $RestoredDatabase.location

if ($status -eq "online")
    {
        Write-Output "The secondary database is ONLINE."
    }
elseif ($status -eq "paused")
    {
        Write-Output "The secondary database is PAUSED."
    }
else {
        Write-Output "The secondary database is OFFLINE."
        exit
	}

if ($location -eq "northcentralus")
    {
        Write-Output "The secondary database is in the North Central region."
    }
elseif ($location -eq "southcentralus")
    {
        Write-Output "The secondary database is in the South Central region."
    }
else {
        Write-Output "Test test"
        exit
	}