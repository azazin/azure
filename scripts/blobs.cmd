@echo off
echo "please enter your AZ login"
call set /p login=
call az login  --username %login%
echo "please enter any 3 digit to create variable"
call set /p version=


call set ResourceGroupName=blobResourceGroup%version%
call set location=eastus
call set storageaccname=blobstorageaccount%version%
call set SKU=Standard_LRS
call set containername=blobontainername%version%

 call az group create  --name %ResourceGroupName%  --location %location%
 call az storage account create --name %storageaccname%  --resource-group %ResourceGroupName%     --location %location%     --sku %SKU%    --encryption blob

 call set storagekey1=az storage account keys list --account-name %storageaccname%   --query "[?keyName=='key1'].value" -o tsv
 call %storagekey1% >key.txt