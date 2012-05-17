#!/usr/bin/perl

use Getopt::Long();
use Net::LDAP::LDIF;
use Net::LDAP::Entry;
use strict;

my $environment;
my $help;

Getopt::Long::GetOptions(
   'env=s' => \$environment,
   'help' => \$help
) or usage("Invalid commmand line options.");
 
usage() if (defined $help);

usage() if (!defined $environment);

   
my $cnNodeReference = "ERROR";
my $hostname = `/bin/hostname -f`;
chomp($hostname);
print "'${hostname}'\n";
my $cnUrl = "NOOP";

my $ldif = Net::LDAP::LDIF->new( "/usr/share/dataone-cn-os-core/debian/ldap/${environment}NodeList.ldif", "r") || die;

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
		print "$isCn\n";
		if ($isCn eq "cn") 
			{
			$cnUrl = $entry->get_value("d1NodeBaseURL");
			print "'${cnUrl}'\n";
			if ($cnUrl =~ /$hostname/) 
				{
				$cnNodeReference = $entry->get_value("d1NodeId");
				last;
				} else {
				$cnUrl = "NOOP";
				}
			}
		}
	}
$ldif->done ();
print "$cnNodeReference,$cnUrl";
exit(0);

