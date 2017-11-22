#!/bin/bash

# Details of the server that will host the images
SRV_USERNAME=ovirt-demo-tool
SRV_HOSTNAME=templates.ovirt.org
SRV_PATH=/var/www/html/bundles/ovirt-demo-tool/master/unstable

# Lago templates will be downloaded from here
TEMPLATE_REPO_PATH=http://templates.ovirt.org/repo/repo.metadata

# Will be used in the VMs names
SUITE_NAME=ovirt-orb-master
# Will be used for the archive name
ARTIFACT_NAME=ovirt-orb

# oVirt version to install
RELEASE_RPM=http://resources.ovirt.org/pub/yum-repo/ovirt-release-master.rpm

# Will be used in LagoInitFile
ENGINE_TEMPLATE=el7.4-base
HOST_TEMPLATE=el7.4-base
HOST_COUNT=2
