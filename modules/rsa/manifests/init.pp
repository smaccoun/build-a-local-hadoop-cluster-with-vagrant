class rsa {

file { "/root/.ssh":
   ensure => "directory",
   owner => "root",
   group => "root",
   mode => 600,
}


file {
  "/root/.ssh/id_rsa":
  source => "puppet:///modules/hadoop/id_rsa",
  mode => 600,
  owner => root,
  group => root,
  require => Exec['apt-get update']
 }
 
file {
  "/root/.ssh/id_rsa.pub":
  source => "puppet:///modules/hadoop/id_rsa.pub",
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
