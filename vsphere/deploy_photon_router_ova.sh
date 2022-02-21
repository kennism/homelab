#!/bin/bash
PhotonOVA="/path/to/photon-hw13_uefi-3.0-a383732.ova"
PhotonRouterVMName="router.tanzu.local"
ESXiHostname="esxi01.tanzu.local"
ESXiUsername="root"
ESXiPassword="topSecretPassword"
PhotonRouterNetwork="VM Network"
PhotonRouterDatastore="datastore1"

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
