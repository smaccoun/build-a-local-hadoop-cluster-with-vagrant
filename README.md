Tutorial
==============

> Note: This tutorial is based off of http://cscarioni.blogspot.co.uk/2012/09/setting-up-hadoop-virtual-cluster-with.html

# Why this tutorial exists

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
