
Get-Disk |
Where partitionstyle -eq 'raw'|
Initialize-Disk -PartitionStyle MBR -PassThru |
New-Partition -AssignDriveLetter -UseMaximumSize |
Format-Volume -FileSystem NTFS -NewFileSystemLabel laba_label -Confirm:$false
