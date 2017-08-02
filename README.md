# AutoLaunchCloudN

This script automates the initial process of setting up CloudN's IP address, network mask, default gateway, DNS servers and proxy settting. With this script, you do not
need to manually go through the Booting Up and Initial Configuration section in CloudN startup guide. 

## Launch CloudN VM
Before you can use the script for the initial process, CloudN virtual machine has to be launched. Below is a 
sample ovftool command to launch CloudN VM from a Window's desktop using vmware OVF Tool. (https://www.vmware.com/support/developer/ovf/)

```command
Usage: ovftool [options] <source> [<target>]

where
<source>: Source URL locator to an OVF package 
<target>: Target URL locator which specifies either a file location, or on ESX Server
     -ds: Target datastore name for a VI locator  
     -n : Specifies target name (CloudN VM name)	 
 
c:\Program Files\VMware\VMware OVF Tool>ovftool -ds="cwchang-datastore" -n="CloudNVMName" c:\Users\Administrator\Desktop\CloudN-ovf-051517\CloudN-ovf-051517\CloudN-ovf-051517.ovf vi://<ESXi_username>:<ESXi_password>@<ESXi_IP>
```

The output of the above command is as below
```output
Opening OVF source: c:\Users\Administrator\Desktop\CloudN-ovf-051517\CloudN-ovf-051517\CloudN-ovf-051517.ovf
The manifest validates
Opening VI target: vi://root@10.130.0.2:443/
Deploying to VI: vi://root@10.130.0.2:443/
Transfer Completed
Completed successfully
```

## Automating CloudN Booting up via PowerCLI Script ##

VMware vSphere PowerCLI provides a Windows PowerShell interface to the vSphere API. vSphere PowerCLI includes PowerShell Cmdlets for administering vSphere components. 

1. Download vSphere PowerCLI package from my.vmware.com.
2. Select "Downloads" and search for "vSphere PowerCLI"�.
3. Make sure the PowerCLI version match your vSphere Client/ESXi host version. For example, if your vSphere Client is 6.5.1, you should select PowerCLI 6.5.1.
4. Install in PowerCLI package on your vSphere Client - Windows Server. 
5. This will create a shortcut "VMware vSphere PowerCLI"� from your Window's desktop.
6. Run this program "VMWare vSphere PowerCLI" as administrator privilege. 
7. From PowerCLI environment type "set-executionpolicy RemoteSigned" and answer [A] Yes to All.

## Git Clone PowerCLI Script ##

git clone https://github.com/AviatrixSystems/AutoLaunchCloudN.git

## Run PowerCLI script ##

1. The script assumes you already downloaded CloudN OVF files onto your vSphere client. 
2. Use vSphere Client to launch the CloudN OVF as you would normally do for any VM and give the VM a name. For example, CloudN-ovf-061517. (To launch the VPM, go to File -> Deploy OVF Template, select the location and the OVF file.) Note, this may take up to an hour if your host machine does not have SSD drive. 

3. Once the VM is finished Deploying and powered on, go to your Window's PowerCli host, click and run the VMware vSphere PowerCLI shortcut as an administrator.
4. From PowerCLI environment type "set-executionpolicy RemoteSigned" and answer [A] Yes to All.
5. Do cd to the location of the powercli script
6. Customize the CloudN information. In the script powercli_launch.ps1, csutomize the following fields:

```parameters
$cloudn_ip = "10.130.0.10"
$cloudn_netmask = "255.255.0.0"
$cloudn_gateway = "10.130.0.1"
$cloudn_dns1 = "8.8.8.8"
$cloudn_dns2 = "8.8.4.4"
$http_proxy = ""
$https_proxy = ""
```

6. Type .\powercli_launch.ps1 -Server <ESXi Host IP address> -User <username> -Password <password>, where username is the login of the ESXi host and password is the password of the username for the ESXi host. 
7. At the completion of the script, you should be able to access CloudN from its web console. Open a browser, and type https://CloudN-private-ip-address, where CloudN-private-ip-address is $cloudn_ip in the above customization code. 


## CloudN Documentation
1. http://docs.aviatrix.com/HowTos/configuring_cloudN_examples.html?highlight=deploy%20cloudn
