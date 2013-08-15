include rsa
include hadoop

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
