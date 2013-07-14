Tutorial
==============

> Note: This tutorial is based off of http://cscarioni.blogspot.co.uk/2012/09/setting-up-hadoop-virtual-cluster-with.html

## Why this tutorial exists

What is hadoop? Hadoop is a framework for handling big data. Data that is so big that usually one machine can't support it.
Hadoop therefore makes use of *multiple* machines to handle and process all of that data.

"But what if I don't have access to multiple machines?"

Well, one option might be to rent out some EC2 instances or some other 3rd party servers. But all of
those usually cost some money, and you don't have quite the power to inspect hadoop's internals as if they were all
on your own machine.

The solution is to simulate several servers on your own machine using virtual machines. For each of those VMs, you'll have
to set them up to be configured for hadoop. Sounds like a lot of work, right?

Using [Vagrant] (http://www.vagrantup.com/) and [Puppet] (https://puppetlabs.com/), server configuration is a breeze.
Make sure you have downloaded each, as well as [Virtualbox] (https://www.virtualbox.org/) before starting this tutorial.

## Basic Cluster

With Vagrant you create a file called a Vagrantfile which specifies your server configuration.

`$ touch Vagrantfile`

With hadoop you will store all of your data on what are called **data nodes**. When you want to store your data, hadoop
will first split this data up into smaller chunks called *blocks*, and these blocks will be divided up amongst the data
nodes. A *master node* will then keep track of where these blocks are, along with other meta information about the data.
For this tutorial, we will create 3 data nodes and 1 master node. Lets first just get some basic VMs up and running without
worrying about the hadoop configuration.

Here's the VagrantFile:

```
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
```

Most of this is pretty self-explanatory. If Vagrant can't find the lucid64 base box, it downloads it. You may want to set up
the memory for each server to be more or less depending on how much memory you have available on your computer.
After the base box is added, four servers - 1 master and 3 data (slave) nodes - are spun up. Of course, if you are on Wifi
and internet DHCP server is already using the IP address range, you'll have to change to a different range.

Once the Vagrant file is complete, simply type

`$ vagrant up`

And you've got yourself a basic cluster!

## Adding Hadoop Configurations

So now we have a cluster, but none of the nodes in this cluster are set up to run hadoop. This is where the powerful 
provisioning of Puppet comes in.

First, let's think about the essential files and software we need for Hadoop:

Software
* openjdk-6
* 
Config Files
* core-site.xml
* hadoop-env.sh
* hdfs-site.xml
* mapred-site.xml
* masters
* slaves

Let's start by just getting Puppet to add openjdk-6 to each machine.

`$ mkdir manifests`
`$ vim manifests/base-hadoop.pp`

Your base-hadoop.pp file should look like:

```
#base-hadoop.pp

group { "puppet":
  ensure => "present",
}
  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
}

package { "openjdk-6-jdk" :
   ensure => present,
  require => Exec['apt-get update']
}

package { "vim" :
   ensure => present,
   require => Exec['apt-get update']
}
```

I added vim in there since we'll probably need to go in and edit files at some point. Now we have to get Vagrant
to run Puppet on startup. To do this, add the following lines to your Vagrantfile:

```
...

config.vm.provision :puppet do |puppet|
     puppet.manifests_path = "manifests"
     puppet.manifest_file  = "base-hadoop.pp"
end

...

```

Now run `$ Vagrant reload` and java6 will be installed on all of your VM's. This may take a bit of time the first time around,
but because Vagrant is idempotent this will be the last time it will have to install java on all machines!
