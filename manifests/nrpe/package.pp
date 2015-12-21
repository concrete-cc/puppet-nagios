# == Class: nagios::nrpe::config
#
# This will install the nrpe client, install basic plugins and create the
# eventhandler folder.
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com
class nagios::nrpe::package {
  require stdlib

  include nagios::folders

  case $::operatingsystem {
    'Ubuntu'                   : {
      $packages = ['nagios-nrpe-server', 'nagios-plugins-basic']
    }
    'RHEL', 'CentOS', 'RedHat' : {
      require epel

      $packages = ['nrpe', 'nagios-plugins-all']
    }
    default                    : {
      err('Unsupported OS')
    }
  }

  package { $packages:
    ensure => installed,
    before => File['/usr/lib/nagios/eventhandlers']
  }

}
