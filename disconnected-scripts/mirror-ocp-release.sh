#!/bin/bash
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
  --tls-verify=${TLS_VERIFY} 
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
	oc adm -a ${LOCAL_SECRET_JSON} release mirror \
		--from=quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE} \
		--to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
		--to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/ocp-release:${OCP_RELEASE} --insecure=${USE_INSECURE}
	cat >${OCP_RELEASE}-clusterimageset.yaml<<EOF
	---
	apiVersion: hive.openshift.io/v1
	kind: ClusterImageSet
	metadata:
	  name: openshift-v$(oc version | awk '{print $3}')
	  namespace: open-cluster-management
	spec:
	  releaseImage: ${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}/ocp-release:${OCP_RELEASE}
EOF
}

function download_oc_latest_client() {
	if [[ ! -f /usr/bin/oc ]]; then
		curl -OL https://raw.githubusercontent.com/tosin2013/openshift-4-deployment-notes/master/pre-steps/configure-openshift-packages.sh
        chmod +x configure-openshift-packages.sh
        ./configure-openshift-packages.sh -i
		#https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest/release.txt

		if [ -f ${HOME}/cluster-versions.json ];
		then 
			VARIABLE=$(oc version | awk '{print $3}')
			echo ${VARIABLE::4}
			AI_OC_RELEASE=$(cat cluster-versions.json | jq '.[]|.display_name'  | grep ${VARIABLE::4} | head -1 | tr -d '"')
			export OCP_RELEASE=${AI_OC_RELEASE}-x86_64
		else 
			export OCP_RELEASE=$(oc version | awk '{print $3}')-x86_64
		fi 	
	else 
		if [ -f ${HOME}/cluster-versions.json ];
		then 
			VARIABLE=$(oc version | awk '{print $3}')
			echo ${VARIABLE::3}
			AI_OC_RELEASE=$(cat cluster-versions.json | jq '.[]|.display_name'  | grep ${VARIABLE::3} | head -1 | tr -d '"')
			export OCP_RELEASE=${AI_OC_RELEASE}-x86_64
		else 
			export OCP_RELEASE=$(oc version | awk '{print $3}')-x86_64
		fi 
	fi
}


create_merge_secret
login_to_registry
download_oc_latest_client
ocp_mirror_release
