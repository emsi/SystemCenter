Get-ClusterSharedVolume |
 foreach {
  new-object psobject -Property @{
   Date = Get-Date
   Name = $_.name
   OwnerNode = $_.OwnerNode
   FriendlyVolumeName = $_.SharedVolumeInfo.FriendlyVolumename
   CapacityGB=$_.SharedVolumeInfo.Partition.Size / 1GB
   UsedSpaceGB = $_.SharedVolumeInfo.Partition.Usedspace / 1GB
   FreeSpaceGB = ($_.SharedVolumeInfo.Partition.Size - $_.SharedVolumeInfo.Partition.Usedspace) / 1GB
   FreePCT = "{0:N2}" -f (100*($_.SharedVolumeInfo.Partition.Size - $_.SharedVolumeInfo.Partition.UsedSpace)/$_.SharedVolumeInfo.Partition.Size)
 }
}  | ft
