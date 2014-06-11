#!/usr/bin/perl

use Carp;
use Getopt::Long();
use Cwd qw(getcwd chdir);
use strict;

my $version;
my $help;

my  ($login,$pass,$uid,$gid) = getpwnam("tomcat7") or die "tomcat7 not in passwd file";

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

sub do_verions_1_2_1_changes
	{
	my $fileList;
	my $orig_dir = getcwd();
	chdir("/");
	open(FIND_TOMCAT6, 'find / ! -path "/etc/tomcat6/**" ! -path "/etc/tomcat6" ! -path "/var/log/tomcat6/**" ! -path "/var/log/tomcat6"  ! -path "/usr/share/tomcat6/**" ! -path "/usr/share/tomcat6" ! -path "/etc/authbind/**" ! -path "/proc/**" ! -path "/tmp/**"  -user tomcat6 -group tomcat6 -print |');
	## set autoflusth
	select((select(FIND_TOMCAT6), $| = 1)[0]);
	my @tomcat6_files;
	while (<FIND_TOMCAT6>) 
		{
		my $filename = $_;
		chomp($filename);
		push (@tomcat6_files, $filename);
	
		}
	close (FIND_TOMCAT6);
#	foreach my $filename (@tomcat6_files)
#		{
#		print STDOUT "$filename\n";
#		}
	@tomcat6_files = undef;
	chown $uid,$gid, @tomcat6_files;
	open(FIND_TOMCAT6, 'find / ! -path "/etc/tomcat6/**" ! -path "/etc/tomcat6" ! -path "/var/log/tomcat6/**" ! -path "/var/log/tomcat6"  ! -path "/usr/share/tomcat6/**" ! -path "/usr/share/tomcat6" ! -path "/etc/authbind/**" ! -path "/proc/**" ! -path "/tmp/**"  -user tomcat6 -print |');
	## set autoflusth
	select((select(FIND_TOMCAT6), $| = 1)[0]);
	for (<FIND_TOMCAT6>) 
		{
		my $filename = $_;
		chomp($filename);
		push (@tomcat6_files, $filename);
		}
	close (FIND_TOMCAT6);
#	foreach my $filename (@tomcat6_files)
#		{
#		print STDOUT "$filename\n";
#		}
	chown $uid,-1, @tomcat6_files;
	my $chownrtn = `chown -h $uid:$gid /usr/share/maven-repo/org/noggit/noggit/debian/noggit-debian.jar /usr/share/java/noggit.jar`;

	chdir($orig_dir);
	}
	



Getopt::Long::GetOptions(
   'version=s' => \$version,
   'help!' => \$help
) or usage("Invalid commmand line options.");


# TODO uncomment the blow code when adding to branch of 1.2.2 release

#my $dkg121_rtn = 0;
#my $rtnjunk= `/usr/bin/dpkg --compare-versions $version eq 1.2.1`;
#if ($? == 0) 
#	{
#	$dkg121_rtn = 1;
#	}
#my $rtnjunk = `/usr/bin/dpkg --compare-versions $version eq 1.2.2`;
#if ($? == 0)
#	{
#	$dkg121_rtn = 1;
#	}
#if ($dkg121_rtn) 
#	{
	do_verions_1_2_1_changes();
#	}
exit 0;
