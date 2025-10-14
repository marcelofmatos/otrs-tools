#!/usr/bin/env perl
# --
# Copyright (C) 2024-2024 Marcelo Matos https://github.com/marcelofmatos/otrs-tools
# --
# Script para verificar grupos LDAP configurados no OTRS/Znuny
# 
# Timeout configurável:
# - Via parâmetro: --timeout 15
# - Via variável de ambiente: LDAP_TIMEOUT=15
# - Padrão: 3 segundos
# 
# Exemplos: 
#   ./ldap_groups_check.pl --timeout 30 --existing
#   LDAP_TIMEOUT=5 ./ldap_groups_check.pl --non-existing
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

my $debug = 0;
my $timeout_opt;
my $filter = '(objectClass=*)';
my ($show_existing, $show_non_existing);
my (@existing_groups, @non_existing_groups);

# Processando as opções de linha de comando
GetOptions(
    "existing"      => \$show_existing,   # Mostrar somente grupos existentes
    "non-existing"  => \$show_non_existing, # Mostrar somente grupos não existentes
    'debug' => \$debug,
    'timeout=i' => \$timeout_opt,  # Timeout em segundos
);

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
my $HTTPBasicAuthObject = $Kernel::OM->Get('Kernel::System::Auth');

sub check_group_existence {
    my ($ldap, $group_dn) = @_;

    my $result = $ldap->search(
        base   => $group_dn,
        filter => $filter,
    );

    if($debug) {
        print Dumper($result);
    }

    return $result->count == 1 ? 1 : 0;
}

# Definindo códigos de escape ANSI para cores
my $verde = "\e[32m";   # verde
my $vermelho = "\e[31m"; # vermelho
my $reset_cor = "\e[0m"; # resetar cor

my $groups_to_check = 

print "AuthSyncModule:\n";
AuthSyncModuleHOST:
for my $i (0..9) {
    # Acessando o valor correspondente no $ConfigObject
    my $suffix = $i == 0 ? '' : $i;
    my $host = $ConfigObject->{"AuthSyncModule::LDAP::Host$suffix"};
    my $UserSyncRolesDefinition = $ConfigObject->{"AuthSyncModule::LDAP::UserSyncRolesDefinition$suffix"};

    next AuthSyncModuleHOST if (!$host);
    next AuthSyncModuleHOST if (!$UserSyncRolesDefinition);

    my $port = 389;

    if(
         $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"} 
         && $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"}->{'port'}
    ) { 
      $port = $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"}->{'port'};
    }

    my $ldap_port       = $port;
    my $base_dn         = $ConfigObject->{"AuthSyncModule::LDAP::BaseDN$suffix"};
    my $bind_dn         = $ConfigObject->{"AuthSyncModule::LDAP::SearchUserDN$suffix"};
    my $bind_password   = $ConfigObject->{"AuthSyncModule::LDAP::SearchUserPw$suffix"};

    # Configurar timeout (prioridade: --timeout, LDAP_TIMEOUT, padrão 3s)
    my $timeout = $timeout_opt || $ENV{LDAP_TIMEOUT} || 3;
    
    my $ldap = Net::LDAP->new(
        $host, 
        port => $port, 
        timeout => $timeout, 
        verify => 'never'
    );
    if (!$ldap) {
        die "Failed to connect to LDAP server after ${timeout}s: Connection timeout or refused";
    }
    
    my $mesg = $ldap->bind(dn => $bind_dn, password => $bind_password);
    if ($mesg->code) {
        die "Failed to bind to LDAP server: " . $mesg->error;
    }

    foreach my $group_dn (keys %$UserSyncRolesDefinition) {

        if (check_group_existence($ldap, $group_dn)) {
            push @existing_groups, $group_dn;
        } else {
            push @non_existing_groups, $group_dn;
        }
    }
    $ldap->disconnect;
}


if ($show_existing) {
    print "${verde}Grupos que foram localizados no LDAP:${reset_cor}\n";
    print "${verde}$_${reset_cor}\n" for @existing_groups;
} elsif ($show_non_existing) {
    print "${vermelho}Grupos que NÃO foram localizados no LDAP:${reset_cor}\n";
    print "${vermelho}$_${reset_cor}\n" for @non_existing_groups;
} else {
    print "${verde}Grupos que foram localizados no LDAP:${reset_cor}\n";
    print "${verde}$_${reset_cor}\n" for @existing_groups;
    print "\n${vermelho}Grupos que NÃO foram localizados no LDAP:${reset_cor}\n";
    print "${vermelho}$_${reset_cor}\n" for @non_existing_groups;
}

