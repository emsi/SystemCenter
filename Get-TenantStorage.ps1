$userRole="*tenant@emsi.address*"

Get-SCVirtualMachine | where UserRole -Like $userRole | 
    foreach {
        $vmName=$_.Name
        $_.VirtualHardDisks | foreach {
            new-object psobject -Property @{
                Name = $vmName
                Location= $_.Location
                Classification = $_.Classification
                SizeGB= $_.MaximumSize / 1GB
                }
        }
    } | sort -Property Classification, Name
