Connect-VIServer -Server vcsa.tanzu.local -User 'administrator@vsphere.local' -Password 'topSecretPassword'
Connect-CisServer -Server vcsa.tanzu.local -User 'administrator@vsphere.local' -Password 'topSecretPassword'
Import-Module VMware.WorkloadManagement

$vsphereWithTanzuParams = @{
    ClusterName = "Tanzu-Cluster";
    TanzuvCenterServer = "vcsa.tanzu.local";
    TanzuvCenterServerUsername = "administrator@vsphere.local";
    TanzuvCenterServerPassword = "topSecretPassword";
    TanzuContentLibrary = "TKG-Content-Library";
    ControlPlaneSize = "TINY";
    MgmtNetwork = "Management";
    MgmtNetworkStartIP = "192.168.1.15";
    MgmtNetworkSubnet = "255.255.255.0";
    MgmtNetworkGateway = "192.168.1.1";
    MgmtNetworkDNS = @("192.168.1.10");
    MgmtNetworkDNSDomain = "tanzu.local";
    MgmtNetworkNTP = @("nl.pool.ntp.org");
    WorkloadNetwork = "Workload";
    WorkloadNetworkStartIP = "10.20.0.10";
    WorkloadNetworkIPCount = 20;
    WorkloadNetworkSubnet = "255.255.255.0";
    WorkloadNetworkGateway = "10.20.0.1";
    WorkloadNetworkDNS = @("192.168.1.10");
    WorkloadNetworkServiceCIDR = "10.96.0.0/24";
    StoragePolicyName = "Tanzu-Storage-Policy";
    HAProxyVMvCenterServer = "vcsa.tanzu.local";
    HAProxyVMvCenterUsername = "administrator@vsphere.local";
    HAProxyVMvCenterPassword = "topSecretPassword";
    HAProxyVMName = "haproxy.tanzu.local";
    HAProxyIPAddress = "192.168.1.12";
    HAProxyRootPassword = "topSecretPassword";
    HAProxyUsername = "wcp";
    HAProxyPassword = "topSecretPassword";
    LoadBalancerStartIP = "10.10.0.64";
    LoadBalancerIPCount = 64
}

New-WorkloadManagement2 @vsphereWithTanzuParams
