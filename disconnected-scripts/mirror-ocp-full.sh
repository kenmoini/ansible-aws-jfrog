#!/bin/bash
# Still in development 
# `curl -X POST -vu ${USERNAME}:${PASSWORD} https://${LOCAL_REGISTRY}/artifactory/ui/jcr/eula/accept`
set -xe

# Variables
export PULL_SECRET_JSON=~/pull_secret.json
export LOCAL_SECRET_JSON=~/merged-pull-secret.json
export LOCAL_REGISTRY=jfrog.example.com
export LOCAL_REPOSITORY=ocp4/ocp4
export OCP_REGISTRY=quay.io/openshift-release-dev/ocp-release
export EMAIL="admin@changeme.com"
export PASSWORD="CHANGEME"
export USERNAME="CHANGEME"
export AUTH="$(echo -n '${USERNAME}:${PASSWORD}' | base64 -w0)" # in base 64
export TLS_VERIFY=false
export VERSION=latest # for 4.9 release use latest-4.9
# Functional

function create_merge_secret(){
    if [ -f ${PULL_SECRET_JSON} ];
    then 

        cat <<EOF > ~/reg-secret.txt
"${LOCAL_REGISTRY}": {
    "email":  "${EMAIL}",
    "auth": "${AUTH}"
}
EOF

        cat ${PULL_SECRET_JSON} |jq ".auths += {`cat ~/reg-secret.txt`}"|tr -d '[:space:]' > ${LOCAL_SECRET_JSON}
    else
        echo "${PULL_SECRET_JSON} not found please add"
        echo "Plese go to https://console.redhat.com/openshift/install/"
        exit 
    fi  
}

function login_to_registry(){
podman login --authfile ~/merged-pull-secret.json \
  -u ${USERNAME} \
  -p ${PASSWORD} \
  ${LOCAL_REGISTRY} \
  --tls-verify=${TLS_VERIFY} -v || exit 1
}

function ocp_mirror_release() {
    echo "----> Mirroring OCP Release: ${OCP_RELEASE}"
    if [ ${TLS_VERIFY} == "false" ];
    then 
       USE_INSECURE="true"
    else
       USE_INSECURE="false"
    fi 
	oc adm -a ${LOCAL_SECRET_JSON} release mirror \
		--from=${OCP_REGISTRY}:${OCP_RELEASE} \
		--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
		--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE} --insecure=${USE_INSECURE}
}

function download_oc_latest_client() {
	if [[ ! -f /usr/bin/oc ]]; then
		curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/pre-steps/configure-openshift-packages.sh
        chmod +x configure-openshift-packages.sh
        ./configure-openshift-packages.sh -i
		#https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/release.txt
		export OCP_RELEASE=$(oc version | awk '{print $3}')-x86_64
	else 
		export OCP_RELEASE=$(oc version | awk '{print $3}')-x86_64
	fi
}


function download_ipi_installer() {
	echo "----> Downloading IPI Installer"
	oc adm --registry-config ${PULL_SECRET_JSON} release extract \
		--command=openshift-baremetal-install \
		--from=${OCP_REGISTRY}:${OCP_RELEASE} \
		--to .

	if [[ ! -f openshift-baremetal-install ]]; then
		echo "OCP Installer wasn't extracted, exiting..."
		exit 1
	fi

	sudo mv openshift-baremetal-install /usr/bin/openshift-baremetal-install
}

function download_rhcos() {
	export RHCOS_VERSION=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["release"]')
	export RHCOS_ISO_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["formats"]["iso"]["disk"]["location"]')
	export RHCOS_ROOT_FS=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["metal"]["formats"]["pxe"]["rootfs"]["location"]')
	export RHCOS_QEMU_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["qemu"]["formats"]["qcow2.gz"]["disk"]["location"]')
	export RHCOS_QEMU_SHA_UNCOMPRESSED=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["qemu"]["formats"]["qcow2.gz"]["disk"]["uncompressed-sha256"]')
	export RHCOS_OPENSTACK_URI=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["openstack"]["formats"]["qcow2.gz"]["disk"]["location"]')
	export RHCOS_OPENSTACK_SHA_COMPRESSED=$(openshift-baremetal-install coreos print-stream-json | jq -r '.["architectures"]["x86_64"]["artifacts"]["openstack"]["formats"]["qcow2.gz"]["disk"]["sha256"]')
	export OCP_RELEASE_DOWN_PATH=${HOME}/rhcos

	echo "RHCOS_VERSION: $RHCOS_VERSION"
	echo "RHCOS_OPENSTACK_URI: $RHCOS_OPENSTACK_URI"
	echo "RHCOS_OPENSTACK_SHA_COMPRESSED: ${RHCOS_OPENSTACK_SHA_COMPRESSED}"
	echo "RHCOS_QEMU_URI: $RHCOS_QEMU_URI"
	echo "RHCOS_QEMU_SHA_UNCOMPRESSED: $RHCOS_QEMU_SHA_UNCOMPRESSED"
	echo "RHCOS_ISO_URI: $RHCOS_ISO_URI"
	echo "RHCOS_ROOT_FS: $RHCOS_ROOT_FS"
	#echo "Press Enter to continue or Ctrl-C to cancel download"
	#read

	if [[ ! -d ${OCP_RELEASE_DOWN_PATH} ]]; then
		echo "----> Downloading RHCOS resources to ${OCP_RELEASE_DOWN_PATH}"
		sudo mkdir -p ${OCP_RELEASE_DOWN_PATH}
		echo "--> Downloading RHCOS resources: RHCOS QEMU Image"
		sudo curl -s -L -o ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_QEMU_URI | xargs basename) ${RHCOS_QEMU_URI}
		curl -X PUT -u ${USERNAME}:${PASSWORD} -T  ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_QEMU_URI | xargs basename) "https://${LOCAL_REGISTRY}/artifactory/libs-release-local/$RHCOS_VERSION/$(echo $RHCOS_QEMU_URI | xargs basename)"
		echo "--> Downloading RHCOS resources: RHCOS Openstack Image"
		sudo curl -s -L -o ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_OPENSTACK_URI | xargs basename) ${RHCOS_OPENSTACK_URI}
		curl -X PUT -u ${USERNAME}:${PASSWORD} -T  ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_OPENSTACK_URI | xargs basename) "https://${LOCAL_REGISTRY}/artifactory/libs-release-local/$RHCOS_VERSION/$(echo $RHCOS_OPENSTACK_URI | xargs basename)"
		echo "--> Downloading RHCOS resources: RHCOS ISO"
		sudo curl -s -L -o ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_ISO_URI | xargs basename) ${RHCOS_ISO_URI}
		curl -X PUT -u ${USERNAME}:${PASSWORD} -T  ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_ISO_URI | xargs basename) "https://${LOCAL_REGISTRY}/artifactory/libs-release-local/$RHCOS_VERSION/$(echo $RHCOS_ISO_URI | xargs basename)"
		echo "--> Downloading RHCOS resources: RHCOS RootFS"
		sudo curl -s -L -o ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_ROOT_FS | xargs basename) ${RHCOS_ROOT_FS}
		curl -X PUT -u ${USERNAME}:${PASSWORD} -T  ${OCP_RELEASE_DOWN_PATH}/$(echo $RHCOS_ROOT_FS | xargs basename) "https://${LOCAL_REGISTRY}/artifactory/libs-release-local/$RHCOS_VERSION/$(echo $RHCOS_ROOT_FS | xargs basename)"
	else
		echo "The folder already exist, so delete it if you want to re-download the RHCOS resources"
	fi
}

function format_images_config() {
	echo """
      Add the following to install-config.yaml

        bootstrapOSImage: http://${LOCAL_REGISTRY}/artifactory/libs-release-local/${RHCOS_QEMU_URI##*/}?sha256=$RHCOS_QEMU_SHA_UNCOMPRESSED
        clusterOSImage: http://${LOCAL_REGISTRY}/artifactory/libs-release-local/${RHCOS_OPENSTACK_URI##*/}?sha256=$RHCOS_OPENSTACK_SHA_COMPRESSED
     """
}


create_merge_secret
login_to_registry
download_oc_latest_client
ocp_mirror_release
download_ipi_installer
download_rhcos
