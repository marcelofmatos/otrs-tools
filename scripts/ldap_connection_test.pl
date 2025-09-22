#!/usr/bin/env perl

use strict;
use warnings;
no warnings 'redefine';

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

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-ldapsearch',
    },
);

my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $EncodeObject = $Kernel::OM->Get('Kernel::System::Encode');
my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
my $MainObject = $Kernel::OM->Get('Kernel::System::Main');
my $DBObject = $Kernel::OM->Get('Kernel::System::DB');
my $HTTPBasicAuthObject = $Kernel::OM->Get('Kernel::System::Auth');

sub testar_conexao_ldap {
    my ($host, $port) = @_;
    
    my $ldap = Net::LDAP->new($host, port => $port);
    if ($ldap) {
        $ldap->disconnect;
        return 1;
    } else {
        return $@;
    }
}

my $green = "\e[32m";
my $red = "\e[31m";
my $color_reset = "\e[0m";

print "AuthModule:\n";
AuthModuleHOST:
for my $i (0..9) {
    my $suffix = $i == 0 ? '' : $i;
    my $host = $ConfigObject->{"AuthModule::LDAP::Host$suffix"};
    my $base_dn = $ConfigObject->{"AuthModule::LDAP::BaseDN$suffix"};

    next AuthModuleHOST if (!$host);

    my $port = 389;

    if (
         $ConfigObject->{"AuthModule::LDAP::Param$suffix"} 
         && $ConfigObject->{"AuthModule::LDAP::Param$suffix"}->{'port'}
    ) { 
      $port = $ConfigObject->{"AuthModule::LDAP::Param$suffix"}->{'port'};
    }

    my $resultado = testar_conexao_ldap($host, $port);
    
    if ($resultado == 1) {
        print "Host$i: $host($base_dn): ${green}OK${color_reset}\n";
    } else {
        print "Host$i: $host($base_dn): ${red}erro na conexão${color_reset}: $resultado\n";
    }    
}

print "AuthSyncModule:\n";
AuthSyncModuleHOST:
for my $i (0..9) {
    my $suffix = $i == 0 ? '' : $i;
    my $host = $ConfigObject->{"AuthSyncModule::LDAP::Host$suffix"};
    my $base_dn = $ConfigObject->{"AuthSyncModule::LDAP::BaseDN$suffix"};

    next AuthSyncModuleHOST if (!$host);

    my $port = 389;

    if (
         $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"} 
         && $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"}->{'port'}
    ) { 
      $port = $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"}->{'port'};
    }

    my $resultado = testar_conexao_ldap($host, $port);
    
    if ($resultado == 1) {
        print "Host$i: $host($base_dn): ${green}OK${color_reset}\n";
    } else {
        print "Host$i: $host($base_dn): ${red}erro na conexão${color_reset}: $resultado\n";
    }    
}

print "CustomerUser:\n";
CustomerUserHOST:
for my $i (0..9) {
    my $suffix = $i == 0 ? '' : $i;
    
    next if (!($ConfigObject->{"CustomerUser$suffix"}));

    my $host = $ConfigObject->{"CustomerUser$suffix"}->{"Params"}->{"Host"};
    my $base_dn = $ConfigObject->{"CustomerUser$suffix"}->{"Params"}->{"BaseDN"};

    next if (!($ConfigObject->{"CustomerUser$suffix"}->{"Module"} eq "Kernel::System::CustomerUser::LDAP"));

    next CustomerUserHOST if (!$host);

    my $port = 389;

    if (
         $ConfigObject->{"CustomerUser$suffix"}->{"Params"}
         && $ConfigObject->{"CustomerUser$suffix"}->{"Params"}->{'Params'}->{'port'}
    ) { 
      $port = $ConfigObject->{"CustomerUser$suffix"}->{"Params"}->{'Params'}->{'port'};
    }

    my $resultado = testar_conexao_ldap($host, $port);
    
    if ($resultado == 1) {
        print "Host$i: $host($base_dn): ${green}OK${color_reset}\n";
    } else {
        print "Host$i: $host($base_dn): ${red}erro na conexão${color_reset}: $resultado\n";
    }    
}

print "Customer::AuthModule:\n";
CustomerAuthModuleHOST:
for my $i (0..9) {
    my $suffix = $i == 0 ? '' : $i;
    my $host = $ConfigObject->{"Customer::AuthModule::LDAP::Host$suffix"};
    my $base_dn = $ConfigObject->{"Customer::AuthModule::LDAP::BaseDN$suffix"};

    next CustomerAuthModuleHOST if (!$host);

    my $port = 389;

    if (
         $ConfigObject->{"Customer::AuthModule::LDAP::Param$suffix"} 
         && $ConfigObject->{"Customer::AuthModule::LDAP::Param$suffix"}->{'port'}
    ) { 
      $port = $ConfigObject->{"Customer::AuthModule::LDAP::Param$suffix"}->{'port'};
    }

    my $resultado = testar_conexao_ldap($host, $port);
    
    if ($resultado == 1) {
        print "Host$i: $host($base_dn): ${green}OK${color_reset}\n";
    } else {
        print "Host$i: $host($base_dn): ${red}erro na conexão${color_reset}: $resultado\n";
    }    
}
