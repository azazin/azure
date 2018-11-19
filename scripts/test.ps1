$cred = Get-Credential
$version = "1"
$resourceGroup = "Bustergroup$version"


New-AzureRmResourceGroup -Name $resourceGroup -Location eastus

$backendSubnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
  -Name myAGSubnet `
  -AddressPrefix 10.0.1.0/24
$agSubnetConfig = New-AzureRmVirtualNetworkSubnetConfig `
  -Name myBackendSubnet `
  -AddressPrefix 10.0.2.0/24
New-AzureRmVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location eastus `
  -Name myVNet `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $backendSubnetConfig, $agSubnetConfig
New-AzureRmPublicIpAddress `
  -ResourceGroupName $resourceGroup `
  -Location eastus `
  -Name myAGPublicIPAddress `
  -AllocationMethod Dynamic

  $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name myVNet
#  $cred = Get-Credential
  for ($i=1; $i -le 2; $i++)
  {
    $nic = New-AzureRmNetworkInterface `
      -Name myNic$i `
      -ResourceGroupName $resourceGroup `
      -Location EastUS `
      -SubnetId $vnet.Subnets[1].Id
    $vm = New-AzureRmVMConfig `
      -VMName myVM$i `
      -VMSize Standard_DS2
    $vm = Set-AzureRmVMOperatingSystem `
      -VM $vm `
      -Windows `
      -ComputerName myVM$i `
      -Credential $cred
    $vm = Set-AzureRmVMSourceImage `
      -VM $vm `
      -PublisherName MicrosoftWindowsServer `
      -Offer WindowsServer `
      -Skus 2016-Datacenter `
      -Version latest
    $vm = Add-AzureRmVMNetworkInterface `
      -VM $vm `
      -Id $nic.Id
    $vm = Set-AzureRmVMBootDiagnostics `
      -VM $vm `
      -Disable
    New-AzureRmVM -ResourceGroupName $resourceGroup -Location EastUS -VM $vm
    Set-AzureRmVMExtension `
      -ResourceGroupName $resourceGroup `
      -ExtensionName IIS `
      -VMName myVM$i `
      -Publisher Microsoft.Compute `
      -ExtensionType CustomScriptExtension `
      -TypeHandlerVersion 1.4 `
      -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
      -Location EastUS
  }

  $vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Name myVNet
$pip = Get-AzureRmPublicIPAddress -ResourceGroupName $resourceGroup -Name myAGPublicIPAddress
$subnet=$vnet.Subnets[0]
$gipconfig = New-AzureRmApplicationGatewayIPConfiguration `
  -Name myAGIPConfig `
  -Subnet $subnet
$fipconfig = New-AzureRmApplicationGatewayFrontendIPConfig `
  -Name myAGFrontendIPConfig `
  -PublicIPAddress $pip
$frontendport = New-AzureRmApplicationGatewayFrontendPort `
  -Name myFrontendPort `
  -Port 80


  $address1 = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Name myNic1
$address2 = Get-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Name myNic2
$backendPool = New-AzureRmApplicationGatewayBackendAddressPool `
  -Name myAGBackendPool `
  -BackendIPAddresses $address1.ipconfigurations[0].privateipaddress, $address2.ipconfigurations[0].privateipaddress
$poolSettings = New-AzureRmApplicationGatewayBackendHttpSettings `
  -Name myPoolSettings `
  -Port 80 `
  -Protocol Http `
  -CookieBasedAffinity Enabled `
  -RequestTimeout 120


  $defaultlistener = New-AzureRmApplicationGatewayHttpListener `
  -Name myAGListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $frontendport
$frontendRule = New-AzureRmApplicationGatewayRequestRoutingRule `
  -Name rule1 `
  -RuleType Basic `
  -HttpListener $defaultlistener `
  -BackendAddressPool $backendPool `
  -BackendHttpSettings $poolSettings


  $sku = New-AzureRmApplicationGatewaySku `
  -Name Standard_Medium `
  -Tier Standard `
  -Capacity 2
New-AzureRmApplicationGateway `
  -Name myAppGateway `
  -ResourceGroupName $resourceGroup `
  -Location eastus `
  -BackendAddressPools $backendPool `
  -BackendHttpSettingsCollection $poolSettings `
  -FrontendIpConfigurations $fipconfig `
  -GatewayIpConfigurations $gipconfig `
  -FrontendPorts $frontendport `
  -HttpListeners $defaultlistener `
  -RequestRoutingRules $frontendRule `
  -Sku $sku


  Get-AzureRmPublicIPAddress -ResourceGroupName $resourceGroup -Name myAGPublicIPAddress
