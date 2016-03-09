# == Class: nagios::nrpe::diskspace
#
# A wrapper class that will break up the fact $::used_blockdevices into its
# constituent parts and pass it to the diskspace check
# nagios::nrpe::blockdevice::diskspace. It also has two extra bits - It removes
# the default check_disk check which would otherwise confuse nrpe, and an extra
# section that tests for lvm usage and adds checks for these.
#
# It would be sensible in the future to combine this with iostat and inodes into
# a single blockdevice check, but all have exceptional sections that would be
# then branched out.
#
# === Parameters
#
#
# [*options_hash*]
#   This will pass options to the diskcheck defines.
#   It should have keys for the drive name you wish to supply details to.
#
# [*monitoring_environment*]
#   This is the environment that the check will be submitted for. This will
#   default to the value set by nagios::nrpe::config but can be overridden here.
#   Not required. This will override the value for the define that it
#   implements.
#
# [*nagios_service*]
#   This is the generic service that this check will implement. This should
#   be set by nagios::nrpe::config but can be overridden here. Not required.
#   This will override the value for the define that it implements.
#
# [*nagios_alias*]
#   This is the hostname that the check will be submitted for. This should
#   almost always be the hostname, but could be overriden, for instance when
#   submitting a check for a virtual ip. Not required. This will override the
#   value for the define that it implements.
#
# === Variables
#
# [*drive*]
#   This is an array built from the blockdevices fact. It should be an array of
#   all the drives.
#
# [*excludedDrives*]
#   A string of all the drives with -I prepended. ie "-I xvda -I xvdb". This is
#   then used to generate a space check for the lvm spaces. There may be a
#   better way of including LVM drives rather than excluding them.
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com>
class nagios::nrpe::diskspace (
  $options_hash           = {},
  $monitoring_environment = $::nagios::nrpe::config::monitoring_environment,
  $nagios_service         = $::nagios::nrpe::config::nagios_service,
  $nagios_alias           = $::hostname) {
  require nagios::nrpe::config
  include nagios::nrpe::service

  # Remove the default check_disk

  file_line { 'check_disk_default':
    ensure => absent,
    line   => 'command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p /',
    path   => '/etc/nagios/nrpe.cfg',
    match  => 'command\[check_disk\]',
    notify => Service[nrpe],
  }

  $drive = split($::used_blockdevices, ',')

  nagios::nrpe::blockdevice::diskspace { $drive:
    monitoring_environment => $monitoring_environment,
    nagios_service         => $nagios_service,
    nagios_alias           => $nagios_alias,
    require                => File_Line['check_disk_default'],
  }

  if $::lvm == true {
    $excludedDrives = join(prefix($drive, '-I '), ' ')

    file_line { 'check_LVM_diskspace':
      ensure => present,
      line   => "command[check_LVM_diskspace]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -p / ${excludedDrives}",
      path   => '/etc/nagios/nrpe_local.cfg',
      match  => 'command\[check_LVM_diskspace\]',
      notify => Service['nrpe'],
    }

    @@nagios_service { "check_LVM_space_${nagios_alias}":
      check_command       => 'check_nrpe_1arg!check_LVM_diskspace',
      use                 => $nagios_service,
      host_name           => $nagios_alias,
      target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
      service_description => "${nagios_alias}_check_LVM_space",
      tag                 => $monitoring_environment,
    }
  }
}
