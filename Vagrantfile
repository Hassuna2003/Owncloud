Vagrant.configure("2") do |config|
  config.vm.box = "debian/bullseye64"

config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
  end

  # Capa 1: Balanceador
  config.vm.define "balanceadorJosein" do |app|
    app.vm.hostname = "balanceadorJosein"
    app.vm.network "public_network"
    app.vm.network "private_network", ip: "192.168.10.10", virtualbox__intnet: "red1"
    app.vm.network "forwarded_port", guest: 80, host: 8080
    #app.vm.provision "shell", path: "balanceador.sh"
  end

  # Capa 2: BackEnd - ServerNFS
  config.vm.define "serverNFSJosein" do |app|
    app.vm.hostname = "serverNFSJosein"
    app.vm.network "private_network", ip: "192.168.10.20", virtualbox__intnet: "red1"
    app.vm.network "private_network", ip: "192.168.20.50", virtualbox__intnet: "red2"
    #app.vm.provision "shell", path: "nfs.sh"
  end

  # Capa 2: BackEnd - Web 1
  config.vm.define "serverweb1Josein" do |app|
    app.vm.hostname = "serverweb1Josein"
    app.vm.network "private_network", ip: "192.168.10.30", virtualbox__intnet: "red1"
    app.vm.network "private_network", ip: "192.168.20.30", virtualbox__intnet: "red2"
    #app.vm.provision "shell", path: "serverweb1.sh"
  end

  # Capa 2: BackEnd - Web 2
  config.vm.define "serverweb2Josein" do |app|
    app.vm.hostname = "serverweb2Josein"
    app.vm.network "private_network", ip: "192.168.10.31", virtualbox__intnet: "red1"
    app.vm.network "private_network", ip: "192.168.20.31", virtualbox__intnet: "red2"
    #app.vm.provision "shell", path: "serverweb2.sh"
  end

  # Capa 3: Base de Datos
  config.vm.define "serverdatosJosein" do |app|
    app.vm.hostname = "serverdatosJosein"
    app.vm.network "private_network", ip: "192.168.20.40", virtualbox__intnet: "red2"
    #app.vm.provision "shell", path: "bbdd.sh"
  end

  config.ssh.insert_key = false
  config.ssh.forward_agent = false
end
