<# .SYNOPSIS
	Script will set IP address, gateway, netmask and dns nameservers in eth0
	
.DESCRIPTION
	Script is using get-VM PowerCLI cmdlet to set guest VM parameters. This assumes an Ubuntu linux VM. 
	
.PARAMETER 
	Mandatory parameter of vSphere/ESXi host, username and password
	
.EXAMPLE
	.\powercli_launch.ps1 -Server 10.130.0.2 -User username1 -Password password #>
	
	
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
#$http_proxy = ""
#$https_proxy = ""

# proxy settings enabled
$http_proxy = "http://10.130.0.15:3128"
$https_proxy = "http://10.130.0.15:3128"

# check running PowerCLI version
Get-PowerCLIVersion

# VM name assigned for CloudN by user from vSphere Client
$vm_name = "My-CloudN"
$vm = Get-VM $vm_name


Function setNetworking ($ip,$netmask,$gateway,$dns1,$dns2,$guestuser,$guestpass,$http_proxy,$https_proxy){

    Write-Host "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv" -foreground cyan
	Write-Host "IP address = $ip" 
	Write-Host "Netmask = $netmask"
	Write-Host "Gateway = $gateway"
	Write-Host "DNS = $dns1 $dns2"
	Write-Host "Guest Username = $guestuser"
	Write-Host "Guest Password = $guestpass"
	Write-Host "http_proxy = $http_proxy"
	Write-Host "https_proxy = $https_proxy"
	Write-Host "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv" -foreground cyan
	Write-Host
	Sleep 5
	
	$path="export LD_LIBRARY_PATH=/usr/local/lib; export CLISH_PATH=/etc/cloudx; clish -c"
	
	$setup = @{
		Ip = $ip
		Netmask = $netmask
		Gateway = $gateway
		DNS1 = $dns1
		DNS2 = $dns2
		Proxy_False = "proxy false"
		Proxy_True = "proxy true"
		Command = "setup_interface_static_address"
		Path = $path
	}
	$proxy = @{
		https = $https_proxy
		http = $http_proxy
		command = "setup_network_proxy"
		test = "test"
		save = "save"
	}	
	
	$setup_static_ip="$($setup.command) $($setup.Ip) $($setup.Netmask) $($setup.Gateway) $($setup.DNS1) $($setup.DNS2)" 
	$setup_proxy="$($setup.Path) $($proxy.command) $($proxy.action) $($proxy.http_proxy) $($proxy.https_proxy)"
		
	if($http_proxy -ne "" -And $https_proxy -ne ""){
		
		Write-Host "Setting IP address with proxy enabled" -foreground yellow
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "$($setup.Path) '$setup_static_ip $($setup.Proxy_True)'" -GuestUser $guestuser -GuestPassword $guestpass 
		
		Write-Host "Check Aviatrix CloudN assigned ip address" -foreground yellow
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "$($setup.Path) 'show_interface_address'" -GuestUser $guestuser -GuestPassword $guestpass
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "$($setup.Path) 'test_internet_connection'" -GuestUser $guestuser -GuestPassword $guestpass
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "$($setup.Path) '$($proxy.command) $($proxy.test) --http_proxy $($proxy.http) --https_proxy $($proxy.https)'" -GuestUser $guestuser -GuestPassword $guestpass
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "$($setup.Path) '$($proxy.command) $($proxy.save) --http_proxy $($proxy.http) --https_proxy $($proxy.https)'" -GuestUser $guestuser -GuestPassword $guestpass

	} else{
		
		Write-Host "Setting IP address with no proxy" -foreground cyan
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "$($setup.Path) '$setup_static_ip $($setup.Proxy_False)'" -GuestUser $guestuser -GuestPassword $guestpass 
		
		
		Invoke-VMScript -VM $vm -ScriptType Bash -ScriptText "$($setup.Path) show_interface_address" -GuestUser $guestuser -GuestPassword $guestpass
	}
}

if($vm.powerstate -eq "PoweredOn"){
	Write-Host "Guest VM is PoweredON" -foreground green
	
	# Check installed VMware Tools inside VM
    $GuestToolsStatus=(Get-View $vm.Id -Property Guest).Guest.ToolsStatus
	
	if($GuestToolsStatus -eq "toolsOK"){
		Write-Host "VMWware Tools is OK" -foreground green

		setNetworking -ip $cloudn_ip -netmask $cloudn_netmask -gateway $cloudn_gateway -dns1 $cloudn_dns1 -dns2 $cloudn_dns2 -guestuser $guestuser -guestpass 	$guestpass -http_proxy $http_proxy -https_proxy $https_proxy

 	}else{
		Write-Host "vmtoolsd not running, please re-install VMware Tools to guest VM" -foreground red
		Disconnect-VIServer -confirm:$false -Server $Server
	}
}else{
	Write-Host "CloudN VM [$vm_name] was PoweredOff" -foreground red
	Start-VM -VM $vm_name 
	Write-Host "Powering ON and waiting 180sec for OS kernel to come up" -foreground cyan
	Sleep 180
	# Check installed VMware Tools inside VM
    $GuestToolsStatus=(Get-View $vm.Id -Property Guest).Guest.ToolsStatus
	
	if($GuestToolsStatus -eq "toolsOK"){
		Write-Host "VMWware Tools is OK" -foreground green
		setNetworking -ip $cloudn_ip -netmask $cloudn_netmask -gateway $cloudn_gateway -dns1 $cloudn_dns1 -dns2 $cloudn_dns2 -guestuser $guestuser -guestpass 	$guestpass -http_proxy $http_proxy -https_proxy $https_proxy
	}else{
		Write-Host "vmtoolsd not running, please re-install VMware Tools to guest VM" -foreground red
		Disconnect-VIServer -confirm:$false -Server $Server
	}
}

	Disconnect-VIServer -confirm:$false -Server $Server

