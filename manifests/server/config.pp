# == Class: nagios::server::config
#
# This is going to configure the server and collect all the submitted services
# etc. This uses the dodgy define nagios::nrpe::collector. There is no way to
# achieve this otherwise - the owner/group will always be root!
#
# It will also handle the configuration for the various plugins that have been
# configured in this module.
#
# === Parameters
#
# [*monitoring_environment*]
#   This is the environment that the recieve checks and clients from. . This
#   will override the value for the define that it implements.
#   Required.
#
# [*password*]
#   The password you would like to use for the nagiosadmin user.
#   Required.
#
# [*salt*]
#   The salt that will be used to generate the password hash.
#   Not required. Defaults to a psuedo random 12 character string.
#
# [*virtualip*]
#   Whether or not to set up the virtualip collector. This is required if you
#   would like to use nagios::virtualip. As a warning this will break if you
#   turn this on while NOT submitting virtual ips.
#   Not required. Defaults to false
#
# [*iostat*]
#   Whether or not to set up the iostat collector. This is required if you
#   would like to use nagios::nrpe::iostat with service_groups. As a warning
#   this will break if you turn this on while NOT submitting groups.
#   Not required. Defaults to false
#
# [*nessus_reports*]
#   Whether or not to set up the nessus_reports plugin and commands.
#   Not required. Defaults to false
#
# [*check_temp_dell_6248*]
#   Whether or not to set up the check_temp_dell_6248 plugin and commands.
#   Not required. Defaults to false
#
# [*pagerduty*]
#   Whether or not to set up the pagerduty notification plugin and commands.
#   Not required. Defaults to true
#
# [*hipchat*]
#   Whether or not to set up the hipchat notification plugin and commands.
#   Not required. Defaults to true
#
# [*email*]
#   Whether or not to set up the email plugin and commands.
#   Not required. Defaults to true
#
# [*event_handler*]
#   Whether or not to set up the event_handler plugin and commands.
#   Not required. Defaults to true
#
# [*nrpe*]
#   Whether or not to set up the nrpe plugin and commands.
#   Not required. Defaults to true
#
# [*check_mssql_health*]
#   Whether or not to set up the check_mssql_health plugin and commands.
#   Not required. Defaults to true
#
# [*check_mssql*]
#   Whether or not to set up the check_mssql plugin and commands.
#   Not required. Defaults to true
#
# [*time_periods*]
#   A hash of time_periods to set up for nagios.
#   Not required.
#
# [*$commands*]
#   A hash of $commands to set up for nagios.
#   Not required.
#
# [*contacts*]
#   A hash of contacts to set up for nagios.
#   Not required.
#
# [*contact_groups*]
#   A hash of contact_groups to set up for nagios.
#   Not required.
#
# [*services*]
#   A hash of services to set up for nagios.
#   Not required.
#
# [*hosts*]
#   A hash of hosts to set up for nagios.
#   Not required.
#
# [*admin_email*]
#   The admin_email to set. This is the address that emails will be sent from,
#   if you use them.
#   Not required. Defaults to nagios@$hostname
#
# [*service_check_timeout*]
#  Timeout for checks
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com
class nagios::server::config (
  $monitoring_environment,
  $password,
  $salt                 = generate_password(12, 'nagios'),
  $virtualip            = false,
  $iostat               = false,
  $nessus_reports       = false,
  $check_temp_dell_6248 = false,
  $pagerduty            = false,
  $hipchat              = false,
  $email                = true,
  $event_handler        = true,
  $nrpe                 = true,
  $check_mssql_health   = true,
  $check_mssql          = true,
  $time_periods         = undef,
  $commands             = undef,
  $contacts             = undef,
  $contact_groups       = undef,
  $services             = undef,
  $hosts                = undef,
  $admin_email          = "nagios@${::hostname}") {
  require nagios::server::package
  include nagios::server::service

  file_line { 'check_external_commands':
    ensure => present,
    line   => 'check_external_commands=1',
    path   => '/etc/nagios3/nagios.cfg',
    match  => 'check_external_commands',
    notify => Service['nagios3'],
  }

  file { '/etc/nagios3/conf.d/puppet/':
    ensure  => directory,
    # purge => true,
    recurse => true,
    force   => true,
    owner   => 'root',
    group   => 'nagios',
    mode    => '0640',
  }

  nagios::server::collector { 'collect_it':
    monitoring_environment => $monitoring_environment,
    require                => File['/etc/nagios3/conf.d/puppet/'],
    notify                 => Exec['rechmod'],
  }

  $encrypted_password = ht_crypt($password, $salt)

  htpasswd { 'nagiosadmin':
    cryptpasswd => $encrypted_password,
    target      => '/etc/nagios3/htpasswd.users',
  }

  file { '/etc/nagios3/htpasswd.users':
    ensure  => present,
    owner   => 'www-data',
    group   => 'www-data',
    require => Htpasswd['nagiosadmin']
  }

  user { 'www-data': groups => ['nagios'], }

  if $iostat == true {
    class { '::nagios::server::collector::iostat': monitoring_environment => 
      $monitoring_environment }
  }

  if $virtualip == true {
    class { '::nagios::server::collector::virtualip': monitoring_environment => 
      $monitoring_environment }
  }

  if $nessus_reports == true {
    class { '::nagios::server::plugins::nessus_reports': }
  }

  if $check_temp_dell_6248 == true {
    class { '::nagios::server::plugins::check_temp_dell_6248': }
  }

  nagios_command { 'Check HTTP nonroot custom port':
    ensure       => 'present',
    command_name => 'check_http_nonroot_custom_port',
    command_line => '/usr/lib/nagios/plugins/check_http -H $ARG1$ -u $ARG2$ -p $ARG3$  --onredirect=sticky -e 200,302',
    target       => '/etc/nagios3/conf.d/puppet/command_nagios.cfg',
    notify       => Exec['rechmod'],
  }

  nagios_command { 'Check HTTPS nonroot custom port':
    ensure       => 'present',
    command_name => 'check_https_nonroot_custom_port',
    command_line => '/usr/lib/nagios/plugins/check_http -S --sni -H $ARG1$ -u $ARG2$ -p $ARG3$  --onredirect=sticky -e 200,302',
    target       => '/etc/nagios3/conf.d/puppet/command_nagios.cfg',
    notify       => Exec['rechmod'],
  }

  nagios_command { 'Check HTTP custom string nonroot custom port':
    ensure       => 'present',
    command_name => 'check_http_custom_string_nonroot_custom_port',
    command_line => '/usr/lib/nagios/plugins/check_http -H $ARG1$ -u $ARG2$ -p $ARG3$ -s $ARG4$ --onredirect=sticky',
    target       => '/etc/nagios3/conf.d/puppet/command_nagios.cfg',
    notify       => Exec['rechmod'],
  }

  nagios_command { 'Check HTTPS custom string nonroot custom port':
    ensure       => 'present',
    command_name => 'check_https_custom_string_nonroot_custom_port',
    command_line => '/usr/lib/nagios/plugins/check_http -S --sni -H $ARG1$ -u $ARG2$ -p $ARG3$ -s $ARG4$ --onredirect=sticky',
    target       => '/etc/nagios3/conf.d/puppet/command_nagios.cfg',
    notify       => Exec['rechmod'],
  }

  file_line { 'admin_email':
    ensure => present,
    line   => "admin_email=${admin_email}",
    path   => '/etc/nagios3/nagios.cfg',
    match  => 'admin_email',
    notify => Service['nagios3'],
  }

  file { '/var/lib/nagios3/rw/':
    ensure => directory,
    mode   => '0750'
  }

  if $pagerduty == true {
    class { '::nagios::server::notification::pagerduty': }
  }

  if $hipchat == true {
    class { '::nagios::server::notification::hipchat': }
  }

  if $email == true {
    class { '::nagios::server::notification::email': }
  }

  if $event_handler == true {
    class { '::nagios::server::plugins::event_handler': }
  }

  if $nrpe == true {
    class { '::nagios::server::plugins::nrpe': }
  }

  if $check_mssql_health == true {
    class { '::nagios::server::plugins::check_mssql_health': }
  }

  if $check_mssql == true {
    class { '::nagios::server::plugins::check_mssql': }
  }

  if $time_periods != undef {
    create_resources('nagios_timeperiod', $time_periods, {
      target => '/etc/nagios3/conf.d/puppet/timeperiod_nagios.cfg',
      notify => Exec['rechmod']
    }
    )
  }

  if $commands != undef {
    create_resources('nagios_command', $commands, {
      target => '/etc/nagios3/conf.d/puppet/command_nagios.cfg',
      notify => Exec['rechmod']
    }
    )
  }

  if $contacts != undef {
    create_resources('nagios_contact', $contacts, {
      target => '/etc/nagios3/conf.d/puppet/contact_nagios.cfg',
      notify => Exec['rechmod']
    }
    )
  }

  if $contact_groups != undef {
    create_resources('nagios_contactgroup', $contact_groups, {
      target => '/etc/nagios3/conf.d/puppet/contact_groups_nagios.cfg',
      notify => Exec['rechmod']
    }
    )
  }

  if $services != undef {
    create_resources('nagios_service', $services, {
      target => '/etc/nagios3/conf.d/puppet/service_nagios.cfg',
      notify => Exec['rechmod']
    }
    )
  }

  if $hosts != undef {
    create_resources('nagios_host', $hosts, {
      target => '/etc/nagios3/conf.d/puppet/host_nagios.cfg',
      notify => Exec['rechmod']
    }
    )
  }
}
