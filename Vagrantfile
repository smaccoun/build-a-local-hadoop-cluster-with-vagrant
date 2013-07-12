Vagrant.configure("2") do |config|
  config.vm.define "hadoop setup"
  config.vm.box = "lucid64"
  
  config.vm.provider :virtualbox do |v, override|
    override.vm.box_url = "http://files.vagrantup.com/lucid64.box"
    v.customize ["modifyvm", :id, "--memory", "256"]
  end

  config.vm.define :hadoop1 do |hadoop1_config|
    hadoop1_config.vm.network :private_network, ip: "192.168.2.11"
    hadoop1_config.vm.hostname = "hadoop1"
  end
  
  config.vm.define :hadoop2 do |hadoop2_config|
    hadoop2_config.vm.network :private_network, ip: "192.168.2.12"
    hadoop2_config.vm.hostname = "hadoop2"
  end
  
  config.vm.define :hadoop3 do |hadoop3_config|
    hadoop3_config.vm.network :private_network, ip: "192.168.2.13"
    hadoop3_config.vm.hostname = "hadoop3"
  end
  
   config.vm.define :master do |master_config|
    master_config.vm.network :private_network, ip: "192.168.2.10"
    master_config.vm.hostname = "master"
  end

end
