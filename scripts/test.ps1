#uncomment before start
#Login-AzureRmAccount
Get-AzureRmSubscription | Sort-Object subscriptionName | Select-Object SubscriptionName
Select-AzureRmSubscription -SubscriptionName Pay-As-You-Go

#$location = "East US"
#$numbernodes = Read-Host -Prompt 'number of nodes'
$match = '^[0-9]{3}$'
do {
$version = Read-Host "Enter 3 digits for the new version to avoid duplicates "
}until ($version -match $match)

$match = '^[a-zA-Z]{6}$'
do {
$rgpreffix = Read-Host "Enter the 6 letters-prefix for the resourcegroup"
}until ($rgpreffix -match $match)
$resourceGroup = "$rgpreffix$version"

$location = "East US"
$SubnetAddressPrefix = "192.168.1.0/24"
$NetAddressPrefx = "192.168.0.0/16"

$match = '^[2-9]{1}$'
do {
$numbernodes = Read-Host "Number of nodes 2-9"
}until ($numbernodes -match $match)
$VMSize = "Basic_A2"

echo $version $rgpreffix $resourceGroup $numbernodes




#Create a resource group
Write-Host "Create a resource group"  -ForegroundColor Green
New-AzureRmResourceGroup   -Name $resourceGroup   -Location $location

# Create a public IP address and specify a DNS name
Write-Host "Create a public IP address and specify a DNS name"  -ForegroundColor Green
$publicIP = New-AzureRmPublicIpAddress   -ResourceGroupName $resourceGroup   -Location $location   -AllocationMethod "Static"   -Name "myPublicIP"

#Create a frontend IP pool
Write-Host "Create a frontend IP pool"  -ForegroundColor Green
$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig   -Name "myFrontEndPool"   -PublicIpAddress $publicIP

#Create a backend address pool
Write-Host "Create a backend address pool"  -ForegroundColor Green
$backendPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "myBackEndPool"

#Create a load balancer
Write-Host "Create a load balancer"  -ForegroundColor Green
$lb = New-AzureRmLoadBalancer   -ResourceGroupName $resourceGroup   -Name "myLoadBalancer"   -Location $location   -FrontendIpConfiguration $frontendIP `
   -BackendAddressPool $backendPool

#Create a health probe
Write-Host "Create a health probe"  -ForegroundColor Green
Add-AzureRmLoadBalancerProbeConfig   -Name "myHealthProbe"   -LoadBalancer $lb   -Protocol tcp   -Port 8080   -IntervalInSeconds 15   -ProbeCount 2

#Apply the health probe to the load balancer
Write-Host "Apply the health probe to the load balancer"  -ForegroundColor Green
Set-AzureRmLoadBalancer -LoadBalancer $lb

#Create a load balancer rule
Write-Host "Create a load balancer rule"  -ForegroundColor Green
$probe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "myHealthProbe"

Add-AzureRmLoadBalancerRuleConfig   -Name "myLoadBalancerRule"   -LoadBalancer $lb   -FrontendIpConfiguration $lb.FrontendIpConfigurations[0] `
  -BackendAddressPool $lb.BackendAddressPools[0]   -Protocol Tcp   -FrontendPort 80   -BackendPort 8080   -Probe $probe

#Update the load balancer
Write-Host "Update the load balancer"  -ForegroundColor Green
Set-AzureRmLoadBalancer -LoadBalancer $lb

# Create a subnet configuration
Write-Host "Create a subnet configuration"  -ForegroundColor Green
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig   -Name "mySubnet"   -AddressPrefix $SubnetAddressPrefix

# Create a virtual network
Write-Host "Create a virtual network"  -ForegroundColor Green
$vnet = New-AzureRmVirtualNetwork   -ResourceGroupName $resourceGroup   -Location $location   -Name "myVnet"   -AddressPrefix $NetAddressPrefx   -Subnet $subnetConfig

#Create  virtual NICs
Write-Host "Create  virtual NICs"  -ForegroundColor Green
for ($i=1; $i -le $numbernodes; $i++)
{
  New-AzureRmNetworkInterface  -ResourceGroupName $resourceGroup  -Name myVM$i  -Location $location  -Subnet $vnet.Subnets[0] `
    -LoadBalancerBackendAddressPool $lb.BackendAddressPools[0]
}

#Create an availability set
Write-Host "Create an availability set"  -ForegroundColor Green
$availabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroup -Name "myAvailabilitySet" -Location $location -Sku aligned -PlatformFaultDomainCount 2  `
 -PlatformUpdateDomainCount 2

# Create user object
Write-Host "Create user object"  -ForegroundColor Green
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

#Create  VMs
Write-Host "Create VMs"  -ForegroundColor Green
for ($i=1; $i -le $numbernodes; $i++)
{
  New-AzureRmVm -ResourceGroupName $resourceGroup -Name "myVM$i" -Location $location -VirtualNetworkName "myVnet" -SubnetName "mySubnet" -SecurityGroupName "myNetworkSecurityGroup" `
    -OpenPorts 8080 -AvailabilitySetName "myAvailabilitySet" -Credential $cred -AsJob
}


#Install IIS update the Default.htm page
Write-Host "Install IIS update the Default.htm page"  -ForegroundColor Green
for ($i=1; $i -le $numbernodes; $i++)
{

Set-AzureRmVMExtension -ResourceGroupName $resourceGroup -ExtensionName "IIS" -VMName myVM$i -Publisher Microsoft.Compute -ExtensionType CustomScriptExtension `
   -TypeHandlerVersion 1.8 `
   -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
   -Location $location
}


#Getting IP address of the VM
Write-Host "Getting IP address of the VM"  -ForegroundColor Green
Start-Sleep -s 15
Get-AzureRmPublicIPAddress -ResourceGroupName $resourceGroup -Name "myPublicIP" | select IpAddress
