#!/bin/bash


#####
##### call this script with a param of either enable or disable
##### the script will turn off ports and services for upgrading a CN when disabled
##### the script will turn on ports and services after upgrading a CN when enabled
#####

#### start up debconf backend database
if [ -e "/usr/share/debconf/confmodule" ]; then
    . /usr/share/debconf/confmodule
else
    echo "debconf must be installed. Exiting."
    exit 1
fi

if [ -e "/usr/local/bin/stopDaemons.sh" ]; then
    echo "The stopDaemons.sh script is already installed"
else
    echo "The stopDaemons.sh script must be installed. Trying to install it."
    http_code=$(curl -s -w %{http_code} -o /usr/local/bin/stopDaemons.sh \
        https://repository.dataone.org/software/tools/trunk/dataone_cn_dev_scripts/usr/share/dataone_cn_dev_scripts/bash/stopDaemons.sh)
    if [[ "${http_code}" != "200" ]]; then
        echo "Couldn't install the stopDaemons.sh script.  Install it manually into /usr/local/bin"
        exit 1    
    else
        chmod ug+x /usr/local/bin/stopDaemons.sh
        echo "stopDaemons.sh script was successfully installed"        
    fi
fi

TOGGLE=${1}

MAX_SERVICE_STOP_TRIES=18
if [[ ${TOGGLE} == "" ]]; then
  echo "pass in a toggle param of [enable|disable] to either enable or disable ports and metacat replication"
  db_stop
  exit 1
fi

if [[ ${TOGGLE} == "enable" || ${TOGGLE} == "disable" ]]; then
  echo "${TOGGLE} ports and metacat replication"
else
  echo "pass in a toggle param of [enable|disable] to either enable or disable ports and metacat replication"
  db_stop
  exit 1
fi



##### find out if ldap or other process is running
##### if it is not try to restart
##### if it does not restart, then fail

function confirm_service_stop() 
{
  local PROCESS_NAME=$1
  A=0
  while (pidof ${PROCESS_NAME} >> /tmp/${0}.${PROCESS_NAME}.pid.tmp 2>&1); 
    do
    let "A += 1" 
    if [[ $A -gt $MAX_SERVICE_STOP_TRIES ]]; then
      echo "process ${PROCESS_NAME} hasn't stopped. Aborting."
      db_stop
      exit 1
    fi
    echo "sleeping 10 seconds: $A of $MAX_SERVICE_STOP_TRIES "
    sleep 10 
  done
  echo "$PROCESS_NAME stop confirmed"
  return
}

##### find out if tomcat is running
##### if it is not try to restart
##### if it does not restart, then fail

function confirm_tomcat_stop() 
{
  local PROCESS_NAME=$1
  A=0
  while [ -f /var/run/${PROCESS_NAME}.pid ]
    do
    let "A += 1" 
    if [[ $A -gt $MAX_SERVICE_STOP_TRIES ]]; then
      echo "process ${PROCESS_NAME} hasn't stopped. Aborting."
      db_stop
      exit 1
    fi
    echo "sleeping 10 seconds: $A of $MAX_SERVICE_STOP_TRIES "
    sleep 10 
  done
  echo "$PROCESS_NAME stop confirmed"
  return
}


MY_ADDRESS=""
MY_OTHER_ADDRESSES=()
PORTS=(5701 5702 5703 389 5432)

/usr/local/bin/stopDaemons.sh

service tomcat9 stop
confirm_tomcat_stop tomcat9
service slapd stop
confirm_service_stop slapd
service postgresql stop
confirm_service_stop postgres


MY_POSSIBLE_IPS=(`hostname --all-ip-addresses`)

db_get dataone-cn-os-core/cn.iplist
ALL_ENVIRONMENT_IPLIST=(${RET}) 
for ip in ${MY_POSSIBLE_IPS[@]}
do
  for all_ip in ${ALL_ENVIRONMENT_IPLIST[@]}
  do
    if [[ "${all_ip}" = "${ip}" ]]; then
      MY_ADDRESS=${ip}
      break 2
    fi
  done
done
echo "$MY_ADDRESS"

for cn_ip in ${ALL_ENVIRONMENT_IPLIST[@]}
do
  if [[ "${cn_ip}" != "${MY_ADDRESS}" ]]; then
    echo "${cn_ip}"
    MY_OTHER_ADDRESSES=( "${MY_OTHER_ADDRESSES[@]}" "${cn_ip}" )
  fi
done

for PORT in ${PORTS[@]}
do
  for IP in ${MY_OTHER_ADDRESSES[@]}
  do
    if [[ ${TOGGLE} == "enable" ]]; then
      ufw allow to any port ${PORT} from ${IP}
    else
      ufw delete allow to any port ${PORT} from ${IP}
    fi 
  done
done

/etc/init.d/slapd start

/etc/init.d/postgresql start

systemctl start tomcat9


if [[ ${TOGGLE} == "enable" ]]; then
 su postgres -c "psql -d metacat  -c \"UPDATE xml_replication SET replicate = 1, datareplicate = 1 WHERE serverid > 1\""
else
  su postgres -c "psql -d metacat  -c \"UPDATE xml_replication SET replicate = 0, datareplicate = 0 WHERE serverid > 1\""
fi

db_stop
exit 0
