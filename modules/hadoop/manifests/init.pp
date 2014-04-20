include wget

class hadoop {
 $hadoop_home = "/opt/hadoop"

exec { "download_hadoop" : 
  command => "/usr/bin/wget http://mirror.sdunix.com/apache/hadoop/common/hadoop-2.2.0/hadoop-2.2.0.tar.gz",
  cwd => "/tmp",
  creates => "/tmp/hadoop-2.2.0.tar.gz"
}

file {
  "/tmp/hadoop.tar.gz":
  ensure => present,
  mode => 640,
  owner => root,
  group => root,
  require => Package["openjdk-6-jdk"]
}

exec { "unpack_hadoop" :
  command => "tar -zxf /tmp/hadoop-2.2.0.tar.gz -C /opt",
  path => $path,
  creates => "${hadoop_home}-2.2.0",
  require => Exec["download_hadoop"]
}

file {
  "${hadoop_home}-2.2.0/etc/hadoop/slaves":
  source => "puppet:///modules/hadoop/slaves",
  mode => 644,
  owner => root,
  group => root,
  require => Exec["unpack_hadoop"]
 }
 
file {
  "${hadoop_home}-2.2.0/etc/hadoop/masters":
  source => "puppet:///modules/hadoop/masters",
  mode => 644,
  owner => root,
  group => root,
  require => Exec["unpack_hadoop"]
 }

file {
  "${hadoop_home}-2.2.0/etc/hadoop/core-site.xml":
  source => "puppet:///modules/hadoop/core-site.xml",
  mode => 644,
  owner => root,
  group => root,
  require => Exec["unpack_hadoop"]
 }
 
file {
  "${hadoop_home}-2.2.0/etc/hadoop/mapred-site.xml":
  source => "puppet:///modules/hadoop/mapred-site.xml",
  mode => 644,
  owner => root,
  group => root,
  require => Exec["unpack_hadoop"]
 }
 
 file {
  "${hadoop_home}-2.2.0/etc/hadoop/hdfs-site.xml":
  source => "puppet:///modules/hadoop/hdfs-site.xml",
  mode => 644,
  owner => root,
  group => root,
  require => Exec["unpack_hadoop"]
 }
 
  file {
  "${hadoop_home}-2.2.0/etc/hadoop/hadoop-env.sh":
  source => "puppet:///modules/hadoop/hadoop-env.sh",
  mode => 644,
  owner => root,
  group => root,
  require => Exec["unpack_hadoop"]
 }
}
