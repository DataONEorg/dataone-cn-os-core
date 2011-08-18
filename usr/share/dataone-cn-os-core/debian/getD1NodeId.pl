#!/usr/bin/perl
use Net::LDAP::LDIF;
use Net::LDAP::Entry;
use strict;

my $cnNodeReference = "ERROR";
my $hostname;
open(HOSTS, '/etc/hosts');

while (<HOSTS>) 
	{
	if ($_ =~ /^(?:[\d\.]+)\s+(cn[^\s]+)\s*/) 
		{
		$hostname= $1;
		last;	
		}
	}
close(HOSTS);

my $ldif = Net::LDAP::LDIF->new( "/usr/share/dataone-cn-os-core/debian/ldap/devNodeList.ldif", "r") || die;

while( not $ldif->eof ( ) ) 
	{
	my $entry = $ldif->read_entry ( );
	if ( $ldif->error ( ) ) 
		{
		print "Error msg: ", $ldif->error ( ), "\n";
#		print "Error lines:\n", $ldif->error_lines ( ), "\n";
		} 
	else 
		{
		my $isCn = $entry->get_value("d1NodeType");
		if ($isCn eq "cn") 
			{
			my $cnUrl = $entry->get_value("d1NodeBaseURL");
			$cnNodeReference = $entry->get_value("d1NodeId") if ($cnUrl =~ /$hostname/);
			}
		}
	}
$ldif->done ( );
print "$cnNodeReference";
exit(0);

