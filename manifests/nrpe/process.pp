# == Define: nagios::nrpe::process
#
# This will build a nagios check for the process specified. This will handle the
# configuration both client and server side.It will also allow you to use an
# event handler with the restart command specified, and will allow you to decide
# whether this command should be added to the sudoers file for the nagios user.
#
# === Parameters
#
# [*process*]
#   The name of the process you would like to test. Uses -C from
#   https://www.monitoring-plugins.org/doc/man/check_procs.html
#   Required. Note: Not currently tested.
#
# [*warning_low*]
#   The low bound of the process count, for warning level. Uses -w from
#   https://www.monitoring-plugins.org/doc/man/check_procs.html
#   Defaults to 1. Not required.
#
# [*critical_low*]
#   The low bound of the process count, for critical level. Uses -c from
#   https://www.monitoring-plugins.org/doc/man/check_procs.html
#   Defaults to 1. Not required.
#
# [*warning_high*]
#   The high bound of the process count, for warning level. Uses -w from
#   https://www.monitoring-plugins.org/doc/man/check_procs.html
#   Defaults to "". Not required.
#
# [*critical_high*]
#   The high bound of the process count, for critical level. Uses -c from
#   https://www.monitoring-plugins.org/doc/man/check_procs.html
#   Defaults to "". Not required
#
# [*type*]
#   Argument or Command. An argument is useful if the application is run by a
#   different program - for instance a java application. A command is for a
#   specific program.
#   Defaults to argument. Not required.
#
# [*user*]
#   A user to check the process is running at, if this is required.
#   Defaults to none. Not required.
#
# [*event_handler*]
#   A boolean value. Whether or not you would like to trigger an event_handler
#   on service failure. This will run the restart_command you specified on
#   detecting a failure.
#   Defaults to false. Not required.
#
# [*restart_command*]
#   The command you wish to run on service failure. Typically a restart command.
#  Do not add use sudo in the command, sudo_required will do this automatically
#  for you.
#   Defaults to "/etc/init.d/$process restart". Not required.
#
# [*sudo_required*]
#   Whether the restart command requires sudo. If true, will add nagios user to
#  the sudoers file for that command, as well as adding it to the command the
#  event handler will run. Note: This will use the specific user if one has been
#  defined.
#   Defaults to true. Not required.
#
# [*sudo_user_required*]
#   Whether the restart command should sudo to the user specified. This requires
#  you to have set sudo_required to true initally.If you want to restart using
#  root (standard behaviour for most applications i.e. nginx) set it to false.
#   Defaults to false. Not required.
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
# === Examples
#
# To check the nginx process and restart if down:
#
#   nagios::nrpe::process { "${hostname} nginx process":
#    process         => "nginx",
#    warning_low     => $warningprocesses,
#    critical_low    => "1",
#    event_handler   => true,
#    restart_command => "/etc/init.d/nginx restart",
#    sudo_required   => true
#  }
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com
#
define nagios::nrpe::process (
  $process,
  $warning_low            = '1',
  $critical_low           = '1',
  $warning_high           = '',
  $critical_high          = '',
  $type                   = 'argument',
  $user                   = '',
  $event_handler          = false,
  $restart_command        = '',
  $sudo_required          = true,
  $sudo_user_required     = false,
  $monitoring_environment = $::nagios::nrpe::config::monitoring_environment,
  $nagios_service         = $::nagios::nrpe::config::nagios_service,
  $nagios_alias           = $::hostname,) {
  require nagios::nrpe::config
  include nagios::nrpe::service

  $type_string = $type ? {
    'argument' => '-a ',
    'command'  => '-C ',
    default    => '-a '
  }

  if $restart_command == '' and $event_handler == true {
    $restart_command = "/etc/init.d/${process} restart"
  }

  if $user == '' {
    $user_command = ''
  } else {
    $user_command = "-u ${user} "
  }

  file_line { "check_${process}_processes":
    ensure => present,
    line   => "command[check_${process}_processes]=/usr/lib/nagios/plugins/check_procs ${user_command}-w ${warning_low}:${warning_high} -c ${critical_low}:${critical_high} ${type_string}${process}",
    path   => '/etc/nagios/nrpe_local.cfg',
    match  => "command\[check_${process}_processes\]",
    notify => Service['nrpe'],
  }

  if $event_handler == true {
    if $sudo_required == true {
      # add nagios to sudoers so it can run $restart_command}
      file_line { "${process}_sudoers":
        ensure => present,
        line   => "nagios ALL=(ALL) NOPASSWD: ${restart_command}",
        path   => '/etc/sudoers',
        before => File_line["restart_${process}"],
      }

      # add sudo to beginning of command
      if $sudo_user_required == true {
        $final_restart_command = "sudo ${user_command}${restart_command}"
      } else {
        $final_restart_command = "sudo ${restart_command}"
      }
    } else {
      $final_restart_command = $restart_command
    }

    file { "restart_${process}.sh":
      ensure  => present,
      path    => "/usr/lib/nagios/eventhandlers/restart_${process}.sh",
      content => template('nagios/nrpe/restart_service.conf.erb'),
      owner   => 'nagios',
      group   => 'nagios',
      mode    => '0755',
      before  => File_line["restart_${process}"],
      require => File['/usr/lib/nagios/eventhandlers'],
    }

    file_line { "restart_${process}":
      ensure => present,
      line   => "command[restart_${process}]=/usr/lib/nagios/eventhandlers/restart_${process}.sh",
      match  => "command\[restart_${process}\]",
      path   => '/etc/nagios/nrpe_local.cfg',
      notify => Service['nrpe'],
    }

    @@nagios_service { "check_${process}_processes_${nagios_alias}":
      check_command       => "check_nrpe_1arg!check_${process}_processes",
      use                 => $nagios_service,
      host_name           => $nagios_alias,
      target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
      service_description => "${nagios_alias}_check_${process}_processes",
      tag                 => $monitoring_environment,
      event_handler       => "event_handler!restart_${process}",
    }

  } else {
    @@nagios_service { "check_${process}_processes_${nagios_alias}":
      check_command       => "check_nrpe_1arg!check_${process}_processes",
      use                 => $nagios_service,
      host_name           => $nagios_alias,
      target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
      service_description => "${nagios_alias}_check_${process}_processes",
      tag                 => $monitoring_environment,
    }
  }

}
