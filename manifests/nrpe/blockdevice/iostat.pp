# == Define: nagios::nrpe::blockdevice::iostat
#
# This will take a drive reference as the name, and use it to create a diskspeed
# check. The warning level for io load will be 80% and 100% for critical. It
# will also make sure load not also trigger if this has triggered, and so
# requires nagios::nrpe::load.
#
# Note: It will set the name of the check to reference sysvol not xvda for
# cleanness in the nagios server
#
# === Parameters
#
# [*namevar*]
#   This will provide the drive reference (ie xvda from xen machines).
#
# === Variables
#
# [*nagios_service*]
#   This is the generic service it will implement. This is set from
#   nagios::params. This should be set by heira in the future.
#
# === Examples
#
#   nagios::nrpe::blockdevice::diskspace { 'xvda':
#   }
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com
define nagios::nrpe::blockdevice::iostat (
  $monitoring_environment = $::nagios::nrpe::config::monitoring_environment,
  $nagios_service         = $::nagios::nrpe::config::nagios_service,
  $nagios_alias           = $::hostname) {
  require nagios::nrpe::checks::iostat
  require nagios::nrpe::load

  $check = "command[check_iostat_${name}]=/usr/lib/nagios/plugins/check_iostat.sh -d ${name} -W -w 999,100,200,100,100 -c 999,200,300,200,100"

  file_line { "check_iostat_${name}":
    ensure => present,
    line   => $check,
    path   => '/etc/nagios/nrpe_local.cfg',
    match  => "command\[check_iostat_${name}\]",
    notify => Service['nrpe'],
  }

  if $name == 'xvda' {
    $drive = 'sysvol'
  } else {
    $drive = $name
  }

  @@nagios_service { "check_${drive}_iostat_${nagios_alias}":
    check_command       => "check_nrpe_1arg_longtimeout!check_iostat_${name}",
    use                 => $nagios_service,
    host_name           => $nagios_alias,
    target              => "/etc/nagios3/conf.d/puppet/service_${::fqdn}.cfg",
    service_description => "${nagios_alias}_check_${drive}_iostat",
    tag                 => "${monitoring_environment}",
    servicegroups       => "servicegroup_iostat_${::xenhost}",
  }

  @@nagios_servicedependency { "load_${name}_on_${nagios_alias}_depencency_iostat"
  :
    dependent_host_name           => $nagios_alias,
    dependent_service_description => "${nagios_alias}_check_load",
    host_name => $nagios_alias,
    service_description           => "${nagios_alias}_check_${drive}_iostat",
    execution_failure_criteria    => 'w,c',
    notification_failure_criteria => 'w,c',
    target    => "/etc/nagios3/conf.d/puppet/service_dependencies_${::fqdn}.cfg",
    tag       => $monitoring_environment,
  }

  @motd::register { "Nagios Diskspeed Check ${name}": }

}
