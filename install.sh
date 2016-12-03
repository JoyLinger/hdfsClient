#!/bin/bash
#-----------------------------------------#
#              Functions                  #
#-----------------------------------------#
#判断jdk是否已经安装
function installed_jdk {
java_v=`java -version 2>>/tmp/hadoop-java.log`
if [ $? -eq 0 ];then
    echo "Found Java has installed..."
    jdk_version_check
else
   echo "There is no JDK environment,please install JDK1.7.*!!"
   exit 
fi
if [ -f /tmp/hadoop-java.log ];then
   rm -f /tmp/hadoop-java.log
fi
}

#如果已安装，使用这个方法来判断jdk是否是1.7的版本
function jdk_version_check {
java_v3=`java -version 2>>/tmp/hadoop-java.log`
info2=`cat /tmp/hadoop-java.log |grep 1.7.*`
if [ $? -eq 0 ];then
    echo "Client has installed 1.7.*, no need to install..."
else
    echo "The Java's version is not 1.7.*, please contact the administrator to check the environment firstly..."
    exit 7
    fi
if [ -f /tmp/hadoop-java.log ];then
  rm -f /tmp/hadoop-java.log
fi
}

#make the $1 to lower
function upper_to_lower {                             #make the $WHITCHTDH to lower
    WHITCHTDH=`echo $1 | tr '[A-Z]' '[a-z]'`
}

#when parameter is zero,print message
function print_message {
echo "Usage: ./install [babylon|olympus|test]"
echo "Parameter'meaning:"
echo "Babylon   :The computing cluster"
echo "Olympus   :The non-computing cluster"
echo "Test      :The test cluster"
echo "Please use root to confingure the client."
}
#configure the clients's conf
function clients_install {
cp ${DIR}/base/conf/$WHITCHTDH-conf/hdfs-site.xml  ${DIR}/base/conf/hadoop/conf/
cp ${DIR}/base/conf/$WHITCHTDH-conf/core-site.xml  ${DIR}/base/conf/hadoop/conf/
cp ${DIR}/base/conf/$WHITCHTDH-conf/mapred-site.xml  ${DIR}/base/conf/hadoop/conf/
cp ${DIR}/base/conf/$WHITCHTDH-conf/yarn-site.xml  ${DIR}/base/conf/hadoop/conf/
cat ${DIR}/base/conf/$WHITCHTDH-conf/hosts >>/etc/hosts
cp ${DIR}/base/conf/$WHITCHTDH-conf/krb5.conf /etc/
}

#Check the user whether exist
function check_user {
flage=false
j=0
for i in `cat /etc/passwd | awk -F ':' '{print $1}'`;do
   if [ "${i}" == "${User}" ];then
      flage=true
   else
      continue
   fi
done
if $flage ;then
   echo "The User ${User} is exists!"
else
   echo "The User ${User} is not exists!"
   exit
fi
}

#Test Servers's Alias
function make_alias {
  case $WHITCHTDH in
     babylon)
     cat ${DIR}/testServers/prefix >> ${DIR}/testServers.sh
     echo "shopt expand_aliases >>/dev/null 2>&1" >> ${DIR}/testServers.sh
     echo "alias bhadoop=${DIR}/base/bin/hadoop" >> ${DIR}/testServers.sh
     echo "alias bhdfs=${DIR}/base/bin/hdfs" >> ${DIR}/testServers.sh
     echo "alias bhbase=${DIR}/base/bin/hbase" >> ${DIR}/testServers.sh
     echo "alias byarn=${DIR}/base/bin/yarn" >> ${DIR}/testServers.sh
     cat ${DIR}/testServers/test-babylon >> ${DIR}/testServers.sh
     ;;
     olympus)
     cat ${DIR}/testServers/prefix >> ${DIR}/testServers.sh
     echo "shopt expand_aliases >>/dev/null 2>&1" >> ${DIR}/testServers.sh
     echo "alias ohadoop=${DIR}/base/bin/hadoop" >> ${DIR}/testServers.sh
     echo "alias ohdfs=${DIR}/base/bin/hdfs" >> ${DIR}/testServers.sh
     echo "alias ohbase=${DIR}/base/bin/base" >> ${DIR}/testServers.sh
     echo "alias oyarn=${DIR}/base/bin/yarn" >> ${DIR}/testServers.sh
     cat ${DIR}/testServers/test-olympus >> ${DIR}/testServers.sh
     ;;
     test)
     cat ${DIR}/testServers/prefix >> ${DIR}/testServers.sh
     echo "shopt expand_aliases >>/dev/null 2>&1" >> ${DIR}/testServers.sh
     echo "alias thadoop=${DIR}/base/bin/hadoop" >> ${DIR}/testServers.sh
     echo "alias thdfs=${DIR}/base/bin/hdfs" >> ${DIR}/testServers.sh
     echo "alias thbase=${DIR}/base/bin/base" >> ${DIR}/testServers.sh
     echo "alias tyarn=${DIR}/base/bin/yarn" >> ${DIR}/testServers.sh
     cat ${DIR}/testServers/test-test >> ${DIR}/testServers.sh
     ;;
     esac
}

#------------------------------------------#
#              Variate                     #
#------------------------------------------#
DIR=`dirname $0`
DIR=`cd $DIR;pwd`
WHITCHTDH=$1                     # The type of TDH cluster, and cast to lower.
upper_to_lower $WHITCHTDH
#安装脚本的配置文件
source ${DIR}/install.conf
#以下的变量意义在install.conf能够找到
User=$Username
check_user >> /dev/null 2>&1
#the user's GID
GID=`cat /etc/passwd |grep -w ${User} | awk -F ':' '{print $4}'` >> /dev/null 2>&1
if [ $? -ne 0 ];then
   echo "The User [$User] not in anyone Group!"
   exit
fi
if [ -z ${GID} ];then
   echo "The Group [$Group] is null,please check /etc/passwd again!"
   exit
fi
#the user's GROUP
Group=`cat /etc/group |grep -w ${GID}| awk -F ':' '{print $1}'` >> /dev/null 2>&1
if [ $? -ne 0 ];then
   echo "The User [$User] not in anyone Group!"
   exit
fi
if [ -z ${Group} ];then
   echo "The Group [$Group] is null,please check /etc/passwd again!"
   exit
fi
krb5User=$kerberosname
keytabdir=$keytabPath

#------------------------------------------#
#                 Run                      #
#------------------------------------------#
#when parameter is zero,print message
if [ $# -eq 0 ];then
  print_message
  exit
fi
#check the user whether exist
check_user 
Homedir=`cat /etc/passwd |grep -w "${User}" | awk -F ':' '{print $6}'` >>/dev/null 2>&1
#the parameters
case $WHITCHTDH in
  #usage flags
  --help|-help|-h)
  print_message
  exit
  ;;
  #pramaters
  babylon|olympus|test)
  installed_jdk

  clients_install
  sh ${DIR}/hadoopconfigupdater/update.sh $WHITCHTDH
  ;;
  #others parameter
  *)
  print_message
  exit
  ;;
esac


if [ $? -eq 0 ];then
  echo "The client is configured!"
else
  echo "The client is not configured!"
fi

#------------------------------------------#
#             Install kerberos's rpm       #
#------------------------------------------#
#rpminfo=`rpm -qa |grep krb5-client-1.6.3-133.49.54.1.x86_64.rpm`
rpminfo=`klist`
if [ $? -eq 0 ];then
  echo "The Kerberos has installed!!!"
else
  cd ${DIR}/kerberos
  rpm -ivh krb5-client-1.6.3-133.49.54.1.x86_64.rpm
fi
if [ $? -eq 0 ];then
    echo "The Kerberos installed successfully..."
else
    echo "The Kerberos failed to install, please check the environment and the package dependencies..."
fi

echo "sh ${DIR}/hadoopconfigupdater/update.sh ${WHITCHTDH}" >>/etc/rc.d/after.local


Homedir=`cat /etc/passwd |grep -w "${User}" | awk -F ':' '{print $6}'` >>/dev/null 2>&1

if [ $? -eq 0 ];then
  chown -R "${User}":"${Group}" ${DIR}/
else
  echo "The User "${User}" or Group "${Group}" is not exist!"
  exit
fi
#Test Servers's shell 
if [ -f ${DIR}/testServers.sh ];then
   rm -f ${DIR}/testServers.sh
fi
make_alias
#Servers's alias
case ${WHITCHTDH} in
  babylon)
if [ -d ${Homedir} ];then
  echo "alias bhadoop=${DIR}/base/bin/hadoop" >> ${Homedir}/.bashrc
  echo "alias bhdfs=${DIR}/base/bin/hdfs" >> ${Homedir}/.bashrc
  echo "alias bhbase=${DIR}/base/bin/hbase" >> ${Homedir}/.bashrc
  echo "alias byarn=${DIR}/base/bin/yarn" >> ${Homedir}/.bashrc
else
  echo "The [${User}] or the User's home directory [${Homedir}] is not exist,please check it first!"
  exit
fi
  if [ -f ${keytabdir} ];then
    echo "kinit -kt ${keytabdir} ${krb5User}" >> ${Homedir}/.bashrc
  else
    echo "The Keytab [ ${keytabdir} ] is not exist,please check it again."
  fi
  ;;
  olympus)
if [ -d ${Homedir} ];then
  echo "alias ohadoop=${DIR}/base/bin/hadoop" >> ${Homedir}/.bashrc
  echo "alias ohdfs=${DIR}/base/bin/hdfs" >> ${Homedir}/.bashrc
  echo "alias ohbase=${DIR}/base/bin/hbase" >> ${Homedir}/.bashrc
  echo "alias oyarn=${DIR}/base/bin/yarn" >> ${Homedir}/.bashrc
else
  echo "The [$User] or the User's home directory [$Homedir] is not exist,please check it first!"
  exit
fi
  if [ -f ${keytabdir} ];then
    echo "kinit -kt ${keytabdir} ${krb5User}" >> ${Homedir}/.bashrc
  else
    echo "The Keytab [ ${keytabdir} ] is not exist,please check it again."
  fi
  ;;
  test)
if [ -d ${Homedir} ];then
  echo "alias thadoop=${DIR}/base/bin/hadoop" >> ${Homedir}/.bashrc
  echo "alias thdfs=${DIR}/base/bin/hdfs" >> ${Homedir}/.bashrc
  echo "alias thbase=${DIR}/base/bin/hbase" >> ${Homedir}/.bashrc
  echo "alias tyarn=${DIR}/base/bin/yarn" >> ${Homedir}/.bashrc
else
  echo "The [$User] or the User's home directory [$Homedir] is not exist,please check it first!"
  exit
fi
  if [ -f ${keytabdir} ];then
    echo "kinit -kt ${keytabdir} ${krb5User}" >> ${Homedir}/.bashrc
  else
    echo "The Keytab [ ${keytabdir} ] is not exist,please check it again."
  fi 
  ;;
esac

if [ $? -eq 0 ];then
  echo "The Hadoop-Client has installed!"
else
  echo "There is something wrong happend,the Hadoop-Client install Failed!"
fi
