# == Class: nagios::nrpe::config
#
# This will perform the configuration of the nrpe so that it allows the server
# to connect to it. It will also add nrpe checks for servers. The defaults are
# probably sensible for a normal linux server.
#
# === Variables
#
# [*server*]
#   This is the ip address for the nagios server, which will be added to the
#   allowed host line in the nagios nrpe config. Required.
#
# [*monitoring_environment*]
#   This is the environment that the check will be submitted for. This will set
#   the default for all checks added to nodes. Required.
#
# [*nagios_service*]
#   This is the generic service that this check will implement. This will set
#   the default for all checks added to nodes. Required.
#
# [*diskspace*]
#   Whether to add a nagios check for diskspace on every drive.
#   Not required. Defaults to true.
#
# [*inodes*]
#   Whether to add a nagios check for inodes on every drive.
#   Not required. Defaults to true.
#
# [*iostat*]
#   Whether to add a nagios check for disk speed on every drive.
#   Not required. Defaults to true.
#
# [*kernel_leak*]
#   Whether to add a nagios check for kernel_leaks. This is slightly situational
#   and potentially not useful, but only is used on 32 bit systems anyway
#   Not required. Defaults to true.
#
# [*load*]
#   Whether to add a nagios check for system load.
#   Not required. Defaults to true.
#
# [*memory*]
#   Whether to add a nagios check for memory usage.
#   Not required. Defaults to true.
#
# [*ntp*]
#   Whether to add a nagios check for ntp sync. This will by default check the
#   time difference with the nagios server itself.
#   Not required. Defaults to true.
#
# [*total_procs*]
#   Whether to add a nagios check for total processes. This is probably not
#   useful.
#   Not required. Defaults to true.
#
# [*zombie_procs*]
#   Whether to add a nagios check for zombie processes.
#   Not required. Defaults to true.
#
# [*lowmemory*]
#   Whether to add a nagios check for lowmemory (which only applies to 32 bit
#   systems). Kernel leak is similar, so generally that should be used instead.
#   Not required. Defaults to true.
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com
class nagios::nrpe::config (
  $server,
  $nagios_service,
  $monitoring_environment,
  $diskspace    = true,
  $inodes       = true,
  $iostat       = true,
  $kernel_leak  = true,
  $load         = true,
  $memory       = true,
  $ntp          = true,
  $total_procs  = true,
  $zombie_procs = true,
  $lowmemory    = false) {
  require nagios::nrpe::package
  include nagios::nrpe::service

  $hosts = "allowed_hosts=127.0.0.1,${server}"

  file { '/etc/nagios/nrpe_local.cfg':
    ensure => present,
    mode   => '0644'
  }

  file_line { 'include':
    ensure => present,
    line   => 'include=/etc/nagios/nrpe_local.cfg',
    path   => '/etc/nagios/nrpe.cfg',
    match  => '^include=',
    notify => Service[nrpe],
  }

  file_line { 'allowed_hosts':
    ensure => present,
    line   => $hosts,
    path   => '/etc/nagios/nrpe.cfg',
    match  => '^allowed_hosts',
    notify => Service[nrpe],
  }

  if $diskspace == true {
    class { '::nagios::nrpe::diskspace': }
  }

  if $inodes == true {
    class { '::nagios::nrpe::inodes': }
  }

  if $iostat == true {
    class { '::nagios::nrpe::iostat': }
  }

  if $kernel_leak == true {
    class { '::nagios::nrpe::kernel_leak': }
  }

  if $load == true {
    class { '::nagios::nrpe::load': }
  }

  if $memory == true {
    class { '::nagios::nrpe::memory': }
  }

  if $ntp == true {
    class { '::nagios::nrpe::ntp': }
  }

  if $total_procs == true {
    class { '::nagios::nrpe::total_procs': }
  }

  if $zombie_procs == true {
    class { '::nagios::nrpe::zombie_procs': }
  }

  if $lowmemory == true {
    class { '::nagios::nrpe::lowmemory': }
  }

  case $::operatingsystem {
    'RHEL', 'CentOS', 'RedHat' : {
      firewall { '200 allow nrpe access':
        dport  => [5666],
        proto  => tcp,
        action => accept,
      }
    }
    default                    : {
    }
  }

}
