userName="QAUSER"
password="7HoXxS3d3JUiZJ8ddaunbttY"
hostName="10.151.116.152"
port="1521"
SID="CWDB01"

input="./DatabaseInput.json"
while IFS= read -r line
do
  id=$(echo $line | sed 's/[^a-zA-Z0-9.@_-]/ /g' | sed 's/[ ]\+/ /g'| cut -d" " -f2)
  v=$(echo $line | sed 's/[^a-zA-Z0-9.@_-]/ /g' | sed 's/[ ]\+/ /g'| cut -d" " -f3)
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
  fi

done<$input

echo "[OracleSetup] username:[$userName], pw:[$password], host:[$hostName], SID:[$SID], port:[$port]"

cd /tmp/OracleSetup/
rpm -ivh oracle-19.3-basic.rpm
rpm -ivh oracle-19.3-sqlplus.rpm
#rpm -Uvh glibc-common-2.15-60.el6.x86_64.rpm

sed -i '/ORACLE_HOME=\/usr\/lib\/oracle\/19.3\/client64/d' ~/.bash_profile
sed -i '/PATH=\$ORACLE_HOME\/bin:\$PATH/d' ~/.bash_profile
sed -i '/LD_LIBRARY_PATH=\$ORACLE_HOME\/lib/d' ~/.bash_profile
sed -i '/export ORACLE_HOME/d' ~/.bash_profile
sed -i '/export LD_LIBRARY_PATH/d' ~/.bash_profile

echo  "ORACLE_HOME=/usr/lib/oracle/19.3/client64" >>  ~/.bash_profile
echo "PATH=\$ORACLE_HOME/bin:\$PATH" >>  ~/.bash_profile
echo "LD_LIBRARY_PATH=\$ORACLE_HOME/lib" >>  ~/.bash_profile
echo "export ORACLE_HOME" >>  ~/.bash_profile
echo "export LD_LIBRARY_PATH" >>  ~/.bash_profile
sed -i '/export PATH/d' ~/.bash_profile
echo "export PATH" >>  ~/.bash_profile
source ~/.bash_profile
rm -f sqllog.txt
echo "sqllog.txt is deleted."
sqlplus "$userName/$password@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$hostName)(PORT=$port))(CONNECT_DATA=(SID=$SID)))" < /tmp/OracleSetup/DeleteUsers.sql >> sqllog.txt
sleep 5s
echo "DeleteUsers.sql has run."
sqlplus "$userName/$password@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$hostName)(PORT=$port))(CONNECT_DATA=(SID=$SID)))" < /tmp/OracleSetup/OracleDatabaseSetup.sql >> sqllog.txt

echo "Oracle database $hostName! has been reset."
