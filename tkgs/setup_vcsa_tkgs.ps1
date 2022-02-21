$VCSAHostname = "vcsa.tanzu.local"
$VCSAUsername = "administrator@vsphere.local"
$VCSAPassword = "topSecretPassword"
$DatacenterName = "Tanzu-Datacenter"
$DatastoreName = "datastore1"
$ClusterName = "Tanzu-Cluster"
$ESXiHostname = "esxi-01.tanzu.local"
$ESXiPassword = "topSecretPassword"
$VDSName = "VDS"
$VDSManagementPG = "Management"
$VDSFrontendPG = "Frontend"
$VDSWorkloadPG = "Workload"
$StoragePolicyName = "Tanzu-Storage-Policy"
$StoragePolicyCategory = "WorkloadType"
$StoragePolicyTag = "Tanzu"

$vc = Connect-VIServer $VCSAHostname -User $VCSAUsername -Password $VCSAPassword

Write-Host "Creating vsphere Tag Category `"${StoragePolicyCategory}`" and vsphere Tag `"${StoragePolicyTag}`" for Storage Policy `"${StoragePolicyName}`" ... "
New-TagCategory -Server $vc -Name $StoragePolicyCategory -Cardinality single -EntityType Datastore
New-Tag -Server $vc -Name $StoragePolicyTag -Category $StoragePolicyCategory
Get-Datastore -Server $vc -Name $DatastoreName | New-TagAssignment -Server $vc -Tag $StoragePolicyTag
New-SpbmStoragePolicy -Server $vc -Name $StoragePolicyName -AnyOfRuleSets (New-SpbmRuleSet -Name "tanzu-ruleset" -AllOfRules (New-SpbmRule -AnyOfTags (Get-Tag $StoragePolicyTag)))
