# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Use a box that supports the libvirt provider
  config.vm.box = "generic/ubuntu2204"
  config.vm.provider :libvirt do |libvirt|
    libvirt.memory = 2048
    libvirt.cpus = 2
  end


  BOX_NAME = "generic/ubuntu2204"
  NETWORK_TYPE = "dhcp"


  config.vm.define "headnode" do |head|
    head.vm.box = BOX_NAME
    head.vm.hostname = "headnode"
    head.vm.network "private_network", type: NETWORK_TYPE

    head.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end

    head.vm.provision "shell", inline: <<-SHELL
      apt-get update -y
      apt-get upgrade -y
      apt-get install -y openssh-server ansible python3
      systemctl enable --now ssh
    SHELL
  end

  (1..2).each do |i|
    config.vm.define "compute#{i}" do |compute|
      compute.vm.box = BOX_NAME
      compute.vm.hostname = "compute#{i}"
      compute.vm.network "private_network", type: NETWORK_TYPE

      compute.vm.provider :libvirt do |libvirt|
        libvirt.memory = 1024
        libvirt.cpus = 1
      end

      compute.vm.provision "shell", inline: <<-SHELL
        apt-get update -y
        apt-get upgrade -y
        apt-get install -y openssh-server ansible python3
        systemctl enable --now ssh
      SHELL
    end
  end
end
