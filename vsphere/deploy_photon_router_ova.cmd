set PhotonOVA=c:\path\to\photon-hw13_uefi-3.0-a383732.ova
set PhotonRouterVMName=router.tanzu.local
set ESXiHostname=esxi01.tanzu.local
set ESXiUsername=root
set ESXiPassword=topSecretPassword
set PhotonRouterNetwork=VM Network
set PhotonRouterDatastore=datastore1

c:\progra~1\vmware\vmware~2\ovftool --name=%PhotonRouterVMName% --X:waitForIpv4 --powerOn --acceptAllEulas --noSSLVerify --datastore=%PhotonRouterDatastore% --net:"None=%PhotonRouterNetwork%" %PhotonOVA% vi://%ESXiUsername%:%ESXiPassword%@%ESXiHostname%
