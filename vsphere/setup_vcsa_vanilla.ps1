$VCSAHostname = "vcsa.tanzu.local"
$VCSAUsername = "administrator@vsphere.local"
$VCSAPassword = "topSecretPassword"
$DatacenterName = "Tanzu-Datacenter"
$DatastoreName = "datastore1"
$ClusterName = "Tanzu-Cluster"
$ESXi1Hostname = "esxi01.tanzu.local"
$ESXi2Hostname = "esxi02.tanzu.local"
$ESXiPassword = "topSecretPassword"
$VDSName = "VDS"
$VDSManagementPG = "Management"
$StoragePolicyName = "Tanzu-Storage-Policy"
$StoragePolicyCategory = "WorkloadType"
$StoragePolicyTag = "Tanzu"

$vc = Connect-VIServer $VCSAHostname -User $VCSAUsername -Password $VCSAPassword

Write-Host "Disabling Network Rollback for 1-NIC VDS ..."
Get-AdvancedSetting -Entity $vc -Name "config.vpxd.network.rollback" | Set-AdvancedSetting -Value false -Confirm:$false

Write-Host "Creating vsphere Datacenter ${DatacenterName} ..."
New-Datacenter -Server $vc -Name $DatacenterName -Location (Get-Folder -Type Datacenter -Server $vc)

Write-Host "Creating vsphere Cluster ${ClusterName} ..."
New-Cluster -Server $vc -Name $ClusterName -Location (Get-Datacenter -Name $DatacenterName -Server $vc) -DrsEnabled -HAEnabled

Write-Host "Disabling Network Redudancy Warning ..."
(Get-Cluster -Server $vc $ClusterName) | New-AdvancedSetting -Name "das.ignoreRedundantNetWarning" -Type ClusterHA -Value $true -Confirm:$false

Write-Host "Adding ESXi host ${ESXi1Hostname} ..."
Add-VMHost -Server $vc -Location (Get-Cluster -Name $ClusterName) -User "root" -Password $ESXiPassword -Name $ESXi1Hostname -Force

Write-Host "Adding ESXi host ${ESXi2Hostname} ..."
Add-VMHost -Server $vc -Location (Get-Cluster -Name $ClusterName) -User "root" -Password $ESXiPassword -Name $ESXi2Hostname -Force

Write-Host "Creating Distributed Virtual Switch ${VDSName} ..."
New-VDSwitch -Server $vc -Name $VDSName -Location (Get-Datacenter -Name $DatacenterName) -NumUplinkPorts 1

Write-Host "Creating Distributed Portgroup ${VDSManagementPG} ..."
New-VDPortgroup -Server $vc -Name $VDSManagementPG -Vds (Get-VDSwitch -Server $vc -Name $VDSName) -PortBinding Ephemeral

