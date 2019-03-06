#!/bin/bash

#############
# Changelog #
#############

# Find the newest version of this script at https://github.com/sejnub/docker-nodered/edit/master/download_nodered_config.sh
#
# 2019-03-01 11:25:48 
# - Improved sourcecode readability 
# - Improved echo outputs
# 2019-03-06
# - Added some comments

#############
# Constants #
#############

USERNAME=""
PASSWORD=""
NODEREDHOST=""

ENF_FN="../.env"

tempdir=./temp_delete_me
dest_prefix=$tempdir/

source_prefix="/fs/data/"


#######
# Doc #
#######

# TODO: The following precedence is not perfect. Improve that!
# Current parameter precedence
# 
# - Arguments given to the script call
# - Constants set in the script source
# - Values from env file
# - values from environment variables
# 
# Perfect precedence
#
# - Arguments given to the script call
# - Constants set in the script source
# - values from environment variables
# - Values from env file

# https://github.com/node-red/cookbook.nodered.org/wiki/How-to-backup-flows-and-related-configuration


#########
# Start # 
#########

me=$(basename -- "$0")

echo "Info: $me started."
echo "Info: This script will download the current definitions of node-red."


# Get config from script arguments
##################################

while getopts "u:p:h:" opt; do
  case "$opt" in
    u)
     USERNAME=$OPTARG
     echo "Info: Username is taken from script argument."
     ;;
    p)
     PASSWORD=$OPTARG
     echo "Info: Password is taken from script argument."
     ;;
    h)
     NODEREDHOST=$OPTARG
     echo "Info: Host is taken from script argument."
     ;;
   esac
done


# Get config from program .env file
###################################

if [ "$USERNAME" == "" ]  && [ "$PASSWORD" == "" ] ; then
  echo "Info: No username and password provided. Using environment variables..."
  
  if [ -f "$ENF_FN" ]; then
    echo "Info: I am sourcing the env file named '$ENF_FN'."
    . $ENF_FN
  else
    echo "Info: There is no env file."
  fi

  echo "Info: I am now setting the credentials using the environment variables."
  USERNAME=$BOP_BROKER_CREDENTIAL_NODERED_USER
  PASSWORD=$BOP_BROKER_CREDENTIAL_NODERED_PASS
fi

echo
echo "Info: The following values are used"
echo "Info:   username = '$USERNAME'"
echo "Info:   password = '$PASSWORD'"
echo "Info:   host     = '$NODEREDHOST'"


# Function definitions
######################

# download_file_raw (from, to)
download_file_raw () {
  from=$1
  to=$2

  echo "Downloading $from"

  http_status=$(curl --write-out %{http_code} --silent -u $USERNAME:$PASSWORD -XGET $from  -o $2)
  result_status=$?
 
  #echo "http_status='$http_status'"
  
  echo "================"
  if [[ $http_status != 200 ]] && [[ $http_status != 204 ]]; then
    echo "FAILED with HTTP status '$http_status' and result_status '$result_status'"
  else
    echo SUCCESS
  fi
  echo "================"
  echo
}

# download_file_simple (filename)
download_file_simple () {
  current_filename=$1
  from=${NODEREDHOST}${source_prefix}${current_filename}
  to=${dest_prefix}${current_filename}
  download_file_raw $from $to
}


# Download with curl
####################

mkdir $tempdir
echo

# These define the flows and any credentials stored for the flows.
download_file_simple "flows.json"
download_file_simple "flows_cred.json"

# This contains the current configuration being used. Includes a list of all of 
# the modules and node types that are being loaded with their versions.
download_file_simple ".config.json"

# Defines the user global settings for Node-RED.
download_file_simple "settings.js"

# If used (will be standard from Node-RED version 0.17), defines the extra 
# npm modules installed such as node-red-contrib-* nodes.
download_file_simple "package.json"


# Copy to final destination and remove tempdir
##############################################

cp $tempdir/"flows.json"       "data/flows.json"
cp $tempdir/"flows_cred.json"  "data/flows_cred.json"
cp $tempdir/".config.json"     "data/.config.json"
cp $tempdir/"settings.js"      "data/settings.js"
cp $tempdir/"package.json"     "data/package.json"

rm -rf $tempdir


# The end
#########

echo
echo "Info: Finished download..."
echo "Info: $me ended."

