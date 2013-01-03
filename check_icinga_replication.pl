#!/usr/bin/env perl

#############################################################################
#Used to check the status of the icinga replication

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
