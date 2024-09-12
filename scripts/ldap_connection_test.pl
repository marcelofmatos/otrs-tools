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

# Definindo códigos de escape ANSI para cores
my $green = "\e[32m";
my $red = "\e[31m";
my $color_reset = "\e[0m";

# Função para testar a conexão LDAP
sub testar_conexao_ldap {
    my ($host, $port) = @_;
    my $ldap = Net::LDAP->new($host, port => $port, timeout => 10);
    return $ldap ? 1 : $@;
}

# Função para testar múltiplas configurações de hosts LDAP, incluindo CustomerUser
sub testar_hosts_ldap {
    my ($config_prefix, $max, $key_host, $key_port, $is_customer_user) = @_;

    for my $i (0..$max) {
        my $suffix = $i == 0 ? '' : $i;
        my $config_entry = $ConfigObject->{"$config_prefix$suffix"};

        next unless $config_entry;

        # Para CustomerUser, o host está em "Params.Host" e a porta em "Params.Params.port"
        my $host;
        my $port = 389;
        
        if ($is_customer_user) {
            next unless $config_entry->{"Module"} eq "Kernel::System::CustomerUser::LDAP";
            $host = $config_entry->{"Params"}->{"Host"};
            if ($config_entry->{"Params"} && $config_entry->{"Params"}->{"Params"} && $config_entry->{"Params"}->{"Params"}->{"port"}) {
                $port = $config_entry->{"Params"}->{"Params"}->{"port"};
            }
        } else {
            # Para outros módulos, acessa diretamente o Host e a Porta
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

# Testando configurações de AuthModule
print "AuthModule:\n";
testar_hosts_ldap("AuthModule::LDAP::Host", 9, 'Host', 'Param.port', 0);

# Testando configurações de AuthSyncModule
print "AuthSyncModule:\n";
testar_hosts_ldap("AuthSyncModule::LDAP::Host", 9, 'Host', 'Param.port', 0);

# Testando configurações de CustomerUser
print "CustomerUser:\n";
testar_hosts_ldap("CustomerUser", 9, 'Params.Host', 'Params.Params.port', 1);

# Testando configurações de Customer::AuthModule
print "Customer::AuthModule:\n";
testar_hosts_ldap("Customer::AuthModule::LDAP::Host", 9, 'Host', 'Param.port', 0);
