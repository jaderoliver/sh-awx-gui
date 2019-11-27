#!/bin/bash
#
# Script para automatização da instalação do AWX - Core, GUI para 
# Administração e gerenciamento do Ansible.
# 
# Script Automatizado para instalação em Distribuição CentOS - Somente !!!
# 
# Criado por Jader Oliveira em 24/11/2019        Version 1.0
#
#

### BEGIN LICENSE
#
# -----------------------------------------------------------------------------------------
# "THE JO LICENSE" (Revisão 1):
# <jaderoliver@linuxmail.org> Escreveu este arquivo. Enquanto você estiver com este aviso
# você pode fazer o que quiser com o mesmo. Caso nos encontrarmos algum dia e você achar 
# que estas coisas foi útil para você, então pode pagar uma bebida para Jader Oliveira
# -----------------------------------------------------------------------------------------
#

#    This file is part of sh-awx-gui.
#
#    sh-awx-gui is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    sh-awx-gui is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with awx-gui.  If not, see <http://www.gnu.org/licenses/>.
#
### END LICENSE

#
#********************************************************************************************************************************
# Verificação da versão e distro do CentOS
#

version_dist=`cat /etc/redhat-release | awk '{print $1}'`
version_code=`cat /etc/redhat-release | awk '{print $4}'`
version_numb=`echo ${version_code:0:1}`

echo "...::: Automatização da Instalação do Ansible - AWX :::..."

if [ -z $version_dist ] && [ -z $version_code ]
    then
        echo -e "\e[31mVersão e Distro não compativel !!! Obs. Usar CentOS.\e[0m\n"
        exit 1
    else
        echo -e "Versão e Distro 100% Compativel..........\e[32m[ OK ]\e[0m\n"
fi

if [ $version_numb -lt 7 ]
    then
        echo -e "\e[31mEsta Versão esta abaixo da 7 !!! Obs. Fazer upgrade de versão.\e[0m\n"
        exit 1
    else
        echo -e "Versão 100% Compativel..........\e[32m[ OK ]\e[0m\n"
fi

#
#
#********************************************************************************************************************************
# Verifica se realmente esta logado como root ou esta modo escalonado
#
user_log=`env | grep USER= | cut -c 6-`

if [ $user_log != "root" ]
    then
        echo -e "\e[31mVocê não esta logado como ROOT !!!\n\e[0m"
        exit 1
    else
        echo -e "Voce esta logado como ROOT..........\e[32m[ OK ]\e[0m\n"
fi

#
#
#********************************************************************************************************************************
# Verifica o espaço em disco necesaario 
#
hd_space=`df / | awk 'NR==2 {print $4}'`

if [ $hd_space -lt 10485760 ]
    then
        echo -e "\e[31mVocê tem menos que o recomendado. 10GB para instalação !!! Obs. Fazer upgrade de HD.\e[0m\n"
        exit 1
    else
        echo -e "Espaço em disco verificado..........\e[32m[ OK ]\e[0m\n"
fi

#
#
#********************************************************************************************************************************
#Verfica se o pacote policy manager esta instalado
#
packg=`rpm -qa | grep policycoreutils-python`

if [ ! -z $packg ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
        echo -e "Aguarde Liberando portas necessarias SELinux.....\n"

        #Liberadno as portas do SELinux
        allow_ports=`semanage port -a -t http_port_t -p tcp 8050 2>&1 && semanage port -a -t http_port_t -p tcp 8051 2>&1 && setsebool -P httpd_can_network_connect 1 2>&1`

        #Validando liberação das Portas
        if [ $? == 0 ]
            then
                echo -e "Portas Liberadas com Sucesso no SELinux..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao liberar as Portas !!!\n\e[0m"
                exit 1
        fi

    else
        echo -e "Aguarde, Instalando o pacote ---> policycoreutils-python.....\n"
    
        #Instalando o Pacote necessario
        install_pkg=`yum -y install policycoreutils-python 2>&1`

        #Validando instalação do Pacote
        if [ $? == 0 ]
            then 
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
                                
                #Liberadno as portas do SELinux
                echo -e "Aguarde Liberando portas necessarias SElinux.....\n"
                allow_ports=`semanage port -a -t http_port_t -p tcp 8050 2>&1 && semanage port -a -t http_port_t -p tcp 8051 2>&1 && setsebool -P httpd_can_network_connect 1 2>&1`
                echo -e "Portas Liberadas com Sucesso SELinux..........\e[32m[ OK ]\e[0m\n"

            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Desabilitar o Firewalld
#

#Verificação do firewalld
fw_stat=`systemctl list-units | grep firewalld | awk '{print $4}'`

if [ "$fw_stat" != "running" ] || [ -z $fw_stat ]
    then 
        echo -e "Firewalld já esta DESATIVADO..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Desativando e Desabilitando o Firewalld.....\n"
        fws=$(systemctl stop firewalld 2>&1)
        fwe=$(systemctl disable firewalld 2>&1)
        echo -e "Firewalld DESATIVADO e DESABILITADO..........\e[32m[ OK ]\e[0m\n"       
fi

#
#
#********************************************************************************************************************************
#Instalando o repo EPEL
#
pkg_epel=`rpm -qa | grep epel`

if [ ! -z $pkg_epel ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Repo ---> EPEL.....\n"

        #Instalando o Pacote necessario
        inst_epel=`yum -y install epel-release 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi    

#
#
#********************************************************************************************************************************
#Instalando Software Colletions
#
pkgs_os=`rpm -qa | grep centos-release-scl | grep centos-release-scl-rh`

if [ ! -z $pkgs_os ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Repo ---> OS Release.....\n"

        #Instalando o Pacote necessario
        isnt_os=`yum -y install centos-release-scl centos-release-scl-rh 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi


#
#
#********************************************************************************************************************************
#Instalando WGET e Adicionado o Repo do AWX
#
pkg_wget=`rpm -qa | grep wget`

if [ ! -z $pkg_wget ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
        echo -e "Adicionando o Repo ---> AWX.....\n"
        awxg=$(wget -O /etc/yum.repos.d/ansible-awx.repo https://copr.fedorainfracloud.org/coprs/mrmeee/ansible-awx/repo/epel-7/mrmeee-ansible-awx-epel-7.repo 2>&1)
        echo -e "Repositorio adicionado com Sucesso..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Pacote ---> WGET.....\n"

        #Instalando o Pacote necessario
        inst_wget=`yum -y install wget 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
                echo -e "Adicionando o Repo ---> AWX.....\n"
                awx_g=$(wget -O /etc/yum.repos.d/ansible-awx.repo https://copr.fedorainfracloud.org/coprs/mrmeee/ansible-awx/repo/epel-7/mrmeee-ansible-awx-epel-7.repo 2>&1)
                echo -e "Repositorio adicionado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Adicionando o Repo do RabbitMQ e Erlang
#
echo -e "Adicionando o Repo ---> RabbitMQ.....\n"
echo "[bintraybintray-rabbitmq-rpm] 
name=bintray-rabbitmq-rpm 
baseurl=https://dl.bintray.com/rabbitmq/rpm/rabbitmq-server/v3.7.x/el/7/
gpgcheck=0 
repo_gpgcheck=0 
enabled=1" > /etc/yum.repos.d/rabbitmq.repo
echo -e "Repositorio adicionado com Sucesso..........\e[32m[ OK ]\e[0m\n"

echo -e "Adicionando o Repo ---> Erlang.....\n"
echo "[bintraybintray-rabbitmq-erlang-rpm] 
name=bintray-rabbitmq-erlang-rpm 
baseurl=https://dl.bintray.com/rabbitmq-erlang/rpm/erlang/21/el/7/
gpgcheck=0 
repo_gpgcheck=0 
enabled=1" > /etc/yum.repos.d/rabbitmq-erlang.repo
echo -e "Repositorio adicionado com Sucesso..........\e[32m[ OK ]\e[0m\n"

#
#
#********************************************************************************************************************************
#Instalando RabbitMQ 
#

pkg_rabbit=`rpm -qa | grep rabbitmq-server`

if [ ! -z $pkg_rabbit ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Pacote ---> RabbitMQ.....\n"

        #Instalando o Pacote necessario
        inst_rabbit=`yum -y install rabbitmq-server 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Instalando GIT 
#

pkg_git=`rpm -qa | grep rh-git29`

if [ ! -z $pkg_git ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Pacote ---> GIT.....\n"

        #Instalando o Pacote necessario
        inst_git=`yum -y install rh-git29 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Instalando PostgreSQL 
#

pkg_pgsql=`rpm -qa | grep rh-postgresql10`

if [ ! -z $pkg_pgsql ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Pacote ---> PostgreSQL 10.....\n"

        #Instalando o Pacote necessario
        inst_pgsql=`yum -y install rh-postgresql10 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Instalando Memcached 
#

pkg_mcached=`rpm -qa | grep memcached`

if [ ! -z $pkg_mcached ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Pacote ---> Memcached.....\n"

        #Instalando o Pacote necessario
        inst_mcached=`yum -y install memcached 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Instalando NGINX 
#

pkg_nginx=`rpm -qa | grep nginx`

if [ ! -z $pkg_nginx ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Pacote ---> NGINX.....\n"

        #Instalando o Pacote necessario
        inst_nginx=`yum -y install nginx 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Instalando RH-PYTHON e Dependencias
#

pkg_python=`rpm -qa | grep rh-python36`

if [ ! -z $pkg_python ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Pacote e suas Depencencias ---> RH-PYTHON 3.6.....\n"

        #Instalando o Pacote necessario
        inst_python=`yum -y install rh-python36 2>&1`
        inst_dep_python=`yum -y install --disablerepo='*' --enablerepo='copr:copr.fedorainfracloud.org:mrmeee:ansible-awx, base' -x *-debuginfo rh-python36* 2>&1`

        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Instalando AWX-RPM 
#

pkg_awx=`rpm -qa | grep ansible-awx`

if [ ! -z $pkg_awx ]
    then
        echo -e "Pacote já Instalado..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "Aguarde, Instalando o Pacote ---> AWX - RPM...\n"

        #Instalando o Pacote necessario
        inst_awx=`yum -y install ansible-awx 2>&1`
        
        #Validando instalação do Pacote
        if [ $? == 0 ]
            then
                echo -e "Pacote instalado com Sucesso..........\e[32m[ OK ]\e[0m\n"
            else
                echo -e "\e[31mErro ao instalar o Pacote !!!\n\e[0m"
                exit 1
        fi
fi

#
#
#********************************************************************************************************************************
#Inicializando DB 
#

#Acessando o Dir TMP para execução dos comandos
echo -e "Acessando o tmp para execução de comandos.....\n"
cd /
cd tmp 

#Iniciando o BD do Postgres
echo -e "Iniciando o BD do Postgres.....\n"
start_bd=`scl enable rh-postgresql10 "postgresql-setup initdb" 2>&1`

#Validando Inicialização
if [ $? == 0 ]
    then
        echo -e "PostgreSQL BD Inicializado com Sucesso..........\e[32m[ OK ]\e[0m\n"
    else
        echo -e "\e[31mErro ao Inicializar o PostgreSQL !!!\n\e[0m"
        exit 1
fi

#
#
#********************************************************************************************************************************
#Inicializando e Habilitando o Serviço do PostgreSQL e RabbitMQ
#

#Iniciando e Habilitando o Serviço do Postgres
echo -e "Iniciando e Habilitando o Serviço do Postgres.....\n"
ps=$(systemctl start rh-postgresql10-postgresql.service 2>&1)
pe=$(systemctl enable rh-postgresql10-postgresql.service 2>&1)
echo -e "PostgreSQL Inicializado e Habilitado com Sucesso..........\e[32m[ OK ]\e[0m\n"

#Iniciando e Habilitando o Serviço do RabbitMQ
echo -e "Iniciando e Habilitando o Serviço do RabbitMQ.....\n"
rs=$(systemctl start rabbitmq-server 2>&1)
re=$(systemctl enable rabbitmq-server 2>&1)
echo -e "RabbitMQ Inicializado e Habilitado com Sucesso..........\e[32m[ OK ]\e[0m\n"

#
#
#********************************************************************************************************************************
#Criação de User e DB
#

#Criando User
echo -e "Aguarde, criando DB User.....\n"
create_user_db=`scl enable rh-postgresql10 "su postgres -c \"createuser -S awx\"" 2>&1`
echo -e "User Criado com Sucesso..........\e[32m[ OK ]\e[0m\n"

#Criando DB
echo -e "Aguarde, criando DB.....\n"
create_db=`scl enable rh-postgresql10 "su postgres -c \"createdb -O awx awx\"" 2>&1`
echo -e "DB Criado com Sucesso..........\e[32m[ OK ]\e[0m\n"

#
#
#********************************************************************************************************************************
#Importação da Database
#

#Import Database
echo -e "Aguarde, Importando DataBase.....\n"
import_db=`sudo -u awx scl enable rh-python36 rh-postgresql10 rh-git29 "GIT_PYTHON_REFRESH=quiet awx-manage migrate" 2>&1`
create_user_awx=`echo "from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'root@localhost', 'passwdawx')" | sudo -u awx scl enable rh-python36 rh-postgresql10 "GIT_PYTHON_REFRESH=quiet awx-manage shell" 2>&1`
create_instance=`sudo -u awx scl enable rh-python36 rh-postgresql10 rh-git29 "GIT_PYTHON_REFRESH=quiet awx-manage provision_instance --hostname=$(hostname)" 2>&1`
create_queue=`sudo -u awx scl enable rh-python36 rh-postgresql10 rh-git29 "GIT_PYTHON_REFRESH=quiet awx-manage register_queue --queuename=tower --hostnames=$(hostname)" 2>&1`

#
#
#********************************************************************************************************************************
#Configuração para o NGINX
#

#Setando Conf do Nginx
echo -e "Aguarde, Configurando o nginx.....\n"
ngc=$(wget -O /etc/nginx/nginx.conf https://raw.githubusercontent.com/MrMEEE/awx-build/master/nginx.conf 2>&1)
sed -i 's/8052/80/' /etc/nginx/nginx.conf 2>&1

#Inicializando e Habilitando o NGINX
ngs=$(systemctl start nginx 2>&1)
nge=$(systemctl enable nginx 2>&1) 
echo -e "Nginx configurado e habilitado com Sucesso..........\e[32m[ OK ]\e[0m\n"

#
#
#********************************************************************************************************************************
#Inicializando o AWX
#

#Iniciando e Habilitando o AWX
echo -e "Iniciando e Habilitando o Serviço do AWX.....\n"
awxs=$(systemctl start awx 2>&1)
awxe=$(systemctl enable awx 2>&1)
echo -e "AWX Inicializado e Habilitado com Sucesso..........\e[32m[ OK ]\e[0m\n"

#
#
#********************************************************************************************************************************
# Verificação Final dos Serviços 
#

#Verifica se os Serviços estão rodando 
for sc_active in nginx awx rabbitmq-server rh-postgresql10-postgresql; do
    
    active=$(systemctl status "$sc_active" | awk 'NR==3 {print $2}')

    if [ "$active" == "active" ]
        then
            echo -e "Serviço $sc_active ATIVO..........\e[32m[ OK ]\e[0m"
        else
            echo -e "\e[31mServiço $sc_active DESATIVADO !!!\n\e[0m"            
    fi
done

#Verifica se os Serviços estão habilitados
for sc_loaded in nginx awx rabbitmq-server rh-postgresql10-postgresql; do
    
    loaded=$(systemctl status "$sc_loaded" | awk 'NR==2 {gsub(";","");print $4}')

    if [ "$loaded" == "enabled" ]
        then
            echo -e "Serviço $sc_loaded ATIVO..........\e[32m[ OK ]\e[0m"
        else
            echo -e "\e[31mServiço $sc_loaded DESATIVADO !!!\n\e[0m" 
    fi
done

echo ""

echo -e "\e[34mCaso nenhum erro tenha ocorrido e todos os serviços estão rodando, então foi instalado com sucesso toda a stack do Ansible e AWX\n"
echo -e "\e[93mPara acessar digite o IP do seu Host no Browser http://w.x.y.z\n"
echo -e "\e[90mUser: admin ---- Senha: passwdawx\n\e[0m"


