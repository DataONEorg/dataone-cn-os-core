#!/usr/bin/perl

use Net::LDAP;
use Net::LDAP::LDIF;
use Carp;
use IO::File;
use Tie::File qw();
use Getopt::Long();

use strict;

my $ldapScriptDir = "/usr/share/dataone-cn-os-core/debian/ldap";
my $ldapServicePropertiesFile = "/etc/dataone/ldapService.properties";
ldap_repl_pem
ldap_repl_key

my $version;
my $help;
my $ldap;

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
      "usage: $command [--help] [--version version]\n" 
   );

   die("\n")
}

sub connectLdap
        {
		my %ldapProperties;
		my $ldapPropertiesFile = IO::File->new("$ldapServicePropertiesFile", "r") || die("unable to open $ldapServicePropertiesFile");
		if (defined $ldapPropertiesFile) 
			{
			my @lines = <$ldapPropertiesFile>;
			foreach my $line (@lines) 
				{
				chomp($line);              # remove the newline from $line.
				my @tokens = split(/=/, $line, 2);
				if(@tokens == 2 ) 
					{ 
					# if this is a key value pair, save it to the hash
					$ldapProperties{$tokens[0]}=$tokens[1];
					}
				}
			} 
		else 
			{
			die ("unable to read $ldapServicePropertiesFile");
			}
		close($ldapPropertiesFile);
        my $ldap = Net::LDAP->new($ldapProperties{'cn.ldap.server'});
        die "unable to connect to ldap" unless (defined($ldap));
        my $mesg;
        my $tls_type;
        if (-e $ldap_repl_pem &&  -e $ldap_repl_key)
                {
                $tls_type = "with auth";
                $mesg = $ldap->start_tls(verify => 'none',
                        clientcert => $ldap_repl_pem,
                        clientkey => $ldap_repl_key);
                }
        else
                {
                $tls_type = "with no auth";
                $mesg = $ldap->start_tls(verify => 'none');
                }
        if ($mesg->is_error())
                {
                die("start_tls $tls_type died: " . $mesg->error_text ());

                }
        my $password = $ldapProperties{'cn.ldap.password'};
        my $mesg = $ldap->bind($ldapProperties{'cn.ldap.admin'}, password=>$ldapProperties{'cn.ldap.password'});
        if ($mesg->is_error())
                {
                die("ldap bind died: " . $mesg->error_text ());
                }
        return $ldap;
        }
        
sub do_verions_1_2_0_changes
	{
	my $slapdRtn=`/etc/init.d/slapd stop`;
	if ($? > 0)
		{
		my @ldapPids=`pidof slapd`;

		if (scalar(@ldapPids) > 0)
			{
			kill 14, $ldapPids[0] || die ("cannot stop slapd\n") ;
			}
		else
			{
			die ("cannot stop slapd\n") ;
			}
		}


	my $newEntry;
	my $ldif = Net::LDAP::LDIF->new( "/etc/ldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif");
	while( not $ldif->eof ( ) )
			{
			my $entry = $ldif->read_entry ();
			if ( $ldif->error ( ) )
					{
					$ldif->done ();
					die  ("Error msg: " . $ldif->error ( ) . "\n" . "Error lines:\n" . $ldif->error_lines ( ) . "\n");
					}
			if (defined ($entry) && ($entry->dn() eq 'olcDatabase={0}config'))
					{
					$newEntry = $entry->clone();
					}
			}
	$ldif->done();
	$newEntry->replace('olcAccess'=>'{0}to *  by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage  by * none');
	$ldif = Net::LDAP::LDIF->new( "/etc/ldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif", "w");
	$ldif->write($newEntry);
	$ldif->done();
	### for some reason the ldif write above adds an empty line at the top of the file, so remove it
	tie my @file, 'Tie::File', "/etc/ldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif" or die ("Could not open /etc/ldap/slapd.d/cn\=config/olcDatabase\=\{0\}config.ldif: $!");
	if ($file[0] =~ //)
			{
			shift @file;
			}
	$slapdRtn= `/etc/init.d/slapd start`;
	die ("cannot start slapd\n") if ($? > 0);
	##### may need to delay the script for a second or two after this or the next portion may not be able to connect to ldap
	sleep 2;
	}
	
my $version;


Getopt::Long::GetOptions(
   'version=s' => \$version,
   'help!' => \$help
) or usage("Invalid commmand line options.");

if ( defined($version) && (length($version) > 0)  && $version =~/^(\d+(?:\.\d+\.\d+)?)/) 
	{
	$version = $1;
	
# do this everytime, too many things can go wrong during and upgrade such that this might not be called, and it needs to be called
# in order for upgrading to ansible to work correctly
	if ($version > 0)
		{
		my $dkg_rtn = `/usr/bin/dpkg --compare-versions $version lt 1.2.0`;
		if ($? == 0) 
			{
			do_verions_1_2_0_changes()
			}
		}
	}
#my $ldap = connectLdap();

##### SOMETHING SHOULD BE HAPPENING HERE FOR TO PREPARE FOR A MIGRATION
#$ldap->unbind;
exit 0;

