class nagios::nrpe::iostat {
  require nagios::nrpe::config
  require basic_server::basic_software
  include nagios::nrpe::service

  $drive = split($::blockdevices, ",")

  nagios::nrpe::iostat::blockdevice_check { $drive: }

  # Create a definition that we can loop through
  define nagios::nrpe::iostat::blockdevice_check {
    case $::processorcount {
      '1'     : {
        $check = "command[check_iostat_$name]=/usr/lib/nagios/plugins/check_iostat.sh -d $name -W -w 999,100,200,50,80 -c 999,200,300,100,100"
      }
      '2'     : {
        $check = "command[check_iostat_$name]=/usr/lib/nagios/plugins/check_iostat.sh -d $name -W -w 999,100,200,50,40 -c 999,200,300,100,50"
      }
      '3'     : {
        $check = "command[check_iostat_$name]=/usr/lib/nagios/plugins/check_iostat.sh -d $name -W -w 999,100,200,50,27 -c 999,200,300,100,33"
      }
      '4'     : {
        $check = "command[check_iostat_$name]=/usr/lib/nagios/plugins/check_iostat.sh -d $name -W -w 999,100,200,50,20 -c 999,200,300,100,25"
      }
      '5'     : {
        $check = "command[check_iostat_$name]=/usr/lib/nagios/plugins/check_iostat.sh -d $name -W -w 999,100,200,50,16 -c 999,200,300,100,20"
      }
      '6'     : {
        $check = "command[check_iostat_$name]=/usr/lib/nagios/plugins/check_iostat.sh -d $name -W -w 999,100,200,50,14 -c 999,200,300,100,16"
      }
      '7'     : {
        $check = "command[check_iostat_$name]=/usr/lib/nagios/plugins/check_iostat.sh -d $name -W -w 999,100,200,50,12 -c 999,200,300,100,14"
      }
      default : {
        $check = "command[check_iostat_$name]=/usr/lib/nagios/plugins/check_iostat.sh -d $name -W -w 999,100,200,50,10 -c 999,200,300,100,13"
      }
    }
    
      file { "check_iostat.sh":
    path   => "/usr/lib/nagios/plugins/check_iostat.sh",
    source => "puppet:///modules/nagios/check_iostat.sh",
    owner  => root,
    group  => root,
    mode   => "0755",
    ensure => present,
    before => File_line["check_iostat_$name"],
  }

    file_line { "check_iostat_$name":
      line   => $check,
      path   => "/etc/nagios/nrpe_local.cfg",
      match  => "command\[check_iostat_$name\]",
      ensure => present,
      notify => Service[nrpe],
    }

    case $::environment {
      'production'  : { $service = "generic-service-excluding-pagerduty" }
      'testing'     : { $service = "generic-service" }
      'development' : { $service = "generic-service-excluding-pagerduty" }
      default       : { $service = "generic-service-excluding-pagerduty" }
    }

    @@nagios_service { "check_iostat_${hostname}_$name":
      check_command         => "check_nrpe_1arg_longtimeout!check_iostat_$name",
      use                   => $service,
      host_name             => $hostname,
      target                => "/etc/nagios3/conf.d/puppet/service_${fqdn}.cfg",
      service_description   => "${hostname}_check_iostat_$name",
      tag                   => "${environment}",
      notifications_enabled => 0,
    }

  }

  @basic_server::motd::register { "Nagios Diskspeed Check $name": }

}
