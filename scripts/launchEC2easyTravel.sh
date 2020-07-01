#!/bin/bash
#*********************************
#If you wish to auto deploy the oneagent provide your dynatrace URL and a PaaS token. If you don't leave them blank
#Format for SaaS - {your-environment-id}.live.dynatrace.com or for Managed - {your-domain}/e/{your-environment-id}
dtURL=
paasToken=

#get the latest ubuntu image AMI id
ubuntu=($(aws ec2 describe-images --owners "099720109477" \
  --filters 'Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-bionic-*' 'Name=state,Values=available' 'Name=is-public,Values=true' 'Name=architecture,Values=x86_64' \
  --query 'reverse(sort_by(Images, &CreationDate))[].ImageId' \
  --output text
))

#create our user data script by copying the sample
cp my_script_sample.txt my_script.txt

#set dtURL and passToken if they are set
		if [ "$dtURL" != "" ]; then
echo 'wget  -O Dynatrace-OneAgent.sh "https://'$dtURL'/api/v1/deployment/installer/agent/unix/default/latest?Api-Token='$paasToken'&arch=x86&flavor=default"' >> my_script.txt
echo '/bin/sh Dynatrace-OneAgent.sh --set-app-log-content-access=true --set-infra-only=false --set-host-group=Production' >> my_script.txt
		fi

#if you would like to auto start easytravel then uncomment the next line
#echo "su -c 'nohup /home/ubuntu/easytravel-2.0.0-x64/runEasyTravelNoGUI.sh --startgroup UEM --startscenario \"Standard with REST Service and Angular2 frontend\" &' - ubuntu" >> my_script.txt

#if you would like to auto terminate your instance after a given time uncomment the next line and update the value to whatever length you require.
#echo 'echo "sudo halt" | at now + 8 hours' >> my_script.txt

#launch ec2 instance. Optionally you might also want to provide a key name and a security group id in the following format. --key-name YourKeyName --security-group-ids sg-YourSgIdNum \ 
#Without these you will not be able to access the host or easyTravel front end. When creating a security group the minimum requirements are inbound on 9080 & 8079 to access the easyTravel & easyTravel Angular front ends and outboun either 443 for direct OneAgent communication or 9999 via an ActiveGate.
ec2=($(aws ec2 run-instances --image-id $ubuntu --count 1 --instance-type t2.medium \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=easyTravel}]' 'ResourceType=volume,Tags=[{Key=Name,Value=easyTravel}]' \
--instance-initiated-shutdown-behavior terminate \
--user-data file://my_script.txt))

#remove temp script
rm -rf my_script.txt