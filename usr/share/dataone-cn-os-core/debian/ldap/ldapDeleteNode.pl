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
      "usage: $command [--help] --password password [--id nodeId] | [--all]\n" 
   );

   die("\n")
}

my $password;
my $nodeid;
my $all;
my $help;

Getopt::Long::GetOptions(
   'id=s' => \$nodeid,
   'password=s' => \$password,
   'all' => \$all,
   'help!' => \$help
) or usage("Invalid commmand line options.");
 
usage() if (defined $help);

usage() if (!defined $password);

usage("The identifier of the node must be specified.")
   unless ((defined $nodeid) || (defined $all));


my $ldap = Net::LDAP->new("localhost");

my $mesg = $ldap->start_tls(verify => 'none',
    clientcert => 'REPLICATION_CERTIFICATE',
    clientkey => 'REPLICATION_CERTIFICATE_KEY'
);

my $mesg = $ldap->bind("cn=admin,dc=dataone,dc=org", password=>${password});


if (defined $all) 
	{
	$mesg = $ldap->search(  filter=>"(objectClass=d1ServiceMethodRestriction)", 
                      base=>"dc=dataone,dc=org");
    } else {
    $mesg = $ldap->search(  filter=>"(&(objectClass=d1ServiceMethodRestriction) (d1NodeId=$nodeid))", 
    	base=>"dc=dataone,dc=org");
    }
my @entries = $mesg->entries;
foreach my $entry (@entries) 
	{
	my $dn = $entry->dn();
	print "DN = $dn\n";
	$ldap->delete($dn);
	}


if (defined $all) 
	{
	$mesg = $ldap->search(  filter=>"(objectClass=d1NodeService)", 
                        base=>"dc=dataone,dc=org");
	} else {
	$mesg = $ldap->search(  filter=>"(&(objectClass=d1NodeService) (d1NodeId=$nodeid))", 
                        base=>"dc=dataone,dc=org");
	}

my @entries = $mesg->entries;
foreach my $entry (@entries) 
	{
	my $dn = $entry->dn();
	print "DN = $dn\n";
	$ldap->delete($dn);
	}

if (defined $all) 
	{
	$mesg = $ldap->search(  filter=>"(objectClass=d1Node)", 
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
	$ldap->delete($dn);
	}

$ldap->unbind;

