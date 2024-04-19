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

# Função para testar a conexão LDAP
sub testar_conexao_ldap {
    my ($host,$port) = @_;
    
    # Tentativa de conexão LDAP
    my $ldap = Net::LDAP->new($host, port => $port);
    if ($ldap) {
        $ldap->disconnect;
        return 1; # Conexão bem-sucedida
    } else {
        return $@; # Retorna o erro
    }
}

# Definindo códigos de escape ANSI para cores
my $verde = "\e[32m";   # verde
my $vermelho = "\e[31m"; # vermelho
my $reset_cor = "\e[0m"; # resetar cor

# mostra configuracao LDAP atual no ambiente

print "AuthModule:\n";
AuthModuleHOST:
for my $i (0..9) {
    my $suffix = $i == 0 ? '' : $i;
    # Acessando o valor correspondente no $ConfigObject
    my $host = $ConfigObject->{"AuthModule::LDAP::Host$suffix"};

    next AuthModuleHOST if (!$host);

    my $port = 389;

    if(
         $ConfigObject->{"AuthModule::LDAP::Param$suffix"} 
         && $ConfigObject->{"AuthModule::LDAP::Param$suffix"}->{'port'}
    ) { 
      $port = $ConfigObject->{"AuthModule::LDAP::Param$suffix"}->{'port'};
    }

    # Testando a conexão LDAP para o host atual
    my $resultado = testar_conexao_ldap($host,$port);
    
    # Imprimindo a saída no formato destacado
    if ($resultado == 1) {
        print "Host$i: $host: ${verde}OK${reset_cor}\n";
    } else {
        print "Host$i: $host: ${vermelho}erro na conexão${reset_cor}: $resultado\n";
    }    
}


print "AuthSyncModule:\n";
AuthSyncModuleHOST:
for my $i (0..9) {
    my $suffix = $i == 0 ? '' : $i;
    # Acessando o valor correspondente no $ConfigObject
    my $host = $ConfigObject->{"AuthSyncModule::LDAP::Host$suffix"};

    next AuthSyncModuleHOST if (!$host);

    my $port = 389;

    if(
         $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"} 
         && $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"}->{'port'}
    ) { 
      $port = $ConfigObject->{"AuthSyncModule::LDAP::Param$suffix"}->{'port'};
    }

    # Testando a conexão LDAP para o host atual
    my $resultado = testar_conexao_ldap($host,$port);
    
    # Imprimindo a saída no formato destacado
    if ($resultado == 1) {
        print "Host$i: $host: ${verde}OK${reset_cor}\n";
    } else {
        print "Host$i: $host: ${vermelho}erro na conexão${reset_cor}: $resultado\n";
    }    
}


print "CustomerUser:\n";
CustomerUserHOST:
for my $i (0..9) {
    my $suffix = $i == 0 ? '' : $i;
    
    next if (!($ConfigObject->{"CustomerUser$suffix"}));

    # Acessando o valor correspondente no $ConfigObject
    my $host = $ConfigObject->{"CustomerUser$suffix"}->{"Params"}->{"Host"};

    next if (!($ConfigObject->{"CustomerUser$suffix"}->{"Module"} eq "Kernel::System::CustomerUser::LDAP"));

    next CustomerUserHOST if (!$host);

    my $port = 389;

    if(
         $ConfigObject->{"CustomerUser$suffix"}->{"Params"} # no critic
         && $ConfigObject->{"CustomerUser$suffix"}->{"Params"}->{'Params'}->{'port'} # no critic
    ) { 
      $port = $ConfigObject->{"CustomerUser$suffix"}->{"Params"}->{'Params'}->{'port'};
    }

    # Testando a conexão LDAP para o host atual
    my $resultado = testar_conexao_ldap($host,$port);
    
    # Imprimindo a saída no formato destacado
    if ($resultado == 1) {
        print "Host$i: $host: ${verde}OK${reset_cor}\n";
    } else {
        print "Host$i: $host: ${vermelho}erro na conexão${reset_cor}: $resultado\n";
    }    
}

print "Customer::AuthModule:\n";
CustomerAuthModuleHOST:
for my $i (0..9) {
    my $suffix = $i == 0 ? '' : $i;
    # Acessando o valor correspondente no $ConfigObject
    my $host = $ConfigObject->{"Customer::AuthModule::LDAP::Host$suffix"};

    next CustomerAuthModuleHOST if (!$host);

    my $port = 389;

    if(
         $ConfigObject->{"Customer::AuthModule::LDAP::Param$suffix"} 
         && $ConfigObject->{"Customer::AuthModule::LDAP::Param$suffix"}->{'port'}
    ) { 
      $port = $ConfigObject->{"Customer::AuthModule::LDAP::Param$suffix"}->{'port'};
    }

    # Testando a conexão LDAP para o host atual
    my $resultado = testar_conexao_ldap($host,$port);
    
    # Imprimindo a saída no formato destacado
    if ($resultado == 1) {
        print "Host$i: $host: ${verde}OK${reset_cor}\n";
    } else {
        print "Host$i: $host: ${vermelho}erro na conexão${reset_cor}: $resultado\n";
    }    
}

