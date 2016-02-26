# == Define: nagios::nrpe::file_ages
#
# This class will allow us to check the number of files in a folder, with an age
# below a certain level, is above a certain threshold. This is useful for
# checking that a file/report generating process is correctly running. We could
# probably fold this into the file_count check for simplicity.
#
# === Parameters
#
# [*namevar*]
#   The directory will default to the name of the resource. This is the
#   directory that the file count will be run on.
#
# [*warning*]
#   The warning age level. It will warn on nagios if the file count younger than
#   this age goes below the threshold.
#   Not required. Defaults to 7.
#
# [*critical*]
#   The critical age level. It will warn on nagios if the file count younger
#   than
#   this age goes below the threshold.
#   Not required. Defaults to 14.
#
# [*recurse*]
#   Boolean for whether the file count should recurse into sub folders.
#   Not required. Defaults to true.
#
# [*type*]
#   The type of file to check for (file, directory or both).
#   Not require. Defaults to file.
#
# [*number*]
#   Minimum number of files.
#   Not required. Defaults to 1.
#
# [*extension*]
#   A file extenstion to filter for.
#   Not required.
#
# [*filter*]
#   A name to filter for.
#   Not required.
#
# [*mode*]
#   days or seconds
#
# [*has_parent*]
#   Whether this folder has a parent service dependency (eg a mount).
#   Not required. Defaults to true.
#
# [*parent_service*]
#   The name of the parent host, if has_parent is set to true (eg
#   ${hostname}).
#   Defaults to $::hostname. Not required.
#
# [*parent_service*]
#   The name of the parent service, if has_parent is set to true (eg
#   ${hostname}_check_mount).
#   Required if has parent is true. Defaults to "".
#
#   Note: This is not tested.
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
# === Variables
#
# [*command*]
#   This is the command that nrpe will use to check the file count.
#
# === Examples
#
#  nagios::nrpe::file_ages { "/var/www/repo/apt/incoming":
#    warning  => "7",
#    critical => "14",
#    recurse  => true,
#    number   => "1",
#  }
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com>
define nagios::nrpe::file_ages (
  $directory              = $name,
  $warning                = '7',
  $critical               = '14',
  $recurse                = true,
  $type                   = 'file',
  $number                 = '1',
  $extension              = '',
  $filter                 = '',
  $mode                   = '',
  $has_parent             = false,
  $parent_host            = $::hostname,
  $parent_service         = '',
  $monitoring_environment = $::nagios::nrpe::config::monitoring_environment,
  $nagios_service         = $::nagios::nrpe::config::nagios_service,
  $nagios_alias           = $::hostname,) {
  require nagios::nrpe::config
  include nagios::nrpe::service
  require nagios::nrpe::checks::file_ages

  $recurse_string = $recurse ? {
    true    => '-r ',
    false   => '',
    default => ''
  }
  $extension_string = $extension ? {
    ''      => '',
    default => "-e ${extension} "
  }
  $filter_string = $filter ? {
    ''      => '',
    default => "-f ${filter} "
  }
  $mode_string = $mode ? {
    ''      => '',
    default => '-m '
  }

  # I will leave trailing _ but this is by far the easiest way to get this to
  # work.
  $command_name = "check_file_ages_${directory}_${extension}_${filter}"

  $command = "command[${command_name}]=/usr/lib/nagios/plugins/check_file_ages.sh -w ${warning} ${recurse_string}-c ${critical} -t ${type} -d ${directory} -a ${number} ${extension_string} ${filter_string} ${mode_string}"

  $service_description = "${nagios_alias}_${command_name}"

  file_line { $command_name:
    ensure => present,
    line   => $command,
    path   => '/etc/nagios/nrpe_local.cfg',
    match  => "command\[${command_name}\]",
    notify => Service[nrpe],
  }

  @@nagios_service { "${command_name}_on_${nagios_alias}":
    check_command       => "check_nrpe_1arg!${command_name}",
    use                 => $nagios_service,
    host_name           => $nagios_alias,
    target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
    service_description => "${nagios_alias}_${command_name}",
    tag                 => $monitoring_environment,
  }

  if $has_parent == true {
    @@nagios_servicedependency { "${command_name}_on_${nagios_alias}_depencency_${parent_service}"
    :
      dependent_host_name           => $nagios_alias,
      dependent_service_description => $service_description,
      host_name                     => $parent_host,
      service_description           => $parent_service,
      execution_failure_criteria    => 'c',
      notification_failure_criteria => 'c',
      target                        => "/etc/nagios3/conf.d/puppet/service_dependencies_${nagios_alias}.cfg",
      tag                           => $monitoring_environment,
    }
  }

}
