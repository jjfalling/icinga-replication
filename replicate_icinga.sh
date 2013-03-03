#!/usr/bin/env bash
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

#****************************************************************************
#*   Replicate Icinga                                                       *
#*   Replicates a master icinga's config to a slave                         *
#*                                                                          *
#*   Copyright (C) 2013 by Jeremy Falling except where noted.               *
#*                                                                          *
#*   This program is free software: you can redistribute it and/or modify   *
#*   it under the terms of the GNU General Public License as published by   *
#*   the Free Software Foundation, either version 3 of the License, or      *
#*   (at your option) any later version.                                    *
#*                                                                          *
#*   This program is distributed in the hope that it will be useful,        *
#*   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
#*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
#*   GNU General Public License for more details.                           *
#*                                                                          *
#*   You should have received a copy of the GNU General Public License      *
#*   along with this program.  If not, see <http://www.gnu.org/licenses/>.  *
#****************************************************************************

#replicates icinga by rsyncing config to slave, restarting icinga if needed, and if restart is not needed checking the config.

#example crontab line:
# */5 * * * * /opt/icinga/replicate_icinga.sh > /var/log/icinga_replication.log 2>&1


##################################################
#Init some stuff
##################################################
restart_icinga="0"
failure="0"
status_file="/var/tmp/icinga_replication.stat"

##################################################
#Functions
##################################################

#this checks to see if each rsync instance runs correctly
# and puts the exit status in the log
function check_rsync {

        status=$?
        echo "Rsync exit status is: $status"

        if [ "$status" != "0" ] && [ "$status" != "24" ]; then

                failure="1"

        fi
}

##################################################
#Check if stat file exists, if not create
##################################################
date

if [ -f $status_file ];
then
   echo "Status file $status_file exists, not re-creating"
else
   echo "Status file $status_file does not exist, creating"
   touch $status_file
fi


##################################################
#Send data to slave
##################################################
#send config to slave
echo "Sending config files to slave"
rsync_conf=`rsync --delete --stats -arp --exclude 'core_checks' /opt/icinga/etc/ rsync://user@icinga-slave.domain.tld/icinga-config/`
check_rsync

#send plugins to slave
echo "Sending plugin files to slave"
rsync_plugins=`rsync --delete --stats -arp /opt/icinga/libexec/ rsync://user@icinga-slave.domain.tld/icinga-plugins/`
check_rsync


##################################################
#Check if rsync had issues
##################################################
#was there a problem with the last group of commands?
if [ "$failure" != "0" ]
then
        #rsync error, exit with error
        echo "ERROR: RSYNC PROBLEM!"
        echo "2|Problem copying files" > $status_file
        exit 1

fi

##################################################
#Check if any files were transfered
##################################################
#see how many files were transferred
num_transf1=`echo "$rsync_conf" | grep "Number of files transferred" | grep -o "[0-9999999]"`

if [ "$num_transf1" -gt "0" ]
then
        let restart_icinga++

fi


#see how many files were transferred
num_transf2=`echo "$rsync_plugins" | grep "Number of files transferred" | grep -o "[0-9999999]"`

#check if any files were transferred
if [ "$num_transf2" -gt "0" ]
then
        let restart_icinga++

fi

##################################################
#Restart icinga if needed
##################################################
#did any files get pushed?
if [ "$restart_icinga" -gt "0" ]
then
        #yes, so restart icinga on slave
        echo "More then 0 files transfered, restarting Icinga"

        #curl the cgi to restart the service
        restart_result=`curl -s "http://icinga-slave.domain.tld/cgi-bin/restart_icinga.cgi?auth_key=[change this to you r key]&check_type=normal"`

        #check if everything is okay
        if [ "$restart_result" == "Icinga restarted" ]
        then
                #looks like icinga exited okay
                echo "Icinga has restarted"
                echo "0|Everything seems okay" > $status_file

        else
                #dosnt look like things went well....
                echo "Error: $restart_result"
                echo "2| $restart_result" > $status_file

        fi

else

        #no restart needed, check if config test passes
        echo "No files transfered, checking Icinga config"

        #curl the cgi to restart the service
        checkcfg_result=`curl -s "http://icinga-slave.domain.tld/cgi-bin/restart_icinga.cgi?auth_key=[change this to you r key]&check_type=config"`

        #check if everything is okay
        if [ "$checkcfg_result" == "Config check passed" ]
        then
                #looks like icinga exited okay
                echo "Icinga config seems fine"
                echo "0|Everything seems okay" > $status_file

        else
                #dosnt look like things went well....
                echo "Error: $checkcfg_result"
                echo "2| $checkcfg_result" > $status_file

        fi


fi


##################################################
#Functions
##################################################
#this checks to see if each rsync instance runs correctly
# and puts the exit status in the log
function check_rsync {

        status=$?
        echo "Rsync exit status is: $status"

        if [ "$status" != "0" ] && [ "$status" != "24" ]; then

                failure="1"

        fi
}
