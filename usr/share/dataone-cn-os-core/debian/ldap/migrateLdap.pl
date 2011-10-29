#!/usr/bin/perl

use Net::LDAP;
use Net::LDAP::LDIF;
use strict;

my $ldapScriptDir = "/usr/share/dataone-cn-os-core/debian/ldap";

my @ldifFiles = qw(org.ldif dataone.ldif cilogon.ldif devRobertWaltzPrincipal.ldif devNodeList.ldif);
my $ldap = Net::LDAP->new("localhost");
my $mesg = $ldap->bind("cn=admin,dc=dataone,dc=org", password=>"password");

foreach my $ldifFile (@ldifFiles) 
	{
	my $ldif = Net::LDAP::LDIF->new( "${ldapScriptDir}/${ldifFile}", "r", onerror => 'undef' );
	while( not $ldif->eof ( ) ) 
		{
		my $entry = $ldif->read_entry ( );
		if ( $ldif->error ( ) ) 
			{
			print "Error msg: ", $ldif->error ( ), "\n";
			print "Error lines:\n", $ldif->error_lines ( ), "\n";
			} 
		else 
			{
			$ldap->add($entry);
			}
	    }
	$ldif->done ( );
	}

$ldap->unbind;

