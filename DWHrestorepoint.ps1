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
$DatabaseName="primary-pool"
#$Label = (Get-Date).AddHours(-5)
#$Label = Get-Date -format "MM-dd HH:mm" 
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

# Create a restore point of the original database
New-AzSqlDatabaseRestorePoint -ResourceGroupName $ResourceGroupName -ServerName $ServerName -DatabaseName $DatabaseName -RestorePointLabel $Label