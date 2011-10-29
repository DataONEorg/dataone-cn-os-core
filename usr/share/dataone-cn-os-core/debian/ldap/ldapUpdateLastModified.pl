#!/usr/bin/perl

use Net::LDAP;
use strict;

use Getopt::Long();

sub usage {
   my $message = $_[0];
   if (defined $message && length $message) {
      $message .= "\n"
         unless $message =~ /\n$/;
   }

   my $command = $0;
   $command =~ s#^.*/##;

   print STDERR (
      $message,
      "usage: $command [--help] --id nodeId\n" 
   );

   die("\n")
}


my $nodeid;
my $all;
my $help;

Getopt::Long::GetOptions(
   'id=s' => \$nodeid,
   'all' => \$all,
   'help!' => \$help
) or usage("Invalid commmand line options.");
 
usage() if (defined $help);

usage("The identifier of the node must be specified.")
   unless ((defined $nodeid) || (defined $all));


my $ldap = Net::LDAP->new("localhost");

my $mesg = $ldap->bind("cn=admin,dc=dataone,dc=org", password=>"password");

if (defined $all) 
	{
	$mesg = $ldap->search( filter=>"&(objectClass=d1Node) (d1NodeType=mn)", 
                        base=>"dc=dataone,dc=org");
	} else {
	$mesg = $ldap->search(  filter=>"(cn=$nodeid)", 
                        base=>"dc=dataone,dc=org");

	}
my @entries = $mesg->entries;
foreach my $entry (@entries) 
	{
	my $dn = $entry->dn();
	print "DN = $dn\n";
	$ldap->modify($dn, replace => {'d1NodeLastHarvested', '1900-01-01T00:00:00.000+00:00'});
	}

$ldap->unbind;

