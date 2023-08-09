Vagrant.configure("2") do |config|
  ip_prefix= "192.168.100.1"

  # workers config
  workers = 3
  (1..workers).each do |i|
    config.vm.define "worker#{i}" do |worker|
      worker.vm.box = "almalinux/8"
      worker.vm.hostname = "worker#{i}"
      worker.vm.network :private_network, ip: "#{ip_prefix}#{i}"
      worker.vm.provider :virtualbox do |vb|
        vb.name = "worker#{i}"
        vb.memory = 2048
        vb.cpus = 1
      end
      worker.vm.synced_folder "./data", "/vagrant_data"
      worker.vm.provision "shell", path: "./scripts/install_prerequisite.sh"
    end
  end

  # master config
  i = 0
  config.vm.define "master" do |master|
    master.vm.box = "almalinux/8"
    master.vm.hostname = "master"
    master.vm.network :private_network, ip: "#{ip_prefix}#{i}"
    master.vm.provider :virtualbox do |vb|
      vb.name = "master"
      vb.memory = 2048
      vb.cpus = 3
    end
    master.vm.synced_folder "./data", "/vagrant_data"
    master.vm.provision "shell", path: "./scripts/install_prerequisite.sh"
    master.vm.provision "shell", path: "./scripts/install_kubernetes_cluster.sh"
  end
end
