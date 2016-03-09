# == Class: nagios::nrpe::service
#
# This will ensure the nrpe service is running and add an nagios_alias 'nrpe'
# for ease of restart scripting.
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com
class nagios::nrpe::service {
  require nagios::nrpe::config

  case $::operatingsystem {
    'Ubuntu'                   : {
      $service = ['nagios-nrpe-server']
    }
    'RHEL', 'CentOS', 'RedHat' : {
      require epel

      $service = ['nrpe']
    }
    default                    : {
      err('Unsupported OS')
    }
  }

  service { $service:
    ensure => running,
    alias  => 'nrpe',
    enable => true,
  }

}
