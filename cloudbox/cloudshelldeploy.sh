#!/bin/bash

####################################################################################################
# Script to drive terraform to setup a dev box with rdp capability in the cloud
#

# Check to see if terraform is present
if ! type "terraform" > /dev/null 2>&1 ; then
    echo "Terraform missing. Please install by using"
    echo "curl -sSL https://raw.githubusercontent.com/bonggeek/share/master/cloudbox/installterraform.sh | bash"
    exit 1
fi

if ! type "az" > /dev/null 2>&1 ; then
    echo "Azure CLI missing. Please install"
    exit 1
fi

# Get the current IP address. We will add this to the VM access allow rule so that 
# from this session we can run remote scripts to configure the VM
shellip=$(curl -s http://ipconfig.io)
echo "Connecting from $shellip"

echo 'Downloading terraform files'
curl -s -O https://raw.githubusercontent.com/bonggeek/share/master/cloudbox/cloudVM.tf
curl -s -O https://raw.githubusercontent.com/bonggeek/share/master/cloudbox/cloudVMsetup.sh
echo 'Downloaded terraform files'

#az login
#az account set --subscription="ef26d084-5353-49bb-856d-e40444a93cb3"

echo "Initializing terraform"
terraform init > /dev/null

if [ -z "$1" ]; then
    read -p 'Username: ' username
else
    username=$1
fi

if [ -z "$2" ]; then
    read -sp 'Password: ' password
else
    password=$2
fi

cmd="terraform apply -auto-approve -var 'userName=$username' -var 'password=$password' -var 'network_allow_rules={ \"0\" = \"131.107.0.0/16,22,TCP\", \"1\" = \"131.107.0.0/16,3389,TCP\", \"2\" = \"207.68.190.32/27,22,TCP\", \"3\" = \"207.68.190.32/27,3389,TCP\", \"4\" = \"52.250.118.235,22,TCP\", \"5\" = \"52.250.118.235,3389,TCP\", \"6\" = \"$shellip,22,TCP\" }'"
eval $cmd
