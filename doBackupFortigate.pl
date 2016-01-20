#!/usr/bin/perl -w

#Script that connect to a fortigate appliance and do a backup. The script also do a rotate of old backup files.
#Autor: alanwds@gmail.com
#Use for free :)

use warnings;
use Net::SCP::Expect;
use strict;

#Declaracao de variaveis

our $user = 'backup';
our $pass = 'password';
our @firewallips = ('ip1','ip2'','ip3');
our $ip = '';
our $currentDate = `date +%d_%m_%Y`;
#remove a quebra de linha da data/hora
chomp($currentDate);

#Inicio das funcoes

#Funcao para log das mensagens do script
sub LOG{

        #Armazena a data e hora em uma variavel
        my $now = `date +"%b %d %R:%S"`;

        #remove a quebra de linha da data/hora
        chomp($now);

        #Recebe a string como parametro
        my ($logitem) = @_;

        #Adiciona a data/hora, espaco e a quebra de linha na linha
        $logitem = $now . " " . $logitem."\n";

        #Abre o arquivo de LOG
        open LOG, ">>/var/log/backupFortinet.log" or die $!;

        #Armazena a strings recebida no arquivo
        print LOG $logitem;

        #Fecha o arquivo
        close LOG;

        #Armazena a informacao no syslog
        my $temp = `/usr/bin/logger -i -p local7.info -t \"Backup Fortinet\" $logitem`;

        #Joga a string no stdout
        print $logitem;

}

#Funcao para executar o backup
sub doBackup{

        #Percorre o array para saber os IPs que ele deve conectar/fazer o backup
        foreach $ip (@firewallips) {
        LOG "Realizando Backup do Fortigate $ip";

        LOG "Efetuando login";
        my $scpe = Net::SCP::Expect->new(auto_yes=>1);
        $scpe->login($user, $pass);

        LOG "Iniciando a copia do arquivo";
        #Faz a copia do arquivo
        $scpe->scp("$ip:sys_config","/opt/backup/fortigate/fortigate-$currentDate\.conf");
        LOG "Copia do arquivo concluida";

        }
}

#Funcao para apagar os backups antigos (Mais que duas semanas)
sub backupRotate{

        LOG "Iniciando o rotate dos backups";

        LOG "Verificando se existem arquivos a serem deletados";

        my $comandoShell = 'find /opt/backup/fortigate/ -name "fortigate-*" -atime +14 -delete -print';

        #Executa o comando
        my($stdout, $stderr, $exit) = `$comandoShell 2>&1`;

        #Testa para verificar se houve erro na execucao do comando
        if($stderr){
                LOG "ERRO_BKP_Fortigate: Nao foi possivel executar o comando";
                LOG "ERRO_BKP_Fortigate: $stderr";
        }else{
                LOG "Consulta efetuada com sucesso";
        }

        #Testa se existe stdout. Se existe e pq os arquivos foram deletados

        if($stdout){

                LOG "Os seguintes arquivos foram encontrados e apagados";
                LOG "$stdout";

        }else{
                LOG "Nao foram encontrados backups antigos";
        }

}

#Inicia as chamdas de funcao
doBackup();
backupRotate();