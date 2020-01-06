1) Copy the entire folder into /tmp/
2) Run the below line
   $. OracleDatabaseReset.sh

What the script does:
1) install Oracle basic and sqlplus package in the server, in order to connect the Oracle database 
2) Update bash_profile and add path to the system
2) run two sql scripts - terminate the connected users, and recreate the schemas [[QA7CLARITY501REPORTUSER,QA7CLARITY501LOOKUPUSER,QA7CLARITY501]

Following files are required.

To setup the Oracle:
json_v1_0_5  
oracle-19.3-basic.rpm  
oracle-19.3-sqlplus.rpm

Input parameters for Oracle setting:
input.json 


/**********/

Khine Shwe Zin
kszin@illumina.com
29 Oct 2019

/**********/
