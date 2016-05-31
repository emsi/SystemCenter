# (C) 2015-2016 Mariusz Wołoszyn
# loosely based on https://blogs.msdn.microsoft.com/virtual_pc_guy/2015/06/23/building-a-daily-ubuntu-image-for-hyper-v/

# Helper function for no error file cleanup
Function cleanupFile ([string]$file) {if (test-path $file) {Remove-Item $file}}

# Local image copy
$imageCachePath = "C:\temp\Images"
$vhdPath = $imageCachePath # You can use any other destination here

# VMM Library and path
$vmmLibrary = "vmm.library.server"
$vmmLibraryPath = "$vmmLibrary\library"
$vhdxPath = "\\$vmmLibraryPath\path\to\vhd\images\"

function getUbuntuImage ()
{
  Param($ubuntuVersion, $ubuntuTag, $ubuntuOperatingSystem, $ubuntuFamilyName,$force=0,$dailyImage=0)
  
  # construct vhd and vhdx file paths
  $vhdxFile = "$($vhdxPath)\$ubuntuVersion.vhdx"
  $vhdFile="$($vhdPath)\$ubuntuVersion-server-cloudimg-amd64-disk1.vhd"
  
  # construct image and manifest URL
  if ($dailyImage) {
    $imageUrl = "https://cloud-images.ubuntu.com/$ubuntuVersion/current/$ubuntuVersion-server-cloudimg-amd64-disk1.vhd.zip"
    $manifestURL = "https://cloud-images.ubuntu.com/$ubuntuVersion/current/$ubuntuVersion-server-cloudimg-amd64.manifest"
  } else {
    $imageUrl = "https://cloud-images.ubuntu.com/releases/$ubuntuVersion/release/$ubuntuFamilyName-server-cloudimg-amd64-disk1.vhd.zip"
    $manifestURL = "https://cloud-images.ubuntu.com/releases/$ubuntuVersion/release/$ubuntuFamilyName-server-cloudimg-amd64.manifest"
  }
  
  # Get the timestamp of the latest build on the Ubuntu cloud-images site
  $lastModified=(Invoke-WebRequest $manifestURL).BaseResponse.LastModified
  $stamp = $lastModified.ToFileTimeUtc()
  $release="1."+$lastModified.Date.Year+"."+$lastModified.Date.Month+"."+$lastModified.Date.Day
  
  # image download path
  $imageCacheFile = "$($imageCachePath)\$ubuntuVersion-$($stamp).vhd.zip"
  
  # Check Paths
  if (!(Test-Path $imageCachePath)) {mkdir $imageCachePath}
  
  # Get vhd data from library
  $vhd = Get-SCVirtualHardDisk | Where-Object {$_.Location –eq $vhdxFile} 
  
  # Nothing to do. Most up-to-date image is in library
  if (($vhd.Release -eq $release) -and ($vhd.State -eq "Normal")){
    return
  }
  
  # No up-to-date image file, need to re-download
  if (!(Test-Path $imageCacheFile) -or $force) {
    "Downloading $imageUrl"
    # If we do not have a matching image - delete the old ones and download the new one
    Remove-Item "$($imageCachePath)\$ubuntuVersion-*.vhd.zip"
    (new-object System.Net.WebClient).DownloadFile("$imageUrl", $imageCacheFile)
  }
  
  # If there is image file, uncompress it
  if (Test-Path $imageCacheFile) {
    "Uncompressing $imageCacheFile"
    # unzip cannot overwrite, make surwe there is no old target vhd
    cleanupFile($vhdFile)
    # Unzip VHD
    Add-Type -assembly "system.io.compression.filesystem"
    [io.compression.zipfile]::ExtractToDirectory($imageCacheFile, $vhdPath)
    if (Test-Path $vhdFile) {cleanupFile($imageCacheFile)}
  }
  
  # Is there vhd file for conversion?
  if (Test-Path $vhdFile) {
    cleanupFile $vhdxFile
    "Converting to VHDX"
    # Covert to VHDX and resize to 50GB
    Convert-VHD –Path $vhdFile –DestinationPath $vhdxFile –VHDType Dynamic -DeleteSource 
    Resize-VHD -Path $vhdxFile -SizeBytes 50GB

    # Set tags
    Set-SCVirtualHardDisk –VirtualHardDisk $vhd -Name $ubuntuVersion -OperatingSystem $ubuntuOperatingSystem  -Tag $ubuntuTag -Release $release -FamilyName $ubuntuFamilyName
  }
}

# Refresh library
$LibShare = Get-SCLibraryShare  | where { $_.Path -eq "\\$vmmLibraryPath" }
Read-SCLibraryShare -LibraryShare $LibShare | Out-Null

getUbuntuImage -ubuntuVersion "precise" -ubuntuTag "UbuntuLinux12.04" -ubuntuOperatingSystem "Ubuntu Linux 12.04 (64 bit)" -ubuntuFamilyName "ubuntu-12.04" 
getUbuntuImage -ubuntuVersion  "trusty" -ubuntuTag "UbuntuLinux14.04" -ubuntuOperatingSystem "Ubuntu Linux 14.04 (64 bit)" -ubuntuFamilyName "ubuntu-14.04"
#getUbuntuImage -ubuntuVersion    "wily" -ubuntuTag "UbuntuLinux15.10" -ubuntuOperatingSystem "Ubuntu Linux 14.04 (64 bit)" -ubuntuFamilyName "ubuntu-15.10"
getUbuntuImage -ubuntuVersion  "xenial" -ubuntuTag "UbuntuLinux16.04" -ubuntuOperatingSystem "Ubuntu Linux 14.04 (64 bit)" -ubuntuFamilyName "ubuntu-16.04"
