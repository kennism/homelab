#!/bin/bash
# William Lam
# www.virtuallyghetto

PhotonOVA="/path/to/photon-hw13_uefi-3.0-a383732.ova"
PhotonRouterVMName="router.tanzu.local"
ESXiHostname="sandbox"
ESXiUsername="root"
ESXiPassword="topSecretPassword"

PhotonRouterNetwork="VM Network"
PhotonRouterDatastore="datastore1"

### DO NOT EDIT BEYOND HERE ###

ovftool \
--name=${PhotonRouterVMName} \
--X:waitForIpv4 \
--powerOn \
--acceptAllEulas \
--noSSLVerify \
--datastore=${PhotonRouterDatastore} \
--net:"None=${PhotonRouterNetwork}" \
${PhotonOVA} \
"vi://${ESXiUsername}:${ESXiPassword}@${ESXiHostname}"