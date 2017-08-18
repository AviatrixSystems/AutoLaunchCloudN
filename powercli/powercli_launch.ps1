param(
    [string]$outDir = $(Split-Path $MyInvocation.MyCommand.Path),	
    [string[]]$esxi_params = @(),
	[string[]]$cloudn_network = @(),
	[string[]]$cloudn_dns = @(),
	[string[]]$cloudn_proxy = @(),
	[string]$vm_name = "",
    [switch]$help = $false,
    [string]$log = ($env:TEMP + "\AutoLaunchCloudN" + $PID + ".log")
)

# Constants
$ScriptName = "powercli_launch"
$ScriptVersion = "1.2.0"
$GitHubURL = "https://github.com/AviatrixSystems/AutoLaunchCloudN"
$esxi_server = ""
$esxi_username = ""
$esxi_password = ""
$guestuser = "admin"
$guestpass ="Aviatrix123#"
$cloudn_ip = ""
$cloudn_netmask = ""
$cloudn_gateway = ""
$http_proxy = ""
$https_proxy = ""
$cloudn_dns1 = ""
$cloudn_dns2 = ""

# Write info and help if requested
write-host ("`nThis is " + $ScriptName + " Version " + $ScriptVersion)
write-host ("`nPlease visit " + $GitHubURL + " for more information.") 
if ($help) {
    write-host "`nUsage:"
    write-host "   powercli_launch [-help] | [-exsi_params [..]] [-cloudn_network [..]] [-cloudn_dns [..]] [-cloudn_proxy [..]] "
    write-host " "
    write-host "`nParameters:"
    write-host "   -help               : display this help"
	write-host "   -exsi_params    [ ] : ESXi host parameters (ip address, username, password)" 
    write-host "   -cloudn_network [ ] : CloudN networking parameters (ip address, network, gateway)"
    write-host "   -cloudn_dns     [ ] : List of domain nameservers (DNS #1 ip address, DSN #2 ip address)"
    write-host "   -cloudn_proxy   [ ] : List of http and https proxy servers [http_proxy, https_proxy]"
    write-host "                         i.e.   -cloudn_proxy (http://10.130.0.15:3128,http://10.130.0.15:3128)"
	write-host "   -vm_name            : virtual machine name deployed by ovftool or vSphere Client"
    write-host "`n"
 
    exit
} else {
    write-host "(Call with -help for instructions)"
    if (!($PSBoundParameters.ContainsKey('log')) -and $PSBoundParameters.ContainsKey('outDir')) {
        write-host ("`nTemporarily logging to " + $log + " ...")
    } else {
        write-host ("`nLogging to " + $log + " ...")
    }
    # Stop active transcript
    try { Stop-Transcript | out-null } catch {}
    # Start own transcript
    try { Start-Transcript -Path $log -Force -Confirm:$false | Out-Null } catch {
        write-host -ForegroundColor Red "`nFATAL ERROR: Log file cannot be opened. Bad file path or missing permission?`n"
        exit
    }
}

	# Parse ESXi host and login credentials
    if ($esxi_params -ne @()) {
        write-host "`nAccessing ESXi host ..."
        for ($i=0; $i -lt $esxi_params.Length; $i++ ) {
		
            if ($ovib = $esxi_params[$i] ) {
                write-host -nonewline "   ESXi param > " $ovib
            } else {
                write-host -ForegroundColor Red "   [ERROR] Cannot access ESXi host " $esxi_params[$i] "!"
            }
        }
		$esxi_server = $esxi_params[0]
		$esxi_username = $esxi_params[1]
		$esxi_password = $esxi_params[2]
		write-host "`n ESXi server" $esxi_server
		write-host "`n ESXi username" $esxi_username
		write-host "`n ESXi password" $esxi_password
		
		Connect-VIServer -Server $esxi_server -Protocol https -User $esxi_username -Password $esxi_password
    }
	# Parse CloudN networking parameters
    if ($cloudn_network -ne @()) {
        write-host "`nCloudN networking parameters ..."
        for ($i=0; $i -lt $cloudn_network.Length; $i++ ) {
            if ($ovib = $cloudn_network[$i] ) {
                write-host -nonewline "   CloudN params > " $ovib
            } else {
                write-host -ForegroundColor Red "   [ERROR] Cannot access CloudN networking params " $cloudn_network[$i] "!"
            }
        }
		$cloudn_ip = $cloudn_network[0]
		$cloudn_netmask = $cloudn_network[1]
        $cloudn_gateway = $cloudn_network[2]
    }
	# Parse CloudN DNS entries
    if ($cloudn_dns -ne @()) {
        write-host "`nCloudN DNS entries ..."
        for ($i=0; $i -lt $cloudn_dns.Length; $i++ ) {
            if ($ovib = $cloudn_dns[$i] ) {
                write-host -nonewline "   CloudN DNS params > " $ovib
            } else {
                write-host -ForegroundColor Red "   [ERROR] Cannot access CloudN DNS params " $cloudn_dns[$i] "!"
            }
        }
		$cloudn_dns1 = $cloudn_dns[0]
		$cloudn_dns2 = $cloudn_dns[1]
    }
	# Parse CloudN Proxy entries
    if ($cloudn_proxy -ne @()) {
        write-host "`nCloudN Proxy entries ..."
        for ($i=0; $i -lt $cloudn_proxy.Length; $i++ ) {
            if ($ovib = $cloudn_proxy[$i] ) {
                write-host -nonewline "   CloudN Proxy params > " $ovib
            } else {
                write-host -ForegroundColor Red "   [ERROR] Cannot CloudN proxy params " $cloudn_proxy[$i] "!"
            }
        }
		$http_proxy = $cloudn_proxy[0]
		$https_proxy = $cloudn_proxy[1]
    } 
	
# function to setup CloudN networking parameters 
function setNetworking ($ip,$netmask,$gateway,$dns1,$dns2,$guestuser,$guestpass,$http_proxy,$https_proxy){

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
	
	# to shorten the actual cloudn command
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
	# to shorten the actual proxy command
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

# check running PowerCLI version
Get-PowerCLIVersion

# VM name assigned for CloudN by user from vSphere Client
$vm = Get-VM $vm_name

if($vm.powerstate -eq "PoweredOn"){
	Write-Host "`nGuest VM is PoweredON" -foreground green
	
	# Check installed VMware Tools inside VM
    $GuestToolsStatus=(Get-View $vm.Id -Property Guest).Guest.ToolsStatus
	
	if($GuestToolsStatus -eq "toolsOK"){
		Write-Host "`nVMWware Tools is OK" -foreground green

		setNetworking -ip $cloudn_ip -netmask $cloudn_netmask -gateway $cloudn_gateway -dns1 $cloudn_dns1 -dns2 $cloudn_dns2 -guestuser $guestuser -guestpass 	$guestpass -http_proxy $http_proxy -https_proxy $https_proxy

 	}else{
		Write-Host "vmtoolsd not running, please re-install VMware Tools to guest VM" -foreground red
		Disconnect-VIServer -confirm:$false -Server $Server
	}
}else{
	Write-Host "`nCloudN VM [$vm_name] was PoweredOff" -foreground red
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

	Disconnect-VIServer -confirm:$false -Server $esxi_server