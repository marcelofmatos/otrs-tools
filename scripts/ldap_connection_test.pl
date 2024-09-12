#!/usr/bin/env perl
# --
# Copyright (C) 2024-2024 Marcelo Matos https://github.com/marcelofmatos/otrs-tools
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

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

# Função para testar múltiplas configurações de hosts LDAP
sub testar_hosts_ldap {
    my ($config_prefix, $max, $key_host, $key_port) = @_;

    for my $i (0..$max) {
        my $suffix = $i == 0 ? '' : $i;
        my $host = $ConfigObject->{"$config_prefix$suffix"}->{$key_host};

        next unless $host;

        my $port = 389;
        if ($ConfigObject->{"$config_prefix$suffix"}->{$key_port}) {
            $port = $ConfigObject->{"$config_prefix$suffix"}->{$key_port};
        }

        print "Host$i: $host: ";
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
testar_hosts_ldap("AuthModule::LDAP::Host", 9, 'Host', 'Param.port');

# Testando configurações de AuthSyncModule
print "AuthSyncModule:\n";
testar_hosts_ldap("AuthSyncModule::LDAP::Host", 9, 'Host', 'Param.port');

# Testando configurações de CustomerUser
print "CustomerUser:\n";
testar_hosts_ldap("CustomerUser", 9, 'Params.Host', 'Params.Params.port');

# Testando configurações de Customer::AuthModule
print "Customer::AuthModule:\n";
testar_hosts_ldap("Customer::AuthModule::LDAP::Host", 9, 'Host', 'Param.port');
