#!/usr/bin/env perl
# Configura o LogModule do OTRS/LigeroSmart para gravar em arquivo
# (Kernel::System::Log::File) em vez de SysLog.
#
# Por padrão o LigeroSmart vem com LogModule = Kernel::System::Log::SysLog.
# Em containers sem daemon de syslog rodando, isso faz com que a tela
# "Eventos do Sistema" (AdminLog) só mostre o buffer em memória do
# processo Perl atual — nada fica persistido, e o log se perde a cada
# novo processo/restart.
#
# Uso: copiar para <otrs_root>/scripts/ e rodar dentro do container do
# webserver (funciona em qualquer instalação LigeroSmart/OTRS, não é
# específico de nenhum cliente):
#
#   docker exec -i <container_webserver> perl scripts/file-log-config.pl [caminho_do_log]
#
# Caminho padrão: <otrs_root>/var/log/otrs.log

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . "/Kernel/cpan-lib";
use lib dirname($RealBin) . "/Custom";

use Kernel::System::ObjectManager;

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'LIGERO-file-log-config',
    },
);

my $OTRSHome = dirname($RealBin);
my $LogFile  = $ARGV[0] || "$OTRSHome/var/log/otrs.log";

my $SysConfigObject = $Kernel::OM->Get('Kernel::System::SysConfig');

my %NewValue = (
    'LogModule'         => 'Kernel::System::Log::File',
    'LogModule::LogFile' => $LogFile,
);

for my $SettingName ( sort keys %NewValue ) {
    UpdateSetting( $SettingName, $NewValue{$SettingName} );
}

my %DeploymentResult = $SysConfigObject->ConfigurationDeploy(
    Comments      => 'file-log-config.pl: LogModule -> File',
    UserID        => 1,
    Force         => 1,
    DirtySettings => [ sort keys %NewValue ],
);

if ( !$DeploymentResult{Success} ) {
    die "Deploy falhou: $DeploymentResult{Error}\n";
}

print "OK. LogModule = File, arquivo: $LogFile\n";
print "O arquivo será criado na primeira entrada de log gravada.\n";

sub UpdateSetting {
    my ( $Name, $Value ) = @_;

    my %Setting = $SysConfigObject->SettingGet(
        Name    => $Name,
        Default => 1,
    );

    if ( !%Setting ) {
        die "Setting '$Name' não existe nesta instalação!\n";
    }

    my $ExclusiveLockGUID = $SysConfigObject->SettingLock(
        UserID    => 1,
        Force     => 1,
        DefaultID => $Setting{DefaultID},
    );

    my $Success = $SysConfigObject->SettingUpdate(
        Name              => $Name,
        EffectiveValue    => $Value,
        ExclusiveLockGUID => $ExclusiveLockGUID,
        UserID            => 1,
    );

    $SysConfigObject->SettingUnlock(
        UserID    => 1,
        DefaultID => $Setting{DefaultID},
    );

    if ( !$Success ) {
        die "Não foi possível atualizar '$Name'!\n";
    }

    return 1;
}
