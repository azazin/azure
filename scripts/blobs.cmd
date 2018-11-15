@echo off
echo "please enter your AZ login"
call set /p login=
call az login  --username %login%
echo "please enter any 3 digits or letters to create a value for variable"
call set /p version=


call set ResourceGroupName=BlobResourceGroup%version%
call set location=eastus2
call set storageaccname=blobbtorageaccount%version%
call set SKU=Standard_LRS
call set containername=blobcontainername%version%
call set keyfile=..\..\key.txt


call az group create  --name %ResourceGroupName%  --location %location%
call az storage account create --name %storageaccname%  --resource-group %ResourceGroupName%     --location %location%     --sku %SKU%    --encryption blob

call set storageacckey=az storage account keys list --account-name %storageaccname%   --query "[?keyName=='key1'].value" -o tsv
call set AZURE_STORAGE_ACCESS_KEY=%storageacckey%
call set AZURE_STORAGE_ACCOUNT=%storageaccname%
call %AZURE_STORAGE_ACCESS_KEY% >%keyfile%
call az storage container create --name %containername%
call set /P keystring=<%keyfile%

call AzCopy /Source:C:\Users\buster\Documents\GitHub\azure /Dest:https://%storageaccname%.blob.core.windows.net/%containername% /DestKey:%keystring% /S
call az storage blob list --container-name %containername% -o table
