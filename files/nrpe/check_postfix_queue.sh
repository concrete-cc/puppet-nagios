#!/bin/bash
# ----------check_postfix_queue.sh-----------
# This is going to check the size of the mail queue is below a certain value. 
#
# Version 0.01 - Jan/2015
# by Ben Field / ben.field@concreteplatform.com

# Exit codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

function help {
	echo -e "
	This is going to check the the size of the mail queue is below a certain value. 
		
	Usage:

	-w,-c = Warning and critical levels respectively. Required parameter.
 	
 	-h = This help
	"
	exit -1
}

# ----------PARAMETER INPUT AND TESTING-----------

WARNINGFLAG=false
ARGUMENTFLAG=false
RECURSE=""

while getopts "w:c:" OPT; do
	case $OPT in
		"w") WARNING=$OPTARG
		WARNINGFLAG=true
		;;
		"c") CRITICAL=$OPTARG
		CRITICALFLAG=true
		;;
		"h") echo "help:" && help
		;;
		\?) echo "UNKNOWN - Invalid option: -$OPT" >&2
		ARGUMENTFLAG=true
		;;
		:) echo "UNKNOWN - Option -$OPTARG requires an argument" >&2
		ARGUMENTFLAG=true
		;;
	esac
done		

#Checks to see if any arguments are missing:
if ! $WARNINGFLAG; then
	echo "UNKNOWN - Warning level parameter required" >&2
	ARGUMENTFLAG=true
fi
if ! $CRITICALFLAG; then
	echo "UNKNOWN - Critical level parameter required" >&2
	ARGUMENTFLAG=true
fi

#Checks for sane Warning/Critical levels
if [ $WARNING -gt $CRITICAL ]; then
	echo "UNKNOWN - Warning level should not be greater than Critical level" >&2
	ARGUMENTFLAG=true
fi

if $ARGUMENTFLAG; then
	exit $STATE_UNKNOWN
fi

# ----------EMAILS CALCULATION-----------

EMAILS=`mailq | egrep -c "^[A-F0-9]{12}"`

# ----------LOW MEMORY TEST AND RETURN TO NAGIOS-----------

if [ $EMAILS -ge $CRITICAL ]; then
        echo "CRITICAL - $EMAILS in mail queue"
        exit $STATE_CRITICAL
elif [ $EMAILS -ge $WARNING ]; then
        echo "WARNING - $EMAILS in mail queue"
        exit $STATE_WARNING
else
        echo "OK - $EMAILS in mail queue"
        exit $STATE_OK
fi