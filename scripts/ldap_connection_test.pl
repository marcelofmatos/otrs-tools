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
HOST:
for my $i (1..9) {
    # Acessando o valor correspondente no $ConfigObject
    my $host = $ConfigObject->{"AuthSyncModule::LDAP::Host$i"};

    next HOST if (!$host);

    my $port = 389;

    if(
         $ConfigObject->{"AuthSyncModule::LDAP::Param$i"} 
         && $ConfigObject->{"AuthSyncModule::LDAP::Param$i"}->{'port'}
    ) { 
      $port = $ConfigObject->{"AuthSyncModule::LDAP::Param$i"}->{'port'};
    }

    # Testando a conexão LDAP para o host atual
    my $resultado = testar_conexao_ldap($host,$port);
    
    # Imprimindo a saída no formato destacado
    if ($resultado == 1) {
        print "Host$i: $host: ${verde}teste ok${reset_cor}\n";
    } else {
        print "Host$i: $host: ${vermelho}erro na conexão${reset_cor}: $resultado\n";
    }    
}

