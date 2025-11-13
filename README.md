# Ansible Lab

This repository contains an Ansible lab setup used for learning, experimenting, and testing infrastructure automation concepts. It uses **Vagrant**, **Libvirt**, and **Ansible** to create a small cluster of virtual machines for running playbooks, configuration management, and orchestration exercises.

---

## Project Overview

The goal of this lab is to: 
- Build hands-on familiarity with **Ansible basics**.
- Practice **infrastrucutre as code** using Vagrant and Libvirt.
- Experiment with **playbooks**, **inventory management**, and **roles**.
- Explore **dynamic inventory**, **templating**, and **user-management**.

| Node       | Role         | Description                          |
|-------------|--------------|--------------------------------------|
| head    | Controller   | Runs Ansible and manages other nodes |
| compute1    | Worker Node  | Target node for Ansible tasks        |
| compute2    | Worker Node  | Target node for Ansible tasks        |


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
Before executing your ansible commands, you may need to run the `update_ips` script. After this script executes, you will be able to run Step 4: Verify Ansible Connectivity. This script uses `templates/host.j2` to update the `hosts` file with accurtate IPs. Becasue our VM's IPs are generated dynamically with each build, this [jinja](https://jinja.palletsprojects.com/en/stable/) templated file loads the correct VM IP information into our `hosts` file.
```
sh update_ips.sh
```

### Example Playbooks
- `motd.yml` Configures a message of the day (MOTD) banner for all nodes
- `create_users.yml` Creates local users on each node

Run any playbook with:
```bash
ansible-playbook -i hosts <playbook-name.yml>
```

Test different playbooks and how they work by running the playbook, and `vagrant ssh`ing into a node to see the configuration change.

### Troubleshooting

- VM IPs chagne on rebuild, the dynamic inventory playbook should auto-update your `hosts` file
- If SSH connection fails, ensure the VM network is active and autostart is enabled. Use `sudo virsh net-list --all` to see network information.
