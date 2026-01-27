# Ansible Lab

This repository contains an Ansible lab setup used for learning, experimenting, and testing infrastructure automation concepts. It uses **Vagrant**, **Libvirt**, and **Ansible** to create a small cluster of virtual machines for running playbooks, configuration management, and orchestration exercises.

---

## Project Overview

The goal of this lab is to: 
- Build hands-on familiarity with **Ansible basics**.
- Practice **infrastrucutre as code** using Vagrant and Libvirt.
- Experiment with **playbooks**, **inventory management**, and **roles**.
- Explore **dynamic inventory**, **templating**, and **user-management**.

| Node        | Role         | Description                          |
|-------------|--------------|--------------------------------------|
| head        | Controller / Wazuh Server | Runs Ansible, manages other nodes, hosts Wazuh SIEM |
| compute1    | Worker Node  | Target node for Ansible tasks        |
| compute2    | Worker Node  | Target node for Ansible tasks        |
| webserver   | Apache Node  | Runs Apache web server               |

## Getting Started

### Prerequisites

You'll need:
- libvirt qemu kvm
- ansible vagrant

### Step 1: Clone the repository
```bash
git clone git@github.com:chloegerhardson/ansible_lab.git
cd ansible_lab
```

### Step 2: Bring Up the VMs
```bash
vagrant up
```

Vagrant will create:
- `head`
- `compute1`
- `compute2`
- `webserver`

Each VM is managed by `libvirt`

### Step 3: Check VM Status
```bash
vagrant status
```

You can ssh into a node:
```bash
vagrant ssh <node-name>
```

### Step 4: Verify Ansible Connectivity
```bash
ansible -i hosts all -m ping
```

### Step 4.0: Update IPs
Before executing your ansible commands, you may need to run the `update_ips` script. After this script executes, you will be able to run Step 4: Verify Ansible Connectivity. This script is based on `playbooks/templates/host.j2` to update the `hosts` file with accurtate IPs. Becasue our VM's IPs are generated dynamically with each build, this [jinja](https://jinja.palletsprojects.com/en/stable/) templated file loads the correct VM IP information into our `hosts` file.
```
sh update_ips.sh
```

### Example Playbooks
- `site.yml` Serves as the main entry point, gets run during Vagrant build, and imports `setup.yml` to install Python and other packages on the nodes.
- `setup.yml` Gets imported to `site.yml` to install basic packages.
- `motd.yml` Configures a message of the day (MOTD) banner for all nodes
- `create_users.yml` Creates local users on each node
- `sys_info.yml` Provides system information for each node
- `deploy_homepage.yml` Deploys a basic Apache server and homepage. Visit the page by vagrant-ssh-ing into the `webserver` node and running `hostname -I` to get it's IP, and then visit `http://<webserver-ip>` to view the site's contents.
- `install_wazuh_server.yml` Installs Wazuh SIEM (all-in-one) on the head node
- `install_wazuh_agent.yml` Installs Wazuh agents on all other nodes

Run any playbook with:
```bash
ansible-playbook -i hosts <playbooks/playbook-name.yml>
```

Test different playbooks and how they work by running the playbook, and `vagrant ssh`ing into a node to see the configuration change.

---

## Wazuh SIEM Setup

This lab includes playbooks for deploying [Wazuh](https://wazuh.com/), an open-source security monitoring platform (SIEM/XDR).

### Requirements

The Wazuh server requires at least **4GB RAM**. The `head` node is configured with 4GB in the Vagrantfile for this purpose.

### Step 1: Install Wazuh Server

Deploy the all-in-one Wazuh server (indexer + manager + dashboard) on the head node:

```bash
ansible-playbook playbooks/install_wazuh_server.yml
```

This takes 5-10 minutes. Once complete, the playbook will display:
- Dashboard URL: `https://<head-ip>`
- Username: `admin`
- Password: (extracted from install files)

If you need to retrieve the credentials later:
```bash
ansible wazuh_server -m shell -a "tar -O -xf /tmp/wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt" --become
```

### Step 2: Install Wazuh Agents

Deploy agents on all other nodes (compute1, compute2, webserver):

```bash
ansible-playbook playbooks/install_wazuh_agent.yml
```

The agents will automatically connect to the Wazuh server. You can verify agent status in the Wazuh dashboard under **Agents**.

### Accessing the Dashboard

1. Get the head node IP: `vagrant ssh head -c "hostname -I"`
2. Visit `https://<head-ip>` in your browser
3. Accept the self-signed certificate warning
4. Log in with the admin credentials

---

### Troubleshooting

- VM IPs chagne on rebuild, run the `update_ips.sh` script to update the `hosts` file
- If SSH connection fails, ensure the VM network is active and autostart is enabled. Use `sudo virsh net-list --all` to see network information.
- Vagrant may also fail if a node domain is already in use. run `sudo virsh list --all --name` to see a list of domains.
  - run `sudo virsh destroy <domain name>` and `sudo virsh undefine <domain name>` to clear any stale domains in use.
  - clear old machines listed under `./.vagrant/machines/`
  - run `vagrant destroy` and `vagrant up` to fully resolve the issue
