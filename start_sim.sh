#!/bin/bash

################################################################################
#            Modify below as needed or override with ENV vars                  #
################################################################################

if [ "$1" == "c2" ] || [ "$1" == "platform" ] ; then
  export TYPE=$1
else
  echo 'Pass in either "c2" or "platform"'
  exit
fi

# Set XML File defaults
if [ -z "${XML_FILES}" ]; then
  XML_FILES+="./qos/comms_qos_lib.xml;"
  # Add Types file
  XML_FILES+="./types/comms_types.xml"
fi

# Set QOS Profile
if [ -z "${QOS_PROFILE}" ]; then
  QOS_PROFILE="comms_qos_lib::c2_qos"
fi

# Set Domain ID defaults
if [ -z "${DOMAIN_ID}" ]; then
  if [ ${TYPE} == "c2" ]; then
    DOMAIN_ID=2
  elif [ ${TYPE} == "platform" ]; then
    DOMAIN_ID=0
  fi
fi

# Set SRC GUID
if [ -z "${SRC_GUID}" ]; then
  if [ ${TYPE} == "c2" ]; then
    SRC_GUID="cb8e8858-c8c2-277f-94b6-32287bed9d05"
  elif [ ${TYPE} == "platform" ]; then
    SRC_GUID="ef32b88e-6e0c-49e9-9886-ae20c28d7f3c"
  fi
fi

# Set DEST GUID
if [ -z "${DEST_GUID}" ]; then
  if [ ${TYPE} == "c2" ]; then
    DEST_GUID="ef32b88e-6e0c-49e9-9886-ae20c28d7f3c"
  elif [ ${TYPE} == "platform" ]; then
    DEST_GUID="cb8e8858-c8c2-277f-94b6-32287bed9d05"
  fi
fi

# Set Session ID
if [ -z "${SESSION_ID}" ]; then
  SESSION_ID=5
fi

# Set verbosity
# 0: dds.Verbosity.SILENT
# 1: dds.Verbosity.EXCEPTION
# 2: dds.Verbosity.WARNING
# 3: dds.Verbosity.STATUS_ALL
if [ -z "${VERBOSITY}" ]; then
  VERBOSITY=2
fi

################################################################################

echo "-------------------------------- CONFIGS: --------------------------------"
echo "XML FILES: " $XML_FILES
echo "QOS_PROFILE: " $QOS_PROFILE
echo "DOMAIN_ID: " $DOMAIN_ID
echo "SRC_GUID: " $SRC_GUID
echo "DEST_GUID: " $DEST_GUID
echo "SESSION_ID: " $SESSION_ID
echo "VERBOSITY: " $VERBOSITY
echo "-------------------------------- CONFIGS: --------------------------------"


# RUN
python3 ./sim/${TYPE}_sim.py --files ${XML_FILES} \
                             --qos_profile ${QOS_PROFILE} \
                             --domain_id ${DOMAIN_ID} \
                             --src_guid ${SRC_GUID} \
                             --dest_guid ${DEST_GUID} \
                             --session_id ${SESSION_ID} \
                             --verbosity ${VERBOSITY}





