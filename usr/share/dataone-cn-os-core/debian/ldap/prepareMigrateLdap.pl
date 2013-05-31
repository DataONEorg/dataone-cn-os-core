#!/usr/bin/perl

use Net::LDAP;
use Net::LDAP::LDIF;
use Carp;
use IO::File;
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
my $version;

Getopt::Long::GetOptions(
   'version=s' => \$version,
   'help!' => \$help
) or usage("Invalid commmand line options.");


my $ldap = connectLdap();

##### SOMETHING SHOULD BE HAPPENING HERE FOR TO PREPARE FOR A MIGRATION
$ldap->unbind;

