#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'redefine';

$| = 1;  # Desabilita o buffer de saída para STDOUT

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

my $green = "\e[32m";
my $red = "\e[31m";
my $color_reset = "\e[0m";

sub testar_conexao_ldap {
    my ($host, $port) = @_;
    my $ldap = Net::LDAP->new($host, port => $port, timeout => 3);
    return $ldap ? 1 : $@;
}

sub testar_hosts_ldap {
    my ($config_prefix, $max, $key_host, $key_port, $is_customer_user) = @_;

    for my $i (0..$max) {
        my $suffix = $i == 0 ? '' : $i;
        my $config_entry = $ConfigObject->{"$config_prefix$suffix"};

        next unless $config_entry;

        my $host;
        my $port = 389;
        
        if ($is_customer_user) {
            next unless $config_entry->{"Module"} eq "Kernel::System::CustomerUser::LDAP";
            $host = $config_entry->{"Params"}->{"Host"};
            if ($config_entry->{"Params"} && $config_entry->{"Params"}->{"Params"} && $config_entry->{"Params"}->{"Params"}->{"port"}) {
                $port = $config_entry->{"Params"}->{"Params"}->{"port"};
            }
        } else {
            $host = ref $config_entry eq 'HASH' ? $config_entry->{$key_host} : $config_entry;
            if (ref $config_entry eq 'HASH' && $config_entry->{$key_port}) {
                $port = $config_entry->{$key_port};
            }
        }
        
        next unless $host;

        print "Host$suffix: $host: ";

        my $resultado = testar_conexao_ldap($host, $port);

        if ($resultado == 1) {
            print "${green}OK${color_reset}\n";
        } else {
            print "${red}erro na conexão${color_reset}: $resultado\n";
        }
    }
}

print "AuthModule:\n";
testar_hosts_ldap("AuthModule::LDAP::Host", 9, 'Host', 'Param.port', 0);

print "AuthSyncModule:\n";
testar_hosts_ldap("AuthSyncModule::LDAP::Host", 9, 'Host', 'Param.port', 0);

print "CustomerUser:\n";
testar_hosts_ldap("CustomerUser", 9, 'Params.Host', 'Params.Params.port', 1);

print "Customer::AuthModule:\n";
testar_hosts_ldap("Customer::AuthModule::LDAP::Host", 9, 'Host', 'Param.port', 0);

