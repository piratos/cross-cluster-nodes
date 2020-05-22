# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  os = "ubuntu/bionic64"
  net_ip = "192.168.2"
  config.vm.define :master, primary: true do |master_config|
    master_config.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "master"
    end

    master_config.vm.box = "#{os}"
    master_config.vm.host_name = "master"
    master_config.vm.network "private_network", ip: "#{net_ip}.2"
    master_config.vm.synced_folder "common", "/srv/common"
    master_config.vm.synced_folder "master", "/srv/master"
  end
  config.vm.provision "file", source: "ssh/key", destination: "/home/vagrant/.ssh/id_rsa"
  config.vm.provision "file", source: "ssh/key.pub", destination: "/home/vagrant/.ssh/id_rsa.pub"
  config.vm.provision "shell", inline: <<-SHELL
    cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
  SHELL

  config.vm.define "worker" do |worker_config|
    worker_config.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
      vb.name = "worker"
    end

    worker_config.vm.box = "#{os}"
    worker_config.vm.host_name = "worker"
    worker_config.vm.network "private_network", ip: "#{net_ip}.3"
    worker_config.vm.synced_folder "common", "/srv/common"
    worker_config.vm.synced_folder "worker", "/srv/worker"
  end
  config.vm.provision "file", source: "ssh/key", destination: "/home/vagrant/.ssh/id_rsa"
  config.vm.provision "file", source: "ssh/key.pub", destination: "/home/vagrant/.ssh/id_rsa.pub"
  config.vm.provision "shell", inline: <<-SHELL
    cat /home/vagrant/.ssh/id_rsa.pub >> /home/vagrant/.ssh/authorized_keys
  SHELL
end
