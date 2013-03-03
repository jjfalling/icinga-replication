#!/usr/bin/env perl

#****************************************************************************
#*   Check Icinga Replication                                               *
#*   Checks the status of replication between icinga master and slave       *
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

use strict;
use warnings;

###########################################################################
#you might need to change the location of the stat file
my $stat_file="/var/tmp/icinga_replication.stat";

#how long should we go before complaining that the replication has not ran?
#using 15 min to start
my $threshhold = 900;

#nagios/icinga exit codes
my $STATE_OK = 0;
my $STATE_WARNING = 1;
my $STATE_CRITICAL = 2;
my $STATE_UNKNOWN = 3;

###########################################################################
#First, check if stat file exists and if it has been modified within 
# the threshold time.

#check if file exists
unless (-e $stat_file) {
        print "Stat file does not exist! $stat_file";
        exit $STATE_UNKNOWN;
} 

# The get file info and current time
my $mtime = (stat("$stat_file"))[9];
my $currenttime = time();

#see if current time 
if( ($currenttime - $mtime) > $threshhold){
        #file was not modified within threshhold, exit with error
        print "Replication has NOT ran in the last $threshhold seconds";
        exit $STATE_CRITICAL;

}


###########################################################################
#File check passed, now read data from file

my $lines = 0;

#open stat file and read data
open FILE, "$stat_file" or die $!;
$lines++ while (<FILE>);
seek (FILE, 0, 0);
chomp(my $stat_data = <FILE>);

#if number of lines is not 1, exit w/ error
unless ($lines = 1) {
        print "Unexpected number of lines in stat file. Expected 1, found $lines";
        exit $STATE_UNKNOWN;

}

#read data from file
close FILE;


#get the error code and exit with it
my ($err_code, $message) = split (/\|/, $stat_data, 2);

print "$message";
exit $err_code;
