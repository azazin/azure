#uncomment before start
Login-AzureRmAccount
Get-AzureRmSubscription | Sort-Object subscriptionName | Select-Object SubscriptionName
Select-AzureRmSubscription -SubscriptionName Pay-As-You-Go

# Declare the variables
$version = "1"
$resourceGroup = "Bustergroup$version"
$location = "East US"
$vmName = "BusterVM$version"
$subnetName = "SubNetBuster$version"
$vnetName = "VNetBuster$version"
$SubnetAddressPrefix = "192.168.1.0/24"
$NetAddressPrefx = "192.168.0.0/16"
$nsgName = "NSGBuster$version"
$VMSize = "Basic_A2"
$storageType = "Standard_LRS"
$dataDiskName = $vmName + "_datadisk$version"
$strNum = 11
[int]$diskSizeInGB = [convert]::ToInt32($strNum, 10)
# Storage Account Name (must be lowercase)
$StorageAccName = "busterstorage$version"
$ScriptFormatPath = ".\format.ps1"
$AzureStorageShare = "bustershare$version"



# Create user object
Write-Host "Create user object"  -ForegroundColor Green
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group
Write-Host "Create a resource group"  -ForegroundColor Green
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

# Create a storage account for this resource group
Write-Host "Create a storage account"  -ForegroundColor Green
New-AzureRMStorageAccount -ResourceGroupName $resourceGroup -Location $Location -AccountName $StorageAccName -SkuName Standard_LRS

# Create a subnet configuration
Write-Host "Create a subnet configuration"  -ForegroundColor Green
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $SubnetAddressPrefix

# Create a virtual network
Write-Host "Create a virtual network"  -ForegroundColor Green
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
  -Name $vnetName -AddressPrefix $NetAddressPrefx -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
Write-Host "Create a public IP address and specify a DNS name"  -ForegroundColor Green
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name "busterpublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 3389
Write-Host "Create an inbound network security group rule for port 3389"  -ForegroundColor Green
$rdpRule = New-AzureRmNetworkSecurityRuleConfig -Name "busterRDPRule" -Description "Allow RDP" `
    -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority "140" `
    -SourceAddressPrefix * -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 3389

# Create an inbound network security group rule for port 80
Write-Host "Create an inbound network security group rule for port 80"  -ForegroundColor Green
$httprule = New-AzureRmNetworkSecurityRuleConfig -Name "busterHTTPRule" -Description "Allow HTTP" `
    -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority "100" `
    -SourceAddressPrefix "Internet" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 80

# Create an inbound network security group rule for port 1352
Write-Host "Create an inbound network security group rule for port 1352"  -ForegroundColor Green
$notesrule = New-AzureRmNetworkSecurityRuleConfig -Name "busterIBMNotesRule" -Description "Allow IBM Notes" `
    -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority "120" `
    -SourceAddressPrefix "Internet" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 1352

# Create a network security group
Write-Host "Create a network security group"  -ForegroundColor Green
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name $nsgName -SecurityRules $rdpRule,$httprule,$notesrule

# Create a virtual network card and associate with public IP address and NSG
Write-Host "Create a virtual network card and associate with public IP address and NSG"  -ForegroundColor Green
$nic = New-AzureRmNetworkInterface -Name busterNic -ResourceGroupName $resourceGroup -Location $location `
  -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration
Write-Host "Create a virtual machine configuration"  -ForegroundColor Green
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $VMSize | `
Set-AzureRmVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic.Id

Write-Host "Add an empty data disk to the virtual machine configuration"  -ForegroundColor Green
$vmConfig = Add-AzureRmVMDataDisk -VM $vmConfig -Name $dataDiskName -DiskSizeInGB $diskSizeInGB -CreateOption Empty -Lun 1

# Create a virtual machine
Write-Host "Create a virtual machine using the virtual machine configuration"  -ForegroundColor Green
New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

#getting IP address of the VM
Get-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup | Select "IpAddress"

#Initialize and format attached raw disk
Write-Host "Initialize and format previously added hard disk"  -ForegroundColor Green
Invoke-AzureRmVMRunCommand -ResourceGroupName $resourceGroup -VMName $vmName -CommandId 'RunPowerShellScript' -ScriptPath   $ScriptFormatPath

Write-Host "Finished!"  -ForegroundColor Green
