# JFrog on AWS

This set of Ansible Automation content will create an EC2 VM in AWS, running RHEL, and deploy JFrog Container Registry via Podman, fronted by HAProxy and optionally certbot for SSL.

## Prerequisites

- Install Ansible
- Install needed pip modules: `pip3 install -r ./requirements.txt`
- Install needed Ansible Collections: `ansible-galaxy collection install -r ./collections/requirements.yml`
- Copy & Modify Variables: `cp vars/example.main.yml vars/main.yml`

## Create AWS Infrastructure & Deploy JFrog

```bash
ansible-playbook aws-bootstrap.yml
```

If using the playbook with a non-AWS instance or one that is already created then make an inventory file as such, substituting the needed variables to match the target:

```ini
[jfrog]
jfrog.example.com ansible_user=ec2-user ansible_connection=ssh ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_python_interpreter='/usr/libexec/platform-python' ansible_ssh_private_key_file="~/.ssh/id_rsa" base_domain="example.com" env_email_owner="you@example.com"
```

Then run the playbook as follows:

```bash
ansible-playbook -i yourInventoryFile aws-bootstrap.yml --skip-tags=rhoe_aws,aws_infra
```

## Available Tags

- `include_vars` - Tasks for including the `vars/main.yml` file - useful for when deploying from Tower
- `rhoe_aws` - Tasks for querying Red Hat Open Environments AWS accounts
- `aws_infra` - All tasks for modifying AWS Infrastructure
- `aws_sg` - Tasks for setting up Security Groups in AWS
- `aws_ec2_key` - Tasks for creating an EC2 SSH Key in AWS
- `aws_query` - Tasks for querying AWS facts, such as finding the latest RHEL AMI
- `aws_ec2` - Tasks for creating EC2 VMs in AWS
- `aws_map_dns_records` - Tasks for setting facts for DNS Records in Route53
- `aws_route53` - Tasks for creating records in Route53
- `aws_add_host` - Tasks for adding the newly created EC2 instance to a new inventory group
- `deploy_jfrog_all` - Tasks for configuring the RHEL VM with JFrog Container Registry

## Post-deployment

There are some manual steps post-deployment - Artifactory Pro allows REST API access.

- Log in with default credentials, walk through the OOTB Wizard to set the base URL and new credentials
- Create a Local Repository - Docker type, Repository Key of whatever you're naming the repo (like `library`, `olm-mirror`, `ocp-release-mirror`, etc), with a Docker Tag Retention of 4096.
- Under ***Identity and Access > Users*** create a user to pull/push from the created Repositories