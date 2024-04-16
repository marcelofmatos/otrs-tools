#!/usr/bin/perl

use strict;
#use warnings;
# Desabilita o aviso de "Subroutine redefined"
no warnings 'redefine';

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . "/Kernel/cpan-lib";

use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Main;
use Kernel::System::DB;
use Kernel::System::Auth::HTTPBasicAuth;
use Kernel::System::ObjectManager;
use utf8;
use Encode qw(decode_utf8);
use Net::LDAP;
use Getopt::Long;
use Data::Dumper;

my $ldap_filter;
GetOptions('filter=s' => \$ldap_filter);

my $attrs = [ 'cn','mail' ];
my $sizelimit = 10;

# Inicializa o Object Manager
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-ldapsearch',
    },
);

# Criando instâncias dos objetos necessários
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');
my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
my $AuthObject = $Kernel::OM->Get('Kernel::System::Auth');


# Function to search user by filter
sub search_by_filter {
    my ($host, $port, $base_dn, $bind_dn, $bind_password, $ldap_filter) = @_;
    
    my $ldap = Net::LDAP->new($host, port => $port, verify => 'never');
    if (!$ldap) {
        die "Failed to connect to LDAP server: $@";
    }
    
    my $mesg = $ldap->bind(dn => $bind_dn, password => $bind_password);
    if ($mesg->code) {
        die "Failed to bind to LDAP server: " . $mesg->error;
    }
    
    my $filter = $ldap_filter;
    print "$filter\n";
    if (!$attrs) { 
        $attrs = [ 'cn','mail' ]; 
    }
    $mesg = $ldap->search(
        base      => $base_dn,
        filter    => $filter,
        scope     => "sub",
        attrs     => $attrs,
        sizelimit => $sizelimit,
    );
    #print Dumper($mesg);
    if ($mesg->code) {
        die "LDAP search failed: " . $mesg->error;
    }
    
    my @entries = $mesg->entries;
    if (@entries) {
        return \@entries; # Return array reference of LDAP entries
    } else {
        return; # No user found
    }
}

# ANSI escape codes for colors
my $green = "\e[32m";   # green
my $red = "\e[31m";     # red
my $reset_color = "\e[0m"; # reset color

# Loop from 1 to 9
AuthModuleHOST:
for my $i (1..9) {
    # Acessando o valor correspondente no $ConfigObject
    my $host = $ConfigObject->{"AuthModule::LDAP::Host$i"};

    next AuthModuleHOST if (!$host);

    my $port = 389;

    if(
         $ConfigObject->{"AuthModule::LDAP::Param$i"} 
         && $ConfigObject->{"AuthModule::LDAP::Param$i"}->{'port'}
    ) { 
      $port = $ConfigObject->{"AuthModule::LDAP::Param$i"}->{'port'};
    }

    my $ldap_port       = $port;
    my $base_dn         = $ConfigObject->{"AuthModule::LDAP::BaseDN$i"};
    my $bind_dn         = $ConfigObject->{"AuthModule::LDAP::SearchUserDN$i"};
    my $bind_password   = $ConfigObject->{"AuthModule::LDAP::SearchUserPw$i"};

    print "$host, $ldap_port, $base_dn, $bind_dn, $bind_password, $ldap_filter\n";
    my $result = search_by_filter($host, $ldap_port, $base_dn, $bind_dn, $bind_password, $ldap_filter);

    if (defined $result && @$result) {
        print "User with filter $ldap_filter found:\n";
        foreach my $user (@$result) {
            #print "cn: " . $user->{cn} . "\n";
            #print "mail: " . $user->{mail} . "\n";
            print print Dumper($user);
        }
    } else {
        print "User with filter $ldap_filter not found.\n";
    }
}
