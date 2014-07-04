# The profile class include the classes instantiation or
# puppet/modules type resource definitions.
# It can include hiera calls for the parametter setting.
# Example:
# class profiles::fooserver {
#   $fooport = hiera("fooserver_port")
#   class { "fooserver":
#     port  => $fooport
#   }
# }

class profiles::security {
  include 'install_fail2ban'
  include 'install_ssh'
  include 'install_sysctl'
  include 'install_iptables'
}

class install_iptables {
  # include sysctl
  # sysctl::value { "net.ipv4.conf.all.accept_redirects": content => "0" }
  # Obtain and create redis server instances from hiera
  # firewall { "000 accept ssh requests":
  #   proto  => "tcp",
  #   port   => 22,
  #   action => "accept",
  # }
  package { 'iptables-persistent':
    ensure => present
  }
  resources { "firewall":
    purge => true,
    require => Package['iptables-persistent'],
  }
  $firewall_rules_hash = hiera('firewall', {})
  create_resources('firewall', $firewall_rules_hash)
}

class install_sysctl {
  # include sysctl
  # sysctl::value { "net.ipv4.conf.all.accept_redirects": content => "0" }
  # Obtain and create redis server instances from hiera
  $sysctl_values_hash = hiera('sysctl', {})
  create_resources('sysctl', $sysctl_values_hash)
}

class install_ssh {
  # Obtain ssh parameters from hiera
  $ssh_parameters = hiera('ssh::server', {})
  $port = $ssh_parameters[port]
  $password_authentication = $ssh_parameters[password_authentication]
  $pubkey_authentication = $ssh_parameters[pubkey_authentication]
  $permit_root_login = $ssh_parameters[permit_root_login]

  # Instance the ssh::server class with hiera parameters
  class { 'ssh::server':
    port => $port,
    password_authentication => $password_authentication,
    pubkey_authentication => $pubkey_authentication,
    permit_root_login => $permit_root_login,
  }
}

class install_fail2ban {
  # Obtain fail2ban parameters from hiera
  $fail2ban_parameters = hiera('fail2ban', {})
  $bantime = $fail2ban_parameters[bantime]
  $maxretry = $fail2ban_parameters[maxretry]
  $mailto = $fail2ban_parameters[destemail]

  # Instance the fail2ban class with hiera parameters
  class { 'fail2ban':
    bantime => $bantime,
    maxretry => $maxretry,
    mailto => $mailto,
  }
}