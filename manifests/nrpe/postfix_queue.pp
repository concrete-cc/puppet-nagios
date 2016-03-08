# == Class: nagios::nrpe::postfix_queue
#
# Checks if a postfix server has too many emails waiting in a mail queue.
#
# === Variables
#
# [*warning*]
#   The warning level. It will warn if the variable is above this value.
#   Not required. Defaults to 5.
#
# [*crtical*]
#   The critical level. It will be critical if the variable is above this value.
#   Not required. Defaults to 10.
#
# [*monitoring_environment*]
#   This is the environment that the check will be submitted for. This will
#   default to the value set by nagios::nrpe::config but can be overridden here.
#   Not required.
#
# [*nagios_service*]
#   This is the generic service that this check will implement. This should
#   be set by nagios::nrpe::config but can be overridden here. Not required.
#
# [*nagios_alias*]
#   This is the hostname that the check will be submitted for. This should
#   almost always be the hostname, but could be overriden, for instance when
#   submitting a check for a virtual ip. Not required.
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.net>
class nagios::nrpe::postfix_queue (
  $warning                = '5',
  $critical               = '10',
  $monitoring_environment = $::nagios::nrpe::config::monitoring_environment,
  $nagios_service         = $::nagios::nrpe::config::nagios_service,
  $nagios_alias           = $::hostname) {
  require nagios::nrpe::config
  include nagios::nrpe::service

  user { 'nagios': groups => ['postfix'], }

  file { 'check_postfix_queue.sh':
    ensure => present,
    path   => '/usr/lib/nagios/plugins/check_postfix_queue.sh',
    source => 'puppet:///modules/nagios/nrpe/check_postfix_queue.sh',
    owner  => 'nagios',
    group  => 'nagios',
    mode   => '0755',
    before => File_line['check_postfix_queue'],
  }

  file_line { 'check_postfix_queue':
    ensure => present,
    line   => "command[check_postfix_queue]=/usr/lib/nagios/plugins/check_postfix_queue.sh -w ${warning} -c ${critical}",
    path   => '/etc/nagios/nrpe_local.cfg',
    match  => 'command\[check_postfix_queue\]',
    notify => Service['nrpe'],
  }

  @@nagios_service { "check_postfix_queue_${nagios_alias}":
    check_command       => 'check_nrpe_1arg!check_postfix_queue',
    use                 => $nagios_service,
    host_name           => $nagios_alias,
    target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
    service_description => "${nagios_alias}_check_postfix_queue",
    tag                 => $monitoring_environment,
  }

}
