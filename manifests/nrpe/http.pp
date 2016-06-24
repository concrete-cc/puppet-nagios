# == Define: nagios::nrpe::http
#
# This class will allow us to check the http response from a server. This will
# currently respond with OK for a 200/300 response, Warning for a 400 response,
# and Critical for no response. This  may want to be tuned. There is also an
# option in the check (but not this manifest) to allow greater response parsing.
# This can be integrated later as situations require.
#
# === Parameters
#
# [*namevar*]
#   The hostname will default to the name of the resource. This is the hostname
#   that the check will send the request to. This will bypass dns, but will make
#   impacts on web servers with more than one hostname and also servers serving
#   https (complete necessity here).
#
# [*health_check_url*]
#   The sub url to check i.e. /ping or /health_check.
#   Not required. Defaults to /
#
# [*port*]
#   The port to check. Annoyingly, will require an override if you use https
#   (set it to 443), as the default is 80.
#   Not required. Defaults to 80
#
# [*has_parent*]
#   Whether this http response has a parent service dependency (eg nginx,
#   tomcat).
#   Not required. Defaults to true.
#
# [*parent_service*]
#   The name of the parent host, if has_parent is set to true (eg
#   ${hostname}).
#   Defaults to $::hostname. Not required.
#
# [*parent_service*]
#   The name of the parent service, if has_parent is set to true (eg
#   ${hostname}_check_nginx).
#   Required if has parent is true. Defaults to "".
#
#   Note: This is not tested.
#
# [*ssl*]
#   Boolean for whether it should use http or https. Note: You will have to
#   change the port as well!
#   Not required. Defaults to false.
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
# [*service_description*]
#   A placeholder for the service description that makes it slightly neater to
#   read.
#
# [*command*]
#   This is the command that nrpe will use to check the file count.
#
# [*protocol*]
#   The represents the string for the connection protocol. Translation of ssl.
#
# [*expect*]
#   The represents the string to expect.
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com>
define nagios::nrpe::http (
  $host                   = $name,
  $health_check_uri       = '/',
  $port                   = '80',
  $has_parent             = false,
  $parent_service         = '',
  $expect                 = '',
  $parent_host            = $::hostname,
  $ssl                    = false,
  $monitoring_environment = $::nagios::nrpe::config::monitoring_environment,
  $nagios_service         = $::nagios::nrpe::config::nagios_service,
  $nagios_alias           = $::hostname,) {
  require nagios::nrpe::config
  include nagios::nrpe::service

  if $ssl == true {
    $protocol = 'HTTPS'
  } else {
    $protocol = 'HTTP'
  }
  $service_description = "${nagios_alias}_check_${host}_${port}_${protocol}_${health_check_uri}"

  if $expect == '' {
    if $ssl == true {
      $command = 'check_https_nonroot_custom_port'
    } else {
      $command = 'check_http_nonroot_custom_port'
    }

    @@nagios_service { "check_${health_check_uri}_at_${host}_${port}_${protocol}_on_${nagios_alias}"
    :
      check_command       => "${command}!${host}!${health_check_uri}!${port}",
      use                 => $nagios_service,
      host_name           => $nagios_alias,
      target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
      service_description => $service_description,
      tag                 => $monitoring_environment,
    }

  } else {
    if $ssl == true {
      $command = 'check_https_custom_string_nonroot_custom_port'
    } else {
      $command = 'check_http_custom_string_nonroot_custom_port'
    }

    @@nagios_service { "check_${health_check_uri}_at_${host}_${port}_${protocol}_on_${nagios_alias}"
    :
      check_command       => "${command}!${host}!${health_check_uri}!${port}!${expect}",
      use                 => $nagios_service,
      host_name           => $nagios_alias,
      target              => "/etc/nagios3/conf.d/puppet/service_${nagios_alias}.cfg",
      service_description => $service_description,
      tag                 => $monitoring_environment,
    }
  }

  if $has_parent == true {
    @@nagios_servicedependency { "${health_check_uri}_at_${host}_on_${nagios_alias}_depencency_${parent_service}"
    :
      dependent_host_name           => $nagios_alias,
      dependent_service_description => $service_description,
      host_name => $parent_host,
      service_description           => $parent_service,
      execution_failure_criteria    => 'c',
      notification_failure_criteria => 'c',
      target    => "/etc/nagios3/conf.d/puppet/service_dependencies_${nagios_alias}.cfg",
      tag       => $monitoring_environment,
    }
  }
}
