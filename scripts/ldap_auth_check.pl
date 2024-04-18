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

# Obtém os argumentos da linha de comando
my ($user, $password) = @ARGV;

# Verifica se os argumentos necessários foram fornecidos
#if (@ARGV < 2) {
#    die "Uso: $0 <username> <password>\n";
#}

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

# Solicita o nome de usuário
print "Digite o nome de usuário: ";
my $user = <STDIN>;
chomp $user;

# Solicita a senha
print "Digite a senha: ";
system "stty -echo"; # Desativa a exibição da senha no terminal
my $password = <STDIN>;
chomp $password;
system "stty echo"; # Ativa a exibição da senha no terminal
print "\n"; # Pula para uma nova linha após a senha

# Realiza o teste de autenticação LDAP
my $AuthResult = $AuthObject->Auth(
    User => $user,
    Pw   => $password
);

use Data::Dumper;
print Dumper($AuthResult);

# Verifica o resultado da autenticação
if ($AuthResult) {
    print "Usuário autenticado com sucesso!\n";
} else {
    print "Falha na autenticação do usuário.\n";
}


