#!/usr/bin/perl -w
use Net::LDAP;
use POSIX qw(strftime);
use Date::Manip;

$argc = $#ARGV + 1;
if ($argc != 3) { die "checkcerts.pl LDAPURI binduser bindpwd"; }
$ldap = Net::LDAP->new( $ARGV[0]) or die "$@";
$mesg = $ldap->bind( $ARGV[1], password => $ARGV[2] );
$mesg = $ldap->search( base => "", filter => "(objectclass=ndspkikeymaterial)" );
$mesg->code && die $mesg->error;
$currenttime = strftime("%Y%m%d", localtime());
$currtime = &ParseDate($currenttime);
$currtimeplus = &DateCalc($currtime, "1 month");

my @entries = $mesg->entries;
 my $entr;
 foreach $entr ( @entries ) {
   my $attr="ndspkinotafter";
   $certdate = substr($entr-> get_value ( $attr ), 0, 8 );
   $crtdate = &ParseDate($certdate);
   $dateresult = &Date_Cmp($currtime,$crtdate);
   $futuredateresult = &Date_Cmp($currtimeplus,$crtdate);
   if ( $dateresult < 0 ) {
         if ( $futuredateresult < 0 ) {
#             print "The certificate ", $entr->dn, " is valid.\n";
          } else {
             print "The certificate ", $entr->dn, " will expire within a month.\n"
          }
   } elsif ($dateresult==0) {
         print "The certificate ", $entr->dn, " expires today.\n";
   } else {
         print "The certificate ", $entr->dn, " has already expired.\n";
   } 
 }
$mesg = $ldap->unbind;

