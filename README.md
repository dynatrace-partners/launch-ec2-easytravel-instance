**ATTENTION:** This is currently a work in progress. Please check back when the course is complete

![](./images/partner_program.png)

# Overview
Hello and welcome to this Dynatrace Partner TechLab. We are launching these as self-paced training for all our partners. This session is not a normal tech lab but is instead intended to help partners launch their own instances of easyTravel for training or demo purposes.

This tutorial will provide instructions on how to launch easyTravel on ec2 instances via;
1. **Shell Script on EC2** - Automatically launch an EC2 instance and install the latest easyTravel Version by executing a shell script. Optionally you can auto-deploy the OneAgent, start an easyTravel scenario and auto terminate the instance after a given time.
2. **Postman on EC2** - Automatically launch an EC2 instance and install the latest easyTravel Version by executing 2 Postman Requests. Optionally you can auto-deploy the OneAgent, start an easyTravel scenario and auto terminate the instance after a given time.

Not only will we launch the instances and install easytravel but we will also configure it to support the ec2 public DNS name for the generated RUM data and we will enable the easyTravel Angular application.

## Pre-Requisites
Pre-Requisite | Shell Script | Postman
------------ | ------------- | ------------- | -------------
AWS account. If you don't have one [get one here](https://aws.amazon.com/) | Required | Required
AWS Access key and secret access key for an IAM user with rights ec2:RunInstances,  ec2:DescribeImages & ec2:CreateTags. | Required | Required
[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) installed | Required | N/A
Dynatrace PaaS token | Optional | Optional
[Postman](https://www.postman.com/downloads/) installed | N/A | Required
Clone or download this repo | Required | Required


## Preparation

**Amazon Web Services (AWS) - Required for Shell Script and Postman**

As we are going to use AWS EC2. We have tested this tutorial on eu-west-1 (Ireland), Paris (eu-west-3) & ..... . To be on the safe side we suggest you pick one of these regions!

Ensure you have created an IAM user  with rights ec2:RunInstances, ec2:DescribeImages & ec2:CreateTags I recommend you create a user for this with only these rights that can be removed in the future.

Login to your AWS account and navigate to IAM > Users > Add user and complete the following
1. Give your user a name and select Programmatic access

![](./images/preparation/awsconfigure.png)

2. Select Create Group

![](./images/preparation/awsCreateGroup.png)

3. Name your group and select Create policy. The Policy creater should open in a new tab.

![](./images/preparation/awsGroupName.png)

4. Choose the service ec2 and under actions search and add RunInstances, DescribeImages & CreateTags. Then click Review policy

![](./images/preparation/awsCreatePolicy.png)

5. It should look like the following. Select Create Policy

![](./images/preparation/awsPolicy.png)

6. Return to your previous tab, click Refresh and search for you new policy. Tick the policy and select Create Group

![](./images/preparation/awsPolicyGroup.png)

7. Ensure your group has been added for your user and the policy is attached. Click Next:tags. Tags are optional so add one if you wish and click Next:Review

![](./images/preparation/awsSetPer.png)

8. Your new user should look like the following. Click Create User. Store your credentials, you can download csv to save them in a file. 

![](./images/preparation/awsUserSum.png)

Once you have your IAM user and role we need a couple of things
1. Your AWS Access Key ID. It should look something like `AKIAIOSFODNN7EXAMPLE`
2. Your AWS Secret key. It should look something like `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`
3. Your AWS region. It should look something like `eu-west-1`

**AWS CLI - Required for Shell Script**

Configure your AWS CLI using the [`aws configure`](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-creds) command and the credentials you created above.

**Postman - Required for Postman**

Once you have installed Postman we need a couple of things
1. Upload the <a id="raw-url" href="https://raw.githubusercontent.com/dynatrace-partners/launch-ec2-easytravel-instance/postman/easyTravel.postman_environment.json">postman environment</a> we have provided.

    Inside Postman click on import, select file and upload TechLab-Managed-Cluster-Automation.postman_environment.json

    ![](./images/preparation/postmanEnv.png)

2. Upload the [<a id="raw-url" href="https://raw.githubusercontent.com/dynatrace-partners/launch-ec2-easytravel-instance/postman/easyTravel.postman_collection.json">postman collection</a> we have provided.

    Repeat the same process to import TechLab-Managed-Cluster-Automation.postman_collection.json

    ![](./images/preparation/postmanCollection.png)

3. Configure your postman environment variables

    * Click on the ![](./images/preparation/manageEnvironments.png) to manage your environments

    * Click on the environment name TechLab-Managed-Cluster-Automation

    * Set the first 5 environment variables to your values. Ensure to set both the initial and current values. For dtManaged it should look like 'xxxxxx.dynatrace-managed.com' do not include the 'https://'. Do not tough the 'installET' variable.

    ![](./images/preparation/environmentVars.png)

    * Click on update to save your changes

4. Select your postman environment in the upper right hand corner dropdown

    ![](./images/preparation/postmanSelEnv.png)

# 1. Creating a new easyTravel instance using a shell script

## Script configuration

The script is made up of a number of parts. The parts are;

1. At the top of the script you have the option to specify your Dynatrace URL and PaaS token if you wish to auto-deploy the OneAgent.

2. The second part is an AWS CLI call to get the latest Ubuntu AMI in your region, it is filtered to the Ubuntu Cloud Account. This way when you launch an ec2 instance in the next step it will use this AMI to ensure you are on an up-to-date version.

3. When we launch the ec2 instance we will supply User data to perform our intallation and configuration. As this will be unique each time depending on the options you choose we first create a new version to maintain the base configuration for future launches.

4. Then we check if dtURL has been set. If it has then we will add the download and installation instructions for the OneAgent to our script. You can modify the installaion instructions if you want to make any customisations. 

**Please note:** The script does not validate the dtURL & paasToken values. If dtURL is anything other than blank it will add the commands to the script.

5. The next command is commented out. It is an optional command to start easyTravel in startgroup UEM & startscenario Standard with REST Service and Angular2 frontend. This is useful if you don't want to have to log onto the instance to start easyTravel. If you uncomment it then it will add the command to your user data.

6. The next command is alos commented out. It is an optional command to automatically terminate the EC2 instance after a given umber of hours. This is useful for training classes if you don't want to have remember to terminate the instances at a later point. If you uncomment it then it will add the command to your user data.

7. This is the command to launch the EC2 instance. When the instance is launched we will supply our completed user data script. By default the script does not provide a key name or security group id. Without a key name you will not be able to log onto the instance. Without a security group it will go into the default group. This might prevent you accessing the application and the OneAgent \(if configured\) from sending data back. It is recommended to configure both of these.

8. The final step deletes the user data file again.

**Executing the request**
1. In your chosen terminal, navigate to the scripts folder of the cloned or downloaded repo.
2. Grant execution rights to the script by running `chmod +x launchEC2easyTravel.sh`
3. View the contents of the script and decide if you would like to supply or enable any of the optional elements. If you do make the necessary changes.
4. Excute the script by running `./launchEC2easyTravel.sh`
5. Inside your AWS console check the instances have been created

![](./images/runinstances/runInstancesEC2.png)

6. If you chose to deploy the OneAgent, check in dynatrace to see if your hosts are now monitored. Please note this can take 5-10 mins. 
 
# 2. Creating a new easyTravel instance using Postman

To create the instance in postman you need 2 requests. The first gets the latest Ubuntu AMI in your region, it is filtered to the Ubuntu Cloud Account. This way when you launch an ec2 instance in the next step it will use this AMI to ensure you are on an up-to-date version.

The second launches the instance.

**Executing the Get AWS AMI ID request**
1. Open the Get AWS AMI ID request.
2. Click on `Send` to execute the request.
3. Check that the request received a `200 OK` response.

![](./images/ami/getAMIResp.png)

    If you get a 401 error check the value of your accessKeyID, secretAccessKey and region environment variables. Ensure both the initial and current values are set and the same. If they are verify you have added the correct roles in IAM.

5. Check that the ImageId environment variable has been set in postman

![](./images/ami/getAMIVars.png)

Now that we have the latest Ubunntu image AMI we can launch our ec2 instances.

**How do you launch an easyTravel ec2 instances via Postman?**

We will leverage the aws RunInstances API call to start 2 instances of the latest Ubuntu AMI that we gathered in the previous call. This will be a blank Ubuntu image so we will leverage [AWS UserData](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) to install and configure both easyTravel and the OneAgent. The UserData is sent as base64-encoded text and we dynamically set some values in the postman execution if you include the optional emements.

## Launching easyTravel ec2 Instance via Postman

**Request configuration**

**ATTENTION:** There are some values that are unique to your ec2 account that you will have to set for this request to work.

Let's have a look at the configuration of this request so we can understand what will happen when we execute it.

This is a Post request that leverages the aws API endpoint to execute the action runInstances. This API call will start an instance of the latest Ubuntu image from the AMI that was gathered in the previous step.

**Parameters**

There are a lot of Parameters in this request, but I will only cover the ones relevant to dynatrace or that you may need to change for your environment.

You may need to set the following Parameters. Determine if you need to set them by reading the table below. If you do need to set them then add the value in postman and ensure you tick the box to the left of the key name to enable it. 
Key | Value | Requirement | Description
------------ | ------------- | ------------- | -------------
KeyName | The name of your key pair | Optional | The name of the key pair used to connect to your instance. You can create a key pair using [CreateKeyPair](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateKeyPair.html). If you do not specify a key pair, you can't connect to the instance. In our use case there is no direct requirement to access the environment, but you may find it useful if you want to perform troubleshooting or use the instance in the future for other things.
SecurityGroupId | The ID of your security group | Optional | If you don't specify a security group ID, aws use the default security group. For more information, see [Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html). Depending on your setup this may be required. A security group acts as a virtual firewall for your instance to control incoming and outgoing traffic so you may require a specific one to allow the correct access to and from your instance. At a minimum you will need inbound on 9080 & 8079 to access the easyTravel & easyTravel Angular front ends and outboun either 443 for direct OneAgent communication or 9999 via an ActiveGate. 

The secret sauce here that you should be aware of is [AWS UserData](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html). When we launch this request we supply a set of commands to be executed on the ec2 instance at start up. The userdata is preconfigured, but you can make changes to include the optional elements. Is is configured in the Pre-request script.

**Pre-request script**
This is part of postman. You can use pre-request scripts in Postman to execute JavaScript before a request runs. You can find more details [here](https://learning.postman.com/docs/postman/scripts/pre-request-scripts/)
In our case the script updates the userdata to be sent to aws including the following
1. Updates the package lists by running apt-get update
2. Installs the required packages
3. Downloads and installs the latest version of easyTravel
4. Makes required config changes to easyTravel including API call to set correct public DNS of instance for the source of the traffic that is generated.
5. Optional - Installs the OneAgent for your newly created environment leveraging the API token you created in exercise 5
6. Optional - Starts the easyTravel angular app. This means you don't even need to access the environment.
7. Optional - Auto terminates after 8 hours

**ATTENTION:** When we create these hosts they are set to auto terminate on shutdown so keep in mind the host will terminate if you shut it down.

To change the shutdown behaviour of an instance using the console (only after you have started your instance)

1. Open the Amazon EC2 console at `https://console.aws.amazon.com/ec2/`.
2. In the navigation pane, choose Instances.
3. Select the instance, and choose Actions, Instance Settings, Change Shutdown Behaviour. The current behaviour is already selected.
4. To change the behaviour, select an option from the Shutdown behaviour list, and then choose Apply.
![](./images/runinstances/shutdown_behavior_dialog.png)


**Executing the Launch AWS easyTravel Instances request**
1. Open the Launch AWS easyTravel Instances request.
2. View the contents of Params tab. Optionally supply a key name and security group ID for your instance
3. View the Pre-request Script tab. Optionally uncomment any of block you wish to include. If you want to include the OneAgent deployment ensure you have set the environment variables dtURL and paasToken.
4. Click on `Send` to execute the request.
5. Check that the request received a `200 OK` response.

![](./images/runinstances/runInstancesRespProd.png)

    If you get a 401 error check the value of your accessKeyID, secretAccessKey and region environment variables. Ensure both the initial and current values are set and the same. If they are verify you have added the correct roles in IAM.

6. Inside your AWS console check the instance has been created

![](./images/runinstances/runInstancesEC2.png)

7. If you chose to deploy the OneAgent, check in dynatrace to see if your hosts are now monitored. Please note this can take 5-10 mins. 

    **Troubleshooting**
    If after 10 mins your hosts have not appeared in dynatrace check the following.
    1. In the AWS EC2 console select one of your instances and click on Actions > Instance settings > View/Change User Data.
        * Verify the userdata has not been corrupted
        * Check the values for your managed environment URL add API token in the wget command
    2. Log on to your instance and view log /var/log/cloud-init-output.log to check for errors in downloading, installing or connection of your OneAgent. You can do this by executing `Tail -f /var/log/cloud-init-output.log`. Please note to access the instance you will need to have specified KeyName when you created the instance. 

Congratulations you have just created 2 new ec2 instance.

