# AutoLaunchCloudN

## Automating CloudN via PowerCLI Script ##

VMware vSphere PowerCLI provides a Windows PowerShell interface to the vSphere API. vSphere PowerCLI includes PowerShell Cmdlets for administering vSphere components. 

1. Download vSphere PowerCLI package from my.vmware.com.
2. Select “Downloads” and search for “vSphere PowerCLI”.
3. Make sure the PowerCLI version match your vSphere Client/ESXi host version.
4. Install in PowerCLI package on your vSphere Client - Windows Server. 
5. This will create a shortcut “VMware vSphere PowerCLI” from your desktop.
5. From PowerCLI environment type “set-executionpolicy RemoteSigned” and answer “[A] Yes to All.

## Git Clone PowerCLI Script ##

https://github.com/AviatrixSystems/AutoLaunchCloudN.git

## Run PowerCLI script ##

1. The script assumes a successful deployment of CloudN OVF format from windows desktop to ESXI datastore.
2. It will look for VM name assigned by the user.
3. Click and run the VMware vSphere PowerCLI shortcut as an administrator.
4. From PowerCLI environment type “set-executionpolicy RemoteSigned” and answer “[A] Yes to All.
5. Do cd to the location of the powercli script
6. Type .\powercli_launch.ps1 -Server <ESXi Host IP address> -User <username> -Password <password>


## CloudN Documentation
1. http://docs.aviatrix.com/HowTos/configuring_cloudN_examples.html?highlight=deploy%20cloudn
