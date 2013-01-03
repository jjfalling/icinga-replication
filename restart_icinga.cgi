#!/usr/bin/perl

local ($buffer, @pairs, $pair, $value, %FORM);

#this is the auth key we expect before restarting anything:
my $correct_auth_key = '[your auth key from the replication script]';

#here are the commands, you may need to change these
my $check_cfg = `/sbin/service icinga checkconfig`;
my $icinga_status = `/sbin/service icinga status`;
my $restart_icinga = `sudo /sbin/service icinga restart`;


# Read in text
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
if ($ENV{'REQUEST_METHOD'} eq "GET")
{
        $buffer = $ENV{'QUERY_STRING'};
}

# Split information into name/value pairs
@pairs = split(/&/, $buffer);
foreach $pair (@pairs)
{
        ($name, $value) = split(/=/, $pair);
        $value =~ tr/+/ /;
        $value =~ s/%(..)/pack("C", hex($1))/eg;
        $FORM{$name} = $value;
}

my $auth_key = $FORM{auth_key};
#two check_types are: normal, config
my $check_type = $FORM{check_type};

#check if auth key is valid
if ($auth_key eq $correct_auth_key) {
print "Content-type:text/html\r\n\r\n";

        #check if the normal check was requested (checks config, restarts icinga if it is running)
        if ($check_type eq "normal") {

        #check if the sanity check passes
        if ($check_cfg !~ "Running configuration check...OK") {
                print "Configuration sanity check failed: $check_cfg";
                exit;
        }

        #check if icinga is running, dont restart if it is not running (for maint reasons, etc)...
        if ($icinga_status !~ "is running") {
                print "Icinga is not running... You must start it: $icinga_status";
                exit;

        }

        #check passed, restart icinga
        if ($restart_icinga !~ "Starting icinga: Starting icinga done.") {
                print "Icinga did not successfully restart: $restart_icinga";
                exit;

        }

        print "Icinga restarted";

        exit;
        }

        #If config check was requested, simply check the config and exit
        elsif ($check_type eq "config") {
        #check if the sanity check passes
        if ($check_cfg !~ "Running configuration check...OK") {
                        print "Configuration sanity check failed: $check_cfg";
                        exit;

        }
        else {
                        print "Config check passed";
        }

        }

        #if an unknown check was requested, throw an error and exit.
        else {

                if ($check_type eq ""){
                        print "Undefined check type";
                        exit;

                }

                else {
                        print "Unknown check type: $check_type";
                        exit;

                }

        }

}

#auth key invalid, gtfo
else {
        print "Content-type:text/html\r\n\r\n";
        print "Invalid CGI auth key, access denied...";
        exit;

}

exit;