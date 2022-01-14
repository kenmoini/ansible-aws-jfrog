# JFrog on AWS

This set of Ansible Automation content will create an EC2 VM in AWS, running RHEL, and deploy JFrog Container Registry via Podman.

## Prerequisites

- Install Ansible
- Install needed pip modules: `pip3 install -r ./requirements.txt`
- Install needed Ansible Collections: `ansible-galaxy collection install -r ./collections/requirements.yml`
- Copy & Modify Variables: `cp vars/example.main.yml vars/main.yml`

## Create AWS Infrastructure & Deploy JFrog

```bash
ansible-playbook aws-bootstrap.yml
```