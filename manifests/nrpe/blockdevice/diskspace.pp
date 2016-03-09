# == Define: nagios::nrpe::blockdevice::diskspace
#
# This will take a drive reference as the name, and use it to create a diskspace
# check. It will also look up the size of the drive to determine the
# warning/critical thresholds as follows:
#
# *Disk Size  < 100GB:
#   -Warning  = 20%
#   -Critical = 10%
# *Disk Size  > 100GB:
#   -Warning  = 10%
#   -Critical = 5%
# *Disk Size  > 1024GB:
#   -Warning  = 4%
#   -Critical = 2%
#
# Note: It will set the name of the check to reference sysvol not xvda for
# cleanness in the nagios server
#
# === Parameters
#
# [*namevar*]
#   This will provide the drive reference (ie xvda from xen machines).
#
# [*options_hash*]
#   This will pass options to the diskcheck.
#   It can take 3 keys:
#   warning: This will override the warning level and should be an integer
#   value.
#   critical: This will override the critical level and should be an integer
#   value.
#   command: This will create an event handler that will run this command. Could
#   be useful for a tricky folder that sometimes fills up. (Generally try to
#   solve this with logrotate rules etc!)
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
#   submitting a check for a virtual ip.
#
# === Variables
#
# [*size*]
#   This is the size in bytes of the drive. This is will call the fact
#   $::blockdevice_${namevar}_size in order to find this.
#
# [*warning*]
#   The % of the diskspace to trigger the warning level at. This is calculated
#   by the above table, with a potential override from $options_hash['warning'].
#
# [*critical*]
#   The % of the diskspace to trigger the critical level at. This is calculated
#   by the above table, with a potential override from $options_hash['critical'].
#
# [*drive*]
#   An override for the nagios service description so that xvda shows as sysvol.
#   Should make nagios easier to read.
#
# === Examples
#
#   nagios::nrpe::blockdevice::diskspace { 'xvda':
#   }
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com>
define nagios::nrpe::blockdevice::diskspace (
  $options_hash           = {
  }
  ,
  $monitoring_environment = $::nagios::nrpe::config::monitoring_environment,
  $nagios_service         = $::nagios::nrpe::config::nagios_service,
  $nagios_alias           = $::hostname) {
  # This has to use a getvar method to return a fact containing another
  # variable in the name.
  $size = getvar("::blockdevice_${name}_size")

  if ($options_hash['warning'] == '' or $options_hash['warning'] == nil or 
  $options_hash['warning'] == undef) {
    # Going to have a different check for very large disks ( gt 100GB) and
    # huge disks (gt 1TB)
    if $size > 15 * 1024 * 1024 * 1024 * 1024 {
      # greater than 15TB
      $warning = '10'
    } elsif $size > 1024 * 1024 * 1024 * 1024 {
      # greater than 1TB
      $warning = '15'
    } elsif $size > 100 * 1024 * 1024 * 1024 {
      # greater than 100GB
      $warning = '18'
    } else {
      $warning = '20'
    }
  } else {
    $warning = $options_hash['warning']
  }

  if ($options_hash['critical'] == '' or $options_hash['critical'] == nil or 
  $options_hash['critical'] == undef) {
    # Going to have a different check for very large disks ( gt 100GB) and
    # huge disks (gt 1TB)
    if $size > 15 * 1024 * 1024 * 1024 * 1024 {
      # greater than 15TB
      $critical = '5'
    } elsif $size > 1024 * 1024 * 1024 * 1024 {
      # greater than 1TB
      $critical = '8'
    } elsif $size > 100 * 1024 * 1024 * 1024 {
      # greater than 100GB
      $critical = '8'
    } else {
      $critical = '10'
    }
  } else {
    $critical = $options_hash['critical']
  }

  file_line { "check_${name}_diskspace":
    ensure => present,
    line   => "command[check_${name}_diskspace]=/usr/lib/nagios/plugins/check_disk -E -w ${warning}% -c ${critical}% -R /dev/${name}*",
    path   => '/etc/nagios/nrpe_local.cfg',
    match  => "command\[check_${name}_diskspace\]",
    notify => Service['nrpe'],
  }

  # For neatness in nagios interface:
  if $name == 'xvda' {
    $drive = 'sysvol'
  } else {
    $drive = $name
  }

  if $event_handler == true {
    file_line { "${drive}_command":
      ensure => present,
      line   => "command[${drive}_command]=${command}",
      path   => '/etc/nagios/nrpe_local.cfg',
      notify => Service['nrpe'],
    }

    @@nagios_service { "check_${drive}_space_${nagios_alias}":
      check_command       => "check_nrpe_1arg!check_${name}_diskspace",
      use                 => $nagios_service,
      host_name           => $nagios_alias,
      target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
      service_description => "${nagios_alias}_check_${drive}_space",
      tag                 => $monitoring_environment,
      event_handler       => "event_handler!${drive}_command",
    }

  } else {
    @@nagios_service { "check_${drive}_space_${nagios_alias}":
      check_command       => "check_nrpe_1arg!check_${name}_diskspace",
      use                 => $nagios_service,
      host_name           => $nagios_alias,
      target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
      service_description => "${nagios_alias}_check_${drive}_space",
      tag                 => $monitoring_environment,
    }

  }

}
