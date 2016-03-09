# == Define: nagios::nrpe::mysql::package
#
# This is going install the percona mysql plugins for the other mysql checks and
# also add the nagios user to the mysql group which is needed for most of the
# checks.
#
# IMPORTANT NOTE: It requires you to have already set up the apt repositories
# from https://www.percona.com/doc/percona-server/5.6/installation/apt_repo.html
#
# Note: Most of these checks will need a nagios mysql user with credentials at
# /etc/nagios/mysql.cnf
#
# === Authors
#
# Ben Field <ben.field@concreteplatform.com>
class nagios::nrpe::mysql::package {
  package { 'percona-nagios-plugins': ensure => installed, }

  user { 'nagios_mysql':
    name   => 'nagios',
    groups => ['mysql'],
  }
}