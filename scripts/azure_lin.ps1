# Variables for common values
$resourceGroup = "lingroup221"
$location = "eastus2"
$VirtualMachine = "mylinVM"

#connect azure account
#Connect-AzureRmAccount


New-AzureRmResourceGroup -Name $resourceGroup -Location $location

# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
  -Name "mySubnet" `
  -AddressPrefix 192.168.1.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "myVNET" `
  -AddressPrefix 192.168.0.0/16 `
  -Subnet $subnetConfig


# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4 `
  -Name "mypublicdns$(Get-Random)"

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleSSH"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access "Allow"

# Create an inbound network security group rule for port 80
$nsgRuleWeb = New-AzureRmNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleWWW"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access "Allow"


# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "myNetworkSecurityGroup" `
  -SecurityRules $nsgRuleSSH,$nsgRuleWeb

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface `
  -Name "myNic" `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString 'WRiVMi8sC7iDDxpT2o6Z3OfslQnyty7nD+' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("buster", $securePassword)

# Create a virtual machine configuration
$vmConfig = New-AzureRmVMConfig `
  -VMName $VirtualMachine `
  -VMSize "Standard_D1" | `
Set-AzureRmVMOperatingSystem `
  -Linux `
  -ComputerName "myVM" `
  -Credential $cred `
  -DisablePasswordAuthentication | `
Set-AzureRmVMSourceImage `
  -PublisherName "Canonical" `
  -Offer "UbuntuServer" `
  -Skus "16.04-LTS" `
  -Version "latest" | `
Add-AzureRmVMNetworkInterface `
  -Id $nic.Id

# Configure the SSH key
$sshPublicKey = cat /home/vagrant/.ssh/id_rsa.pub
Add-AzureRmVMSshPublicKey `
  -VM $vmconfig `
  -KeyData $sshPublicKey `
  -Path "/home/buster/.ssh/authorized_keys"

#Create with New-AzureRmVM
  New-AzureRmVM `
  -ResourceGroupName $resourceGroup `
  -Location $location -VM $vmConfig
