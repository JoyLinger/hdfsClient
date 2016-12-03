#!/bin/bash
#--------------------------------#
#          Function              #
#--------------------------------#
# check
function checkXmlPid {
  if [ -f ${1} ]; then
    if kill -0 `cat ${1}` > /dev/null 2>&1; then
      echo ${4}-CLUSTER-XML-UPDATER is running as process `cat ${1}`.Stopping it.
      # stop update ${4}-CLUSTER-XML
      kill -9 `cat ${1}`
    fi
  fi
  
  if [ -f ${2} ]; then
    if kill -0 `cat ${2}` > /dev/null 2>&1; then
      echo ${5}-CLUSTER-XML-UPDATER is running as process `cat ${2}`.Stopping it.
      # stop update ${5}-CLUSTER-XML
      kill -9 `cat ${2}`
    fi
  fi
  # The param ${3} is what you input now.
  if [ -f ${3} ]; then
    if kill -0 `cat ${3}` > /dev/null 2>&1; then
      echo ${6}-CLUSTER-XML-UPDATER is already running as process `cat ${3}`.
      return 0
    fi
  fi
  # start update ${6}-CLUSTER-XML
  updateXml "${7}" "${3}"
  echo Starting ${6}-CLUSTER-XML-UPDATER as process `cat ${3}`.
}

function checkHostsPid {
  if [ -f ${1} ]; then
    if kill -0 `cat ${1}` > /dev/null 2>&1; then
      echo ${4}-CLUSTER-HOSTS-UPDATER is running as process `cat ${1}`.Stopping it.
      # stop update ${4}-CLUSTER HOSTS
      kill -9 `cat ${1}`
    fi
  fi
  
  if [ -f ${2} ]; then
    if kill -0 `cat ${2}` > /dev/null 2>&1; then
      echo ${5}-CLUSTER-HOSTS-UPDATER is running as process `cat ${2}`.Stopping it.
      # stop update ${5}-CLUSTER HOSTS
      kill -9 `cat ${2}`
    fi
  fi
  # The param ${3} is what you input now.
  if [ -f ${3} ]; then
    if kill -0 `cat ${3}` > /dev/null 2>&1; then
      echo ${6}-CLUSTER-HOSTS-UPDATER is already running as process `cat ${3}`.
      return 0
    fi
  fi
  # start update ${4}-CLUSTER HOSTS
  updateHosts "${7}" "${3}"
  echo Starting ${6}-CLUSTER-HOSTS-UPDATER as process `cat ${3}`.
}

#make the 1 to lower
function upper_to_lower {                             #make the WHITCHTDH to lower
    WHITCHTDH=`echo $1 | tr '[A-Z]' '[a-z]'`
}

function updateXml {
  cd ${DIR}
  java -jar hadoopconfigupdater-1.2.1.jar -zk $1 -pull -pullfiles ${DIR}/../base/conf/hadoop/conf/hdfs-site.xml,${DIR}/../base/conf/hadoop/conf/core-site.xml,${DIR}/../base/conf/hadoop/conf/mapred-site.xml,${DIR}/../base/conf/hadoop/conf/yarn-site.xml,${DIR}/../base/conf/$WHITCHTDH-conf/hdfs-site.xml,${DIR}/../base/conf/$WHITCHTDH-conf/core-site.xml,${DIR}/../base/conf/$WHITCHTDH-conf/mapred-site.xml,${DIR}/../base/conf/$WHITCHTDH-conf/yarn-site.xml,${DIR}/../base/conf/$WHITCHTDH-conf/hosts -c OVERWRITE -pullmode WATCH  >> ${DIR}/hadoop-clients-xml-updater.log 2>&1 &
  echo $! > $2
}

function updateHosts {
  cd ${DIR}
  java -jar hadoopconfigupdater-1.2.1.jar -zk $1 -pull -pullfiles  /etc/hosts -c APPEND -pullmode WATCH >> ${DIR}/hadoop-clients-hosts-updater.log 2>&1 &
  echo $! > $2
}

#--------------------------------#
#          Variate               #
#--------------------------------#
WHITCHTDH=$1                     # The type of TDH cluster, and cast to lower.
upper_to_lower $WHITCHTDH
OLYMPUS_ZK="40.32.65.47:2181,40.32.65.48:2181,40.32.65.49:2181"           #olympus's zookeeper IP
BABYLON_ZK="40.32.64.102:2181,40.32.64.103:2181,40.32.64.104:2181"        #babylon's zookeeper IP
TEST_ZK="197.3.84.202:2181,197.3.84.203:2181"                             #test's    zookeeper IP
DIR=`dirname $0`
DIR=`cd $DIR;pwd`
PID_DIR="${DIR}/pid"
BABYLON_HOSTS_PID_FILE="${PID_DIR}/hadoopconfigupdater-babylon-hosts.pid"
OLYMPUS_HOSTS_PID_FILE="${PID_DIR}/hadoopconfigupdater-olympus-hosts.pid"
TEST_HOSTS_PID_FILE="${PID_DIR}/hadoopconfigupdater-test-hosts.pid"
BABYLON_XML_PID_FILE="${PID_DIR}/hadoopconfigupdater-babylon-xml.pid"
OLYMPUS_XML_PID_FILE="${PID_DIR}/hadoopconfigupdater-olympus-xml.pid"
TEST_XML_PID_FILE="${PID_DIR}/hadoopconfigupdater-test-xml.pid"
#--------------------------------#
#          Run                   #
#--------------------------------#
#call function
if [ ! -d ${PID_DIR} ]; then 
  mkdir ${PID_DIR}
fi

case ${WHITCHTDH} in
"babylon")
  checkHostsPid "${TEST_HOSTS_PID_FILE}" "${OLYMPUS_HOSTS_PID_FILE}" "${BABYLON_HOSTS_PID_FILE}" "TEST" "OLYMPUS" "BABYLON" "${BABYLON_ZK}"
  checkXmlPid "${TEST_XML_PID_FILE}" "${OLYMPUS_XML_PID_FILE}" "${BABYLON_XML_PID_FILE}" "TEST" "OLYMPUS" "BABYLON" "${BABYLON_ZK}"
  ;;
"olympus")
  checkHostsPid "${TEST_HOSTS_PID_FILE}" "${BABYLON_HOSTS_PID_FILE}" "${OLYMPUS_HOSTS_PID_FILE}" "TEST" "BABYLON" "OLYMPUS" "${OLYMPUS_ZK}"
  checkXmlPid "${TEST_XML_PID_FILE}" "${BABYLON_XML_PID_FILE}" "${OLYMPUS_XML_PID_FILE}" "TEST" "BABYLON" "OLYMPUS" "${OLYMPUS_ZK}"
  ;;
"test")
  checkHostsPid "${BABYLON_HOSTS_PID_FILE}" "${OLYMPUS_HOSTS_PID_FILE}" "${TEST_HOSTS_PID_FILE}" "BABYLON" "OLYMPUS" "TEST" "${TEST_ZK}"
  checkXmlPid "${BABYLON_XML_PID_FILE}" "${OLYMPUS_XML_PID_FILE}" "${TEST_XML_PID_FILE}" "BABYLON" "OLYMPUS" "TEST" "${TEST_ZK}"
  ;;
esac

