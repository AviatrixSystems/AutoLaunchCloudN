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



$cloudn_interface = "eth0"
$cloudn_ip = "10.130.0.10"
$cloudn_netmask = "255.255.0.0"
$cloudn_gateway = "10.130.0.1"
$cloudn_dns1 = "8.8.8.8"
$cloudn_dns2 = "8.8.4.4"

$guestuser = "admin"
$guestpass ="Aviatrix123#"
# proxy settings disabled
$http_proxy = ""
$https_proxy = ""

# proxy settings enabled
#$http_proxy = "http://10.130.0.15:3128"
#$https_proxy = "http://10.130.0.15:3128"

# check running PowerCLI version
Get-PowerCLIVersion

# VM name assigned for CloudN by user from vSphere Client
$vm_name = "CloudN1"
$vm = Get-VM $vm_name


Function setNetworking ($ip,$netmask,$gateway,$dns1,$dns2,$eth,$guestuser,$guestpass,$http_proxy,$https_proxy){
	Write-Output "Interface = $eth"
	Write-Output "IP address = $ip"
	Write-Output "Netmask = $netmask"
	Write-Output "Gateway = $gateway"
	Write-Output "DNS = $dns1 $dns2"
	Write-Output "Guest Username = $guestuser"
	Write-Output "Guest Password = $guestpass"
	Write-Output "http_proxy = $http_proxy"
	Write-Output "https_proxy = $https_proxy"
	
	# create a temp file
	$pathfile="/etc/network/tempfile"
	$text1="sudo touch /etc/network/tempfile"
	$text2="sudo chmod 777 /etc/network/tempfile" 
	$interface="sudo cp /etc/network/tempfile /etc/network/interfaces"
	$remove="sudo rm /etc/network/tempfile"
	$toggle="sudo ifdown eth0; ifup eth0"
	
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $text1 -GuestUser $guestuser -GuestPassword $guestpass
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $text2 -GuestUser $guestuser -GuestPassword $guestpass
		
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "echo auto lo >> $pathfile" -GuestUser $guestuser -GuestPassword $guestpass
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "echo iface lo inet loopback >> $pathfile" -GuestUser $guestuser -GuestPassword $guestpass
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "echo  >> $pathfile" -GuestUser $guestuser -GuestPassword $guestpass

	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "echo auto $eth >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo iface $eth inet static >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo address $ip >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo netmask $netmask  >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo gateway $gateway >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo dns-nameservers $dns1 $dns2 >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "echo  >> $pathfile" -GuestUser $guestuser -GuestPassword $guestpass
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo auto eth1 >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo iface eth1 inet static >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo address 0.0.0.0 >> $pathfile” -GuestUser $guestuser -GuestPassword $guestpass 
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $interface -GuestUser $guestuser -GuestPassword $guestpass
	Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $toggle -GuestUser $guestuser -GuestPassword $guestpass
	
	
	if($http_proxy -ne "" -And $https_proxy -ne ""){
		$proxyfile="/etc/environment"
		$text1="sudo cp /etc/environment /etc/dummyfile"
		$text2="sudo chmod 777 /etc/dummyfile"
		$no_proxy="127.0.0.1," + $ip + ",169.254.169.254" 
		$text3="sudo cp /etc/dummyfile /etc/environment"
		$text4="sudo rm /etc/dummyfile"
		$local="sudo /etc/rc.local"
			
		Write-Output ""
		Write-Output "http_proxy = $http_proxy"
		Write-Output "https_proxy = $https_proxy"
		Write-Output "no_proxy = $no_proxy"


		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $text1 -GuestUser $guestuser -GuestPassword $guestpass
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $text2 -GuestUser $guestuser -GuestPassword $guestpass

		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo http_proxy=$http_proxy >> /etc/dummyfile” -GuestUser $guestuser -GuestPassword $guestpass
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo https_proxy=$https_proxy >> /etc/dummyfile” -GuestUser $guestuser -GuestPassword $guestpass
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “echo no_proxy=$no_proxy >> /etc/dummyfile” -GuestUser $guestuser -GuestPassword $guestpass

		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $text3 -GuestUser $guestuser -GuestPassword $guestpass
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $text4 -GuestUser $guestuser -GuestPassword $guestpass
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText $local -GuestUser $guestuser -GuestPassword $guestpass

	} else{
		Write-Output "Https Proxy not enabled"
	}
}

if($vm.powerstate -eq "PoweredOn"){
	Write-Output "Guest VM is PoweredON"
	
	# Check installed VMware Tools inside VM
    $GuestToolsStatus=(Get-View $vm.Id -Property Guest).Guest.ToolsStatus
	
	if($GuestToolsStatus -eq "toolsOK"){
		Write-Output "VMWware Tools is OK"

		# test command
		#Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “pwd” -GuestUser $guestuser -GuestPassword $guestpass -ToolsWaitSecs 30
		#Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “whoami” -GuestUser $guestuser -GuestPassword $guestpass -ToolsWaitSecs 30
		#Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText “pwd” -GuestUser $guestuser -GuestPassword $guestpass -ToolsWaitSecs 30

		# Setting IP/Netmask/GW/DNS for eth0 interface
		#
		setNetworking -ip $cloudn_ip -netmask $cloudn_netmask -gateway $cloudn_gateway -dns1 $cloudn_dns1 -dns2 $cloudn_dns2 -eth $cloudn_interface -guestuser $guestuser -guestpass $guestpass -http_proxy $http_proxy -https_proxy $https_proxy

 	}else{
		Write-Output "vmtoolsd not running, please re-install VMware Tools to guest VM"
		Disconnect-VIServer -confirm:$false -Server $Server
	}
}else{
	Start-VM -VM $vm_name
	sleep 20
	setNetworking -ip $cloudn_ip -netmask $cloudn_netmask -gateway $cloudn_gateway -dns1 $cloudn_dns1 -dns2 $cloudn_dns2 -eth $cloudn_interface -guestuser $guestuser -guestpass $guestpass -http_proxy $http_proxy -https_proxy $https_proxy
}

	Disconnect-VIServer -confirm:$false -Server $Server

