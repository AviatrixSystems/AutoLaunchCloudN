<# .SYNOPSIS
	Script will set IP address, gateway, netmask and dns nameservers in eth0
	
.DESCRIPTION
	Script is using get-VM PowerCLI cmdlet to set guest VM parameters. This assumes an Ubuntu linux VM. 
	
.PARAMETER 
	Mandatory parameter of vSphere/ESXi host, username and password
	
.EXAMPLE
	set_vm_networking.ps1 -Server 10.130.0.2 -User username1 -Password password #>
	
	
param($Server,$User,$Password)
Connect-VIServer -Server $Server -Protocol https -User $User -Password $Password


$pathfile = "/etc/network/intf"

$cloudn_interface = "eth0"
$cloudn_ip = "10.10.0.10"
$cloudn_netmask = "255.255.0.0"
$cloudn_gateway = "10.10.0.1"
$cloudn_dns1 = "8.8.8.8"
$cloudn_dns2 = "8.8.4.4"
$http_proxy = ""
$https_proxy = ""
$guestuser = "test"
$guestpass ="test123"


# check running PowerCLI version
Get-PowerCLIVersion

# Get VM name = "DNS"
$vm_name = "TestDNS"
$vm = Get-VM $vm_name

# Check installed VMware Tools inside VM
$GuestToolsStatus=(Get-View $vm.Id -Property Guest).Guest.ToolsStatus


Function setNetworking ($ip,$netmask,$gateway,$dns1,$dns2,$eth,$pathfile,$guestuser,$guestpass){
	Write-Output "Interface = $eth"
	Write-Output "IP address = $ip"
	Write-Output "Netmask = $netmask"
	Write-Output "Gateway = $gateway"
	Write-Output "DNS = $dns1 $dns2"
	Write-Output "Target Filename = $pathfile"
	Write-Output "Guest Username = $guestuser"
	Write-Output "Guest Password = $guestpass"
	
	# check if http/https proxy are enabled
	
	
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo auto $eth >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo iface $eth inet static >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo address $ip >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo netmask $netmask  >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo gateway $gateway >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo dns-nameservers $dns1 $dns2 >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
}

if($vm.powerstate -eq "PoweredOn"){
	Write-Output "Guest VM is PoweredON"
	
	if($GuestToolsStatus -eq "toolsOK"){
		Write-Output "VMWware Tools is OK"

		# test command
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “pwd” -GuestUser test -GuestPassword test123 -ToolsWaitSecs 30
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “whoami” -GuestUser test -GuestPassword test123 -ToolsWaitSecs 30
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “pwd” -GuestUser test -GuestPassword test123 -ToolsWaitSecs 30

		# Setting IP/Netmask/GW/DNS for eth0 interface
		#
		setNetworking -ip $cloudn_ip -netmask $cloudn_netmask -gateway $cloudn_gateway -dns1 $cloudn_dns1 -dns2 $cloudn_dns2 -eth $cloudn_interface -pathfile $pathfile -guestuser $guestuser -guestpass $guestpass

 	}else{
		Write-Output "vmtoolsd not running, please re-install VMware Tools to guest VM"
		Disconnect-VIServer -confirm:$false -Server $Server
	}
}else{
	Start-VM -VM $vm_name
	sleep 20
	setNetworking -ip $cloudn_ip -netmask $cloudn_netmask -gateway $cloudn_gateway -dns1 $cloudn_dns1 -dns2 $cloudn_dns2 -eth $cloudn_interface -pathfile $pathfile -guestuser $guestuser -guestpass $guestpass

}

	Disconnect-VIServer -confirm:$false -Server $Server

 

 




