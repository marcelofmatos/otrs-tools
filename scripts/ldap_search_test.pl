#!/usr/bin/env perl
# --
# Copyright (C) 2024-2024 Marcelo Matos https://github.com/marcelofmatos/otrs-tools
# --
# Script para buscar entradas LDAP configuradas no OTRS/Znuny
# 
# Timeout configurável:
# - Via parâmetro: --timeout 15
# - Via variável de ambiente: LDAP_TIMEOUT=15
# - Padrão: 3 segundos
# 
# Exemplos: 
#   ./ldap_search_test.pl                                        # Usa filtro padrão (a*, admin*, test*, user*) com limite de 1000
#   ./ldap_search_test.pl --timeout 30 --filter "(uid=usuario)" # Filtro personalizado
#   ./ldap_search_test.pl --sizelimit 5                         # Limite personalizado de 5 entradas
#   LDAP_TIMEOUT=5 ./ldap_search_test.pl --filter "(sAMAccountName=joao)"
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
my $attrs_list = 'cn,mail,uid,sAMAccountName';

# Constantes padrão para filtro e limite - funcionam tanto em AD quanto OpenLDAP
# Filtro mais restritivo que busca usuários comuns em testes (a*, admin*, test*, user*)
my $DEFAULT_FILTER = '(|(uid=a*)(uid=admin*)(uid=test*)(uid=user*)(sAMAccountName=a*)(sAMAccountName=admin*)(sAMAccountName=test*)(sAMAccountName=user*))';  
my $DEFAULT_SIZELIMIT = 1000;                         # Limite de 1000 entradas (valor original)

my $sizelimit = $DEFAULT_SIZELIMIT;
my $ldap_filter;
my $host;
my $port;

GetOptions(
    'filter=s'    => \$ldap_filter,
    'attrs=s'     => \$attrs_list,
    'debug'       => \$debug,
    'host=s'      => \$host,
    'port=i'      => \$port,
    'timeout=i'   => \$timeout_opt,  # Timeout em segundos
    'sizelimit=i' => \$sizelimit,    # Limite de entradas
);

# Se nenhum filtro foi fornecido, usar o filtro padrão
$ldap_filter = $DEFAULT_FILTER if (!defined($ldap_filter) || $ldap_filter eq '');

my $attrs = [split ',', $attrs_list];

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-ldapsearch',
    },
);

my $ConfigObject  = $Kernel::OM->Get('Kernel::Config');
my $EncodeObject  = $Kernel::OM->Get('Kernel::System::Encode');
my $LogObject     = $Kernel::OM->Get('Kernel::System::Log');
my $MainObject    = $Kernel::OM->Get('Kernel::System::Main');
my $DBObject      = $Kernel::OM->Get('Kernel::System::DB');
my $AuthObject    = $Kernel::OM->Get('Kernel::System::Auth');

sub search_by_filter {
    my ($host, $port, $base_dn, $bind_dn, $bind_password, $ldap_filter) = @_;
    
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
    
    my $filter = $ldap_filter;

    $mesg = $ldap->search(
        base      => $base_dn,
        filter    => $filter,
        scope     => "sub",
        attrs     => $attrs,
        sizelimit => $sizelimit,
    );

    if ($mesg->code) {
        die "LDAP search failed: " . $mesg->error;
    }
    
    my @entries = $mesg->entries;
    if (@entries) {
        return \@entries;
    } else {
        return;
    }
}

my $green = "\e[32m";
my $red = "\e[31m";
my $reset_color = "\e[0m";

AuthModuleHOST:
for my $i (0..9) {

    my $suffix = $i == 0 ? '' : $i;

    my $host = $ConfigObject->{"AuthModule::LDAP::Host$suffix"};

    next AuthModuleHOST if (!$host);

    my $config_port = 389;

    if (
         $ConfigObject->{"AuthModule::LDAP::Params$suffix"} 
         && $ConfigObject->{"AuthModule::LDAP::Params$suffix"}->{'port'}
    ) { 
      $config_port = $ConfigObject->{"AuthModule::LDAP::Params$suffix"}->{'port'};
    }

    $port ||= $config_port;

    my $base_dn       = $ConfigObject->{"AuthModule::LDAP::BaseDN$suffix"};
    my $bind_dn       = $ConfigObject->{"AuthModule::LDAP::SearchUserDN$suffix"};
    my $bind_password = $ConfigObject->{"AuthModule::LDAP::SearchUserPw$suffix"};

    next AuthModuleHOST if (!$bind_dn && !$bind_password);

    print "$host, $port, $base_dn, $bind_dn, $ldap_filter\n";
    my $result = search_by_filter($host, $port, $base_dn, $bind_dn, $bind_password, $ldap_filter);

    my @headers = @$attrs;
    my @values;

    if (defined $result && @$result) {
        print "${green}Entry with filter $ldap_filter found:${reset_color}\n";
        my $format_headers = "%s\t| " x scalar(@headers);
        printf("$format_headers\n", @headers);
        foreach my $entry (@$result) {
            @values = ();
            foreach my $attr (@headers) {
                foreach my $attribute (@{$entry->{asn}->{attributes}}) {
                    if($attribute->{type} eq $attr) {
                        push @values, $attribute->{vals}->[0];
                        last;
                    }
                }
            }
            my $format_string = "%s\t| " x scalar(@values);
            printf("$format_string\n", @values);
            if ($debug) {
                print Dumper($entry->{asn});
            }
        }
    } else {
        print "${red}Entry with filter $ldap_filter not found.${reset_color}\n";
    }
}
