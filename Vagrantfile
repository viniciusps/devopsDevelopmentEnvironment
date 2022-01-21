# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
Vagrant.require_version ">= 2.0.0"

# just a single node is required
NODES = ENV['NODES'] || 1

# Memory & CPUs
MEM = ENV['MEM'] || 8000
CPUS = ENV['CPUS'] || 4

# User Data Mount
#SRCDIR = ENV['SRCDIR'] || "/home/"+ENV['USER']+"/test"
SRCDIR = ENV['SRCDIR'] || "/tmp/vagrant"
DSTDIR = ENV['DSTDIR'] || "/home/vagrant/data"

# Management
GROWPART = ENV['GROWPART'] || "true"

# Minikube Variables
KUBERNETES_VERSION = ENV['KUBERNETES_VERSION'] || "1.18.16"

required_plugins = %w(vagrant-sshfs vagrant-vbguest)

required_plugins.each do |plugin|
  need_restart = false
  unless Vagrant.has_plugin? plugin
    system "vagrant plugin install #{plugin}"
    need_restart = true
  end
  exec "vagrant #{ARGV.join(' ')}" if need_restart
end


def configureVM(vmCfg, hostname, cpus, mem, srcdir, dstdir)

  vmCfg.vm.box = "roboxes/ubuntu1804"

  vmCfg.vm.hostname = hostname
  vmCfg.vm.network "private_network", type: "dhcp",  bridge: "vboxnet0", :model_type => "virtio", :autostart => true

  vmCfg.vm.synced_folder '.', '/vagrant', disabled: true
  # sync your laptop's development with this Vagrant VM
  vmCfg.vm.synced_folder srcdir, dstdir, type: "rsync", rsync__exclude: ".git/", create: true

  vmCfg.vm.provider "virtualbox" do |provider, override|
    provider.memory = mem
    provider.cpus = cpus


    override.vm.synced_folder srcdir, dstdir, type: 'sshfs', ssh_opts_append: "-o Compression=yes", sshfs_opts_append: "-o cache=no", disabled: false, create: true
  end

  vmCfg.vm.provider "virtualbox" do |provider, override|
    provider.memory = mem
    provider.cpus = cpus
    provider.customize ["modifyvm", :id, "--cableconnected1", "on"]

    override.vm.synced_folder srcdir, dstdir, type: 'virtualbox', create: true
  end

  # ensure docker is installed # Use our script so we can get a proper support version
  vmCfg.vm.provision "shell", path: "scripts/install_docker.sh", privileged: false
  # Script to prepare the VM
  vmCfg.vm.provision "shell", path: "scripts/custom.sh", privileged: false
  vmCfg.vm.provision "shell", path: "scripts/growpart.sh", privileged: false if GROWPART == "true"
  vmCfg.vm.provision "shell", path: "scripts/install_misc_tools.sh", privileged: false, env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION}
  vmCfg.vm.provision "shell", path: "scripts/install_minikube.sh", privileged: false, env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION}
  vmCfg.vm.provision "shell", inline: "/home/vagrant/start_minikube.sh", privileged: false, env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION}
  vmCfg.vm.provision "shell", path: "scripts/minikube_ingress.sh", privileged: false
  vmCfg.vm.provision "shell", path: "scripts/install_argocd.sh", privileged: false
  vmCfg.vm.provision "shell", path: "scripts/install_strimzi.sh", privileged: false
  vmCfg.vm.provision "shell", inline: "/home/vagrant/stop_minikube.sh", privileged: false

  return vmCfg
end

# Entry point of this Vagrantfile
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vbguest.auto_update = false

  1.upto(NODES.to_i) do |i|
    hostname = ENV['VAGRANT_HOSTNAME'].to_s + "-%02d" % [i]
    cpus = CPUS
    mem = MEM
    srcdir = SRCDIR
    dstdir = DSTDIR

    config.vm.define hostname do |vmCfg|
      vmCfg = configureVM(vmCfg, hostname, cpus, mem, srcdir, dstdir)
    end

    config.trigger.after :up do |trigger|
      trigger.info = "Starting minikube"
      trigger.run = {inline: 'vagrant ssh -c /home/vagrant/start_minikube.sh', env: {"KUBERNETES_VERSION" => KUBERNETES_VERSION}}
    end
  end

end
