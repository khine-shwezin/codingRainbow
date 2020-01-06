#!/usr/bin/env bash
folderPath=$(pwd)
scriptPath=$(pwd)
userName="QAUSER"
password="7HoXxS3d3JUiZJ8ddaunbttY"
hostName="10.151.116.152"
port="1521"
SID="CWDB01"

if [ $# -eq 0 ]
then
   repoName="5.1"
else
   repoName=${1}
fi

input="./OracleSetup/DatabaseInput.json"
while IFS= read -r line
do
  id=$(echo $line |  cut -d":" -f1 | sed 's/"//g')
  v=$(echo $line | cut -d":" -f2 | sed 's/"//g'| sed 's/,//g')

  if [ ${#id} -gt 0 ]
  then
    if [[ "$id" == "userName" ]]
    then
      userName=$v
    fi
    if [[ "$id" == "password" ]]
    then
      password=$v
    fi
    if [[ "$id" == "hostName" ]]
    then
      hostName=$v
    fi
    if [[ "$id" == "port" ]]
    then
      port=$v
    fi
    if [[ "$id" == "SID" ]]
    then
      SID=$v
    fi
    if [[ "$id" == "oracle_base_url" ]]
    then
      oracle_base_url=$v
    fi
    if [[ "$id" == "oracle_sqlplus_url" ]]
    then
      oracle_sqlplus_url=$v
    fi
  fi

done<$input

echo "username:[$userName], pw:[$password], host:[$hostName], SID:[$SID], port:[$port]"
dbServer=$hostName

echo "Enabling $repoName repo at Oracle server $dbServer....."

cd /opt/gls/clarity/bin
./run_clarity.sh stop

cd $folderPath

echo "Start downloading Oracle basic and sqlplus packages. If you run on Centos 6 or 7, it needs GLIBC 2.14 and so, you need to manually run sql scripts in the Oracle Database."
wget $oracle_base_url -O OracleSetup/oracle-19.3-basic.rpm
wget $oracle_sqlplus_url -O OracleSetup/oracle-19.3-sqlplus.rpm
echo "Oacle packages download finished!"

pwd
rm -rf /tmp/OracleSetup
cp -rf OracleSetup /tmp/
cd /tmp/OracleSetup

. OracleDatabaseReset.sh
echo "Oracle database has been successfully reset."

cd /etc/init.d
./nextseq_seqservice-v1 stop
./nextseq_seqservice-v2 stop

unalias rm
unalias mv

echo "Removing PreReq..."
yum list | grep PreReq
echo y| yum remove "*PreReqs*"

echo "Removing Elastic.."
echo y | yum remove "elasticsearch"

echo y | yum remove "rabbitmq-server"

rm -rf /opt/gls/clarity
rm -rf /opt/gls/jdk8
rm -rf /opt/gls/jdk6
rm -rf /var/log/elasticsearch/*
rm -rf /opt/elasticsearch

echo "Deleting and Creating users and groups"
userdel -rf glsai
userdel -rf glsftp
userdel -rf glsjboss
userdel -rf glstomcat
groupdel claritylims
groupdel glsjdk6
groupdel glsjdk7
groupdel glsjdk8

enable_repo.sh -o -r $repoName
echo y | yum install ClarityLIMS-App
pwd
echo "Clarity LIMS App has been installed!"

cd /opt/gls/clarity/config
echo "Initial cleanup and setup completed. Pending scripts will be installed to Oracle server at $dbServer................."

myhost=$(hostname)
echo "This server is $myhost connecting to $dbServer"

rm 20_input.txt
touch 20_input.txt
echo "1" >> 20_input.txt
echo $dbServer >> 20_input.txt
echo $port >> 20_input.txt
echo $SID >> 20_input.txt
echo QA7CLARITY501LOOKUPUSER >> 20_input.txt
echo "QA7CLARITY501" >> 20_input.txt
echo "QA7CLARITY501" >> 20_input.txt

su glsjboss "./pending/20_configure_claritylims_platform.sh" <20_input.txt
echo "20_configure_claritylims_platform has been executed."

touch 26_input.txt
echo "y" >> 26_input.txt #Are you an In Vitro Diagnostics lab (US only)? [y/n].
echo $myhost >> 26_input.txt #fully qualified domain name that identifies this server
echo $SID >> 26_input.txt #Enter required value for database SID
echo "QA7CLARITY501" >> 26_input.txt #Enter required value for database username
echo "QA7CLARITY501" >> 26_input.txt #Enter password value for database password
echo "QA7CLARITY501" >> 26_input.txt #Confirm password value for database password
echo "y" >> 26_input.txt #Continue with database initialization [n]
echo "kszin@illumina.com" >> 26_input.txt #Clarity LIMS Administrative Email address
echo "admin" >> 26_input.txt #Admin Username
echo "apassword" >> 26_input.txt #admin's password
echo "facility" >> 26_input.txt #Facility Users Username
echo "fpassword" >> 26_input.txt #facility's password
echo "apiuser" >> 26_input.txt #API Access Username
echo "apipassword" >> 26_input.txt #apiuser's password
echo $myhost >> 26_input.txt #Enter required value for File Server - server
echo "/opt/gls/clarity/users/glsftp" >> 26_input.txt #Enter required value for File Server - directory
echo "glsftp" >> 26_input.txt #value for File Server - username
echo "glsftp" >> 26_input.txt #Enter password value for File Server - password
echo "glsftp" >> 26_input.txt #Confirm password value for File Server
echo "y" >> 26_input.txt #Any existing data will be LOST.  Do you wish to proceed?
echo "n" >> 26_input.txt #If you do not wish this data to be collected, select N. [Y]

su glsjboss "./pending/26_initialize_claritylims_tenant.sh" < 26_input.txt
echo "26_initialize_claritylim_tenant has been executed."

touch ftp_input.txt
echo "glsftp" >> ftp_input.txt
echo "glsftp" >> ftp_input.txt
passwd glsftp < ftp_input.txt
echo "Password for glsftp has been changed."
rm -f ftp_input.txt

touch rabbit_input.txt
echo $myhost >> rabbit_input.txt
./pending/32_root_configure_rabbitmq.sh < rabbit_input.txt
echo "32_configure_rabbitmq has been executed."
rm -f rabbit_input.txt

./pending/40_root_install_proxy.sh
echo "40_install_proxy has been executed."

cd /usr/gls/bin
./installQACerts.sh
echo "QA certs installed"

clarityConfig="/etc/httpd/conf.d/clarity.conf"
sed -i 's|CERTPATH/NOT_CONFIGURED_CERT|/etc/httpd/sslcertificate/star_cavc_illumina.com.crt|g' $clarityConfig
sed -i 's|CERTPATH/NOT_CONFIGURED_PRIVATE_KEPT| /etc/httpd/sslcertificate/star_cavc_illumina_com.key|g' $clarityConfig
sed -i 's|# SSLCertificateChainFile CERTPATH/NOT_CONFIGURED_CHAIN|SSLCertificateChainFile /etc/httpd/sslcertificate/chain.crt|g' $clarityConfig
echo "SSL paths have been updated in $clarityConfig"

errorCode=0
startClarity(){
/opt/gls/clarity/bin/run_clarity.sh start
}
handleError(){
errorCode=1
}
installPackages(){
cd /usr/gls/bin
./installQACerts.sh
enable_repo.sh -o -r qa
printf "y" | yum install "*pre-conf*"
cd /opt/gls/clarity/config
ls -la
su glsjboss -c "./pre-configured-workflows-installer.sh -o install QC_Protocols.base"
yum install ClarityLIMS-NGS-Package*
echo "NGS and QC protocols have been installed."
}
startClarity || handleError

echo "errorCode:$errorCode"
if [ $errorCode -eq 0 ]
then
  echo "Clarity is Up! Check at $(hostname). NGS and QC Protocols will be installed."
  installPackages
else
  echo "Error to start Clarity"
fi
