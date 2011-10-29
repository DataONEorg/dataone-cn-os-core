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


my $personid;
my $all;
my $help;

Getopt::Long::GetOptions(
   'id=s' => \$personid,
   'all' => \$all,
   'help!' => \$help
) or usage("Invalid commmand line options.");
 
usage() if (defined $help);

usage("The identifier of the node must be specified.")
   unless ((defined $personid) || (defined $all));


my $ldap = Net::LDAP->new("localhost");

my $mesg = $ldap->bind("cn=admin,dc=dataone,dc=org", password=>"password");

if (defined $all) 
	{
	$mesg = $ldap->search(  filter=>"(objectClass=d1Principal)", 
                        base=>"dc=cilogon,dc=org");
	} else {
	$mesg = $ldap->search(  filter=>"(&(cn=$personid)(objectClass=d1Principal))", 
                        base=>"dc=cilogon,dc=org");

	}
my @entries = $mesg->entries;
foreach my $entry (@entries) 
	{
	my $dn = $entry->dn();
	print "DN = $dn\n";
	$ldap->delete($dn);
	}

$ldap->unbind;

