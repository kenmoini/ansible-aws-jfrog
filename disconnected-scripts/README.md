# Script to configure disconnected environments

## Requirements for jumpbox
* Ansible 
```
sudo subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
sudo dnf install ansible
```
* Podman
```
sudo dnf module install -y container-tools
```
* Set up for rootless containers
```
# sudo yum install slirp4netns podman -y
# sudo tee -a /etc/sysctl.d/userns.conf > /dev/null <<EOT
user.max_user_namespaces=28633
EOT
# sudo sysctl -p /etc/sysctl.d/userns.conf
```
* jq 
```
sudo dnf install jq -y
```
* libvirt for mirror-ocp-full.sh 
```
sudo dnf install libvirt -y
```

## Configure jfrog Repo for Script
[Jfrog pre-configuration](jfrog-preflight.md)

# To mirror an OpenShift release to Quay
* replace password with generated password for output
```
sed -i 's/PASSWORD="CHANGEME"/PASSWORD=PASSWORD_OUTPUT/g' mirror-ocp-release.sh
```

* run the mirror-ocp-release.sh script
```
./mirror-ocp-release.sh
```

# To mirror an OpenShift release and host OpenShift Binaries for UBI deployments
* replace password with generated password for output
```
sed -i 's/PASSWORD="CHANGEME"/PASSWORD=PASSWORD_OUTPUT/g' mirror-ocp-full.sh
```

* run the ./mirror-ocp-full.sh
```
./mirror-ocp-full.sh
```

# To mirror an OpenShift release and host OpenShift Binaries for assisted installer deployments
* replace jfrog endpoint
```
sed -i 's/LOCAL_REGISTRY=.*/LOCAL_REGISTRY=YOUR_JFROG_URL/g' mirror-ocp-full.sh
```
* replace username
```
sed -i 's/USERNAME=.*/USERNAME=YOUR_USERNAME/g' mirror-ocp-full.sh
```
* replace password with current password
```
sed -i 's/PASSWORD=.*/PASSWORD=YOUR_PASSWORD/g' mirror-ocp-full.sh
```
* run the get-ai-svc-version.sh
> create `vim  $HOME/rh-api-offline-token` is the token generated from this page: https://access.redhat.com/management/api
```
./get-ai-svc-version.sh
```

* run the ./mirror-ocp-full.sh
```
./mirror-ocp-full.sh
```
