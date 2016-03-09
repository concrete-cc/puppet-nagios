#Nagios

#### Table of contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with nagios](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
6. [Development - Guide for contributing to the module](#development)

##Overview

A puppet nagios module that will configure both the nagios server and nrpe clients. The client configuration includes checks for almost everything you need.

##Module Description

The server submodule provides a built, nagios server. It will work fully from scratch. The most important module is nagios::server::config which will ensure it compiles the client checks, as well as give you several options for how to configure the various notification plugins and check plugins. The details of these are in the manifest documentation.

The client class will set up a host on the nagios server. The basic classes is nagios::client, which will set up a host for the client and nagios::nrpe::config which will set up the nrpe client (as well as all the normal server checks by default).

There are also several checks which you will useful, these are all contained in nagios::nrpe::*. 

##Setup 

Important Note:

This module will require you to have puppetdb set up as the checks and clients are collected by external resource collectors.

Simply install the module, and add the nagios::server::config to your server to have a fully working nagios server. It will be accessible at http://fqdn with the password you set and the nagiosadmin user.

Then add nagios::nrpe::config and nagios::client to each node in order to have a fully functioning (if slightly limited!) nagios environment.

##Usage

For more information please look at the documentation contained in each class.

###Nagios Server (default)

This will set up a nagios server with only email notification.

####Example:

	nagios::server::config {
		monitoring_environment => 'production',
		password               => 'nagios_password'
	}

###Nagios Server (hipchat notification)

This will set up a nagios server with email and hipchat notification.

####Example:

	nagios::server::config {
		monitoring_environment => 'production',
		password               => 'nagios_password',
		hipchat                => true
	}

	nagios::server::notification::hipchat {
		token                  => 'hipchat_token',
		room                   => 'hipchat_room',
		contacts               =>  { 'hipchat' => { alias => 'Hipchat Contact' } }
	}

###Nagios Server (pagerduty notification)

This will set up a nagios server with email and pagerduty notification. You will need to have set up the pagerduty apt repository seperately!

####Example:

	nagios::server::config {
		monitoring_environment => 'production',
		password               => 'nagios_password',
		pagerduty              => true
	}

	nagios::server::notification::pagerduty {
		pager                  => 'pagerduty_pager',
		contacts               =>  { 'pagerduty' => { alias => 'Pagerduty Contact' },
                                 'pagerduty_non_urgent' => { alias => 'Pagerduty Non Urgent Contact',
                                 service_notification_period => 'non_urgent_hours' } }
	}

###Nagios Client (Only Ping Check)

This will set up just a host with a ping check

####Example:

	nagios::client {
		nagios_service         => 'generic_service',
		monitoring_environment => $::environment
	}

###Nagios Client (With NRPE and basic server checks)



This will set up a host with a series of the most useful basic server checks. 

####Example:

Where nagios server is at 192.168.1.1:

	nagios::client {
		nagios_service         => 'generic_service',
		monitoring_environment => $::environment
	}

	nagios::nrpe::config {
		server                 => '192.168.1.1',
		nagios_service         => 'generic_service',
		monitoring_environment => $::environment
	}

Default Checks are:

* Diskspace
* Inodes
* Iostat (diskspeed)
* Kernel_leak (for 32 bit systems)
* Load
* Memory
* NTP
* Total Procs
* Zombie Procs

###Nagios HTTP Check

This will add an http check on a server that already has nagios::client.

####Example:

	nagios::nrpe::http { $::fqdn:
    	health_check_uri => '/',
    	port             => '80',
    	ssl              => false,
    	nagios_service   => 'generic_service'
	}

###Nagios TCP Check

This will add a process check on a server that already has nagios::client.

####Example:

	nagios::nrpe::process { "${::hostname} dummy process":
    	process          => 'dummy',
    	warning_low      => '1',
    	critical_low     => '1',
    	event_handler    => false,
	}

###Other Individual Checks

Please look at the the individual manifest documentation for more information.

##Reference

Please look at the rdoc inside each manifest for more information.

##Development

Please feel free to submit any issues or pull requests to the github page.

###Changelog

Version:

* 2: A large refactor of the server manifests in order to make it totally self sufficent.
* 2.1: A refactor of nagios::nrpe::config to make it self sufficent. Also updated readme.
* 2.2: A change to nagios::nrpe::config to reenable individual check overrides. Added json_file check.
* 2.3: Added support for centos clients (not servers) and fixed a fairly large mistake with iostat where a requirement was impossible.
* 2.4: Added a new check postfix_queue, which will check the length of a postfix queue.
* 2.5: Updated diskspace to be able to take options as a hash from hiera. Also allowed it to run a command on a full disk. May cause issues with backwards compatibility if you were previously overriding values with enc facts.