# == Class: nagios::client
#
# This is going to create the host definition for each client.
#
# === Paramters
#
# [*nagios_parent*]
#  This is taken as a global variable from the puppet dashboard. I am not sure
#  about the correct way of handling this. This is used to override the parent
#  in the nagios host. An important note is that nagios will fail if this is not
#  a xenhost or defined! Needs a much better solution.
#
# === Variables
#
# [*nagios_service*]
#   This is the generic service it will implement. This is set from
#   nagios::params. This should be set by heira in the future.
#
# === Authors
#
# Ben Field <justin.miller@concreteplatform.com
class nagios::client (
  $nagios_service,
  $monitoring_environment,
  $parent       = $::xenhost,
  $nagios_alias = $::hostname,
  $address      = $::ipaddress_eth0) {
  # The not hugely neat way, need to refactor this:

  if $parent != 'physical' {
    @@nagios_host { $nagios_alias:
      ensure          => present,
      target          => "/etc/nagios3/conf.d/puppet/host_${::fqdn}.cfg",
      address         => $address,
      use             => 'generic-host',
      nagios_alias    => $nagios_alias,
      tag             => $monitoring_environment,
      parents         => $parent,
      icon_image      => 'base/linux40.png',
      statusmap_image => 'base/linux40.gd2',
    }
  } else {
    @@nagios_host { $nagios_alias:
      ensure          => present,
      target          => "/etc/nagios3/conf.d/puppet/host_${::fqdn}.cfg",
      address         => $address,
      use             => 'generic-host',
      nagios_alias    => $nagios_alias,
      tag             => $monitoring_environment,
      icon_image      => 'base/linux40.png',
      statusmap_image => 'base/linux40.gd2',
    }
  }

  @@nagios_service { "check_ping_${nagios_alias}":
    target              => "/etc/nagios3/conf.d/puppet/service_${::fqdn}.cfg",
    check_command       => 'check_ping!100.0,20%!500.0,60%',
    use                 => $nagios_service,
    host_name           => $nagios_alias,
    service_description => "${nagios_alias}_check_ping",
    require             => Nagios_host[$nagios_alias],
    tag                 => $monitoring_environment,
  }

  @motd::register { 'Nagios Ping Check': }

}
