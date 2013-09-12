Tutorial
==============

> Note: This tutorial is based off of http://cscarioni.blogspot.co.uk/2012/09/setting-up-hadoop-virtual-cluster-with.html

Using only 1 command, you can get a full hadoop cluster running on your own machine!

```
$: cd /tmp
$: git clone https://github.com/smaccoun/build-a-local-hadoop-cluster-with-vagrant.git
$: cd build-a-local-hadoop-cluster-with-vagrant/
$: vagrant up

# Now log in and start hadoop
$: vagrant ssh master
$: sudo su -
$: cd /opt/hadoop-1.1.2
$: ./bin/start-all.sh
```

This is the first of a series of tutorials. This one gives you an introduction to vagrant and puppet, as well as
show some of the key configuration files necessary for hadoop. If all you want is to run vagrant on your own machine,
just clone the repo and run the commands above to get on your way!

Note that the first time you run this it will probably take a significant amount of time to download the base box 
and all other necessary files. Fortunately, Vagrant is idempotent so all future `vagrant up` commands will go quite 
quickly, and spawning up future clusters should only be a matter of a couple of minutes.

Feel free to fork and suggest improvements. This tutorial is still a work in progress. Future tutorials will
include basic MapReduce processes with Java, and eventually Hive and Pig too!

If at any point you want to close your machines or shut them down just type
```
#From host, halt machines
$: vagrant halt

#From host, destroy all machines. Can be reclaimed with vagrant up
$: vagrant destroy
```

## Why this tutorial exists

What is hadoop? Hadoop is a framework for handling big data. Data that is so big that usually one machine can't support it.
Hadoop therefore makes use of *multiple* machines to handle and process all of that data.

"But what if I don't have access to multiple machines?"

Well, one option might be to rent out some EC2 instances or some other 3rd party servers. But all of
those usually cost some money, and you don't have quite the power to inspect hadoop's internals as if they were all
on your own machine. Another option is to run Hadoop in pseudo-distributed mode, but this doesn't allow you to see hadoop
truly working with multiple nodes - as it would in any industrial implementation - and so you don't get to see
it's key parallel processing capabilities.

The solution is to simulate several servers on your own machine using virtual machines. For each of those VMs, you'll have
to set them up to be configured for hadoop. Sounds like a lot of work, right?

Using [Vagrant] (http://www.vagrantup.com/) and [Puppet] (https://puppetlabs.com/), server configuration is a breeze.
Make sure you have downloaded each, as well as [Virtualbox] (https://www.virtualbox.org/) before starting this tutorial.

## Basic Cluster

With Vagrant you create a file called a Vagrantfile which specifies your server configuration.

`$ touch Vagrantfile`

With hadoop, you will store all of your data on what are called **data nodes**. When you want to store your data, hadoop
will first split this data up into smaller chunks called *blocks*, and these blocks will be divided up amongst the data
nodes. A **name node** (the *master* of the *slaves*) will then keep track of where these blocks are, along with other meta information about the data.
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
     puppet.module_path = "modules"
end

...

```

Now run `$ Vagrant reload` and java6 will be installed on all of your VM's. This may take a bit of time the first time around,
but because Vagrant is idempotent this will be the last time it will have to install java on all machines!

####Configuring SSH

Hadoop will use SSH to have VMs to communicate with one another. In order to prevent password prompts when loggin in,
we must store the public rsa keys in each vm.

First, generate an example key on your host machine:
`$: ssh-keygen -t rsa`

Then create a puppet module which will configure all VMs to store info on this public key. Create a modules directory
where we will put the rest of our puppet VMs, and then add an rsa module to it.

```
$: mkdir -p modules/rsa
$: cd modules/rsa
$: mkdir manifests files
```

Create the initialization file (init.pp) for this module. The RSA key should be the one you just generated.
StrictHostKeyChecking has to be set to no in order to allow for seamless ssh communication with Hadoop.
Make sure to copy the `/etc/ssh/ssh_config` into `modules/rsa/files`.

```
$: vim manifests/init.pp

class rsa {

file { "/etc/ssh/ssh_config":
   source => "puppet:///modules/rsa/ssh_config",
   owner => "root",
   group => "root",
   mode => 600
}

file { "/root/.ssh":
   ensure => "directory",
   owner => "root",
   group => "root",
   mode => 600,
}


file {
  "/root/.ssh/id_rsa":
  source => "puppet:///modules/rsa/id_rsa",
  mode => 600,
  owner => root,
  group => root,
  require => Exec['apt-get update']
 }
 
file {
  "/root/.ssh/id_rsa.pub":
  source => "puppet:///modules/rsa/id_rsa.pub",
  mode => 600,
  owner => root,
  group => root,
  require => Exec['apt-get update']
 }

ssh_authorized_key { "ssh_key":
    ensure => "present",
    key    => "AAAAB3NzaC1yc2EAAAADAQABAAABAQDSmQKEUmUHeIWeNl6wac8mnH5iy36XVECoEp+VqVfANeX4SPQMFQb2f+LgBmodW+lKqvo8aO+kk1mWYSuU745n8g0xszAq46IlHtUxyz7pRJTO46Ut2PDEvAabSIP/CaGbKZ9+SajkE+fny/VUu10ke9KCiNw/8qW8OT52bqwq4lqKeyH4Rj7dhQfT20g8V9d0Sv9szozt+EVLjaF/2TcNGoHwGs8aSNQ0m/HtAUPZzrZO5J4LnVV+KwYnT0htyJGyHPwSuaMVbbNptIrblHMxLAsatZsQvi7wlJlPpH2zBTDjkODvRu3drbQ8UtQynYac8nTfVICp/TDa0JRHO4tf",
    type   => "ssh-rsa",
    user   => "root",
    require => File['/root/.ssh/id_rsa.pub']
}
 
}


```

And in the files folder, add your `id_rsa` and `id_rsa.pub` files that you just generated. Here are mine:

*id_rsa*
```
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEA0pkChFJlB3iFnjZesGnPJpx+Yst+l1RAqBKflalXwDXl+Ej0
DBUG9n/i4AZqHVvpSqr6PGjvpJNZlmErlO+OZ/INMbMwKuOiJR7VMcs+6USUzuOl
LdjwxLwGm0iD/wmhmymffkmo5BPn58v1VLtdJHvSgojcP/KlvDk+dm6sKuJainsh
+EY+3YUH09tIPFfXdEr/bM6M7fhFS42hf9k3DRqB8BrPGkjUNJvx7QFD2c62TuSe
C51VfisGJ09IbciRshz8ErmjFW2zabSK25RzMSwLGrWbEL4u8JSZT6R9swUw45Dg
70bt3a20PFLUMp2GnPJ031SAqf0w2tCURzuLXwIDAQABAoIBABK6UKL7wMg9S4Sa
SSle/3DrkcGvXv6OG4HWxiJFAOyy3lSKCEnaxNe+36oUZ/NcbQ6azc35dvYntFvP
IFUKSJutxsaYrLvjqlOqvkLDVEDiPGl5jQLau+6C2gONG0/ex2RI+0n7uu0tZ/4R
ASwbzVilOj8pdIyrQ1nNrWRSyzS06wMnGQTsI8agT+V6/sVXUnMNGZZprp8Hp5Ph
JJfl7P8GeI4t+tEoM0ty28E+ZnAjUx416DC8LNQZhQkOlfCX7IRUMnxF1R1u4nhZ
y94wRLuPY4gkxNGkxeSp0VV053UMaqGkJjxfQnTQBLhmTqHY0aQn2n1dFcIvGRnX
eDQzxyECgYEA9c6yGLPKQfAYwNs6+K5GbkFALCAwnE9jCSmU+YEkYoqmG+N2VKmT
shXt3JACQrhDZTZrIhlwoEc4OXrLUkQ6hKFoqRLPFAIC0iI5N8IPRkPQHGiigtBp
SSoviR7p/LPOWAx5qG9VbaUVOUbrPSnfwPyO0Bz7Zv9hrUTk7/kyyRMCgYEA21SN
/gWIFLOc1hc/T7dEMs2BZa6EEOrp/DJ0rqA+MONKbIWXQbnX5xlQd+2uXthfxmXq
LitDIRWjJ+0w5dui6TXsEwXgTp/69gu7GGpWfFpKOerQSP2riiuc2WcZKv39Z/K6
zloZ9tFZVd3nMXiDSQKKtZLARtq2bZTXWJdNqgUCgYB7/FtnDGEL63CA7tQLFdTe
zjjxSPdcEMsSlw/W3mYc8nShApXwVGz0Wg1VwKnzP4B3MADP/WcK4YGhtKeUAmhF
+CiTh7I+FFmZ5rtXvaH4vkHd4oV+WGOTDR1XG+nIlmWRkhFXfXjoymkvL+9+NX3w
mTPsE4JXzJ9XR7X2uYr9UwKBgQDOVqrKurt99kfrJa27Ogef37QHS/oUzFvalkEt
c7VuWrZOiBN3kvXqBOeuG936focD6Cc6zhp2SpvW2Q8yf8GwsrjoYJPYhCseRIT8
gDXjATJpcF4I/RTfhQ4nfRWxW4eFvlY+AYgBqovn+z4gTWb9TbXfAjN/tQ0A5JD/
WECJXQKBgDeE6UamNYkgGQkk7HYbjLMl6E7x+EJ5G+70dcm1i79kgjYJVW9GoaSD
/Slbx1BZkOqukbY8iqbj+QiBl+SZ8Pt5uQdf7SIRpkY3yrCiJHiL4cdbY6n6tuiv
j8yNhiTUxwn3ZPz8KvuCLpptai3Hn0P1cEV5vua//d12Fc1NEnjj
-----END RSA PRIVATE KEY-----
```

*id_rsa.pub*
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDSmQKEUmUHeIWeNl6wac8mnH5iy36XVECoEp+VqVfANeX4SPQMFQb2f+LgBmodW+lKqvo8aO+kk1mWYSuU745n8g0xszAq46IlHtUxyz7pRJTO46Ut2PDEvAabSIP/CaGbKZ9+SajkE+fny/VUu10ke9KCiNw/8qW8OT52bqwq4lqKeyH4Rj7dhQfT20g8V9d0Sv9szozt+EVLjaF/2TcNGoHwGs8aSNQ0m/HtAUPZzrZO5J4LnVV+KwYnT0htyJGyHPwSuaMVbbNptIrblHMxLAsatZsQvi7wlJlPpH2zBTDjkODvRu3drbQ8UtQynYac8nTfVICp/TDa0JRHO4tf
```

If you run vagrant up, you should now be able to communicate with all of your VM's using SSH without having to type
passwords!

###Add Hadoop Config Files

Let's now add all the basic hadoop files you need to get basic hadoop up and running.

**core-site.xml**
Let's use the basic version of this file:

```
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
 <configuration>
  <property>
   <name>fs.default.name</name>
   <value>hdfs://192.168.2.10:9000</value>
   <description>The name of the default file system. A URI whose scheme and authority determine the FileSystem implementation.</description>
  </property>
 </configuration>
```
 
**hadoop-env.sh**
The only line we need to set for our basic setup is our JAVA_HOME variable.

```
...
export JAVA_HOME=/usr/lib/jvm/java-6-openjdk
...
```

**mapred-site.xml**
Where our job tracker runs. Hadoop runs the job tracker on the master node (NameNode)

```
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
 <property>
  <name>mapred.job.tracker</name>
  <value>192.168.2.10:9001</value>
  <description>The host and port that the MapReduce job tracker runs at.</description>
 </property>
</configuration>
```

And finally we will create our master and slave files that tell hadoop which machines are the data nodes and which is
the name node:

**masters**
```
192.168.2.10
```

**slaves**
```
192.168.2.11
192.168.2.12
192.168.2.13
```

### Test it out!

Using only 1 command, you can get a full hadoop cluster running on your own machine!

```
$: cd /tmp
$: git clone https://github.com/smaccoun/build-a-local-hadoop-cluster-with-vagrant.git
$: cd build-a-local-hadoop-cluster-with-vagrant/
$: vagrant up

# Now log in and start hadoop
$: vagrant ssh master
$: sudo su -
$: cd /opt/hadoop-1.1.2
$: ./bin/start-all.sh
```

If you want to ssh into any other nodes to see their workings, just use `vagrant ssh hadoop<#>`.
Future tutorial will go more in depth from here. Stay tuned.


