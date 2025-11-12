# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base box compatible with libvirt
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_check_update = true

  # Disable default synced folder to speed up and avoid prompts
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Define machines
  nodes = {
    "head" => { memory: 2048, cpus: 2 },
    "compute1" => { memory: 2048, cpus: 2 },
    "compute2" => { memory: 2048, cpus: 2 }
  }

  nodes.each do |name, opts|
    config.vm.define name do |node|
      node.vm.hostname = name

      # Provider-specific configuration for libvirt
      node.vm.provider :libvirt do |lv|
        lv.memory = opts[:memory]
        lv.cpus   = opts[:cpus]
        # Uncomment to adjust storage size, network, etc.
        # lv.storage :file, :size => '20G'
        # node.vm.network "private_network", ip: "192.168.121.10", libvirt__network_name: "vagrant-libvirt"
      end

      # Ensure Python is present for Ansible on minimal images
      node.vm.provision "shell", inline: <<-SHELL
        set -eux
        if command -v apt-get >/dev/null 2>&1; then
          sudo apt-get update -y
          sudo apt-get install -y python3
        elif command -v dnf >/dev/null 2>&1; then
          sudo dnf install -y python3
        elif command -v yum >/dev/null 2>&1; then
          sudo yum install -y python3
        fi
      SHELL
    end
  end

  # Run Ansible once after all machines are up
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "site.yml"
    ansible.become = true
    ansible.limit = "all"

    # Group machines for targeted plays
    ansible.groups = {
      "head" => ["head"],
      "compute" => ["compute1", "compute2"]
    }

    # Increase verbosity if needed: "v", "vv", "vvv"
    # ansible.verbose = 'v'
  end
end
