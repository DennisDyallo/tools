#function SetDeviceState([string] $Device, [string] $State){
#	if($Device -eq "lights"){
#		$deviceId = "ACCF2399582A"
#	}
#	elseif ($Device -eq "speakers"){
#		$deviceId = "ACCF2399591C"
#	}
#	else{
#		throw "Invalid device"
#	}
#
#	$postParams = @{toMainPage = "set$State$deviceId"}
#	Invoke-WebRequest -Uri http://localhost:8000/ -Method POST -Body $postParams
#}
#
## Chocolatey profile
#$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
#if (Test-Path($ChocolateyProfile)) {
#  Import-Module "$ChocolateyProfile"
#}


Write-Host "Hello Dennis (from: $PSSCRIPTROOT\$($MyInvocation.Mycommand.Name))"


function gits { 
	&"C:\Program Files\Git\cmd\git.exe" status
} 

function gitl { 
	&"C:\Program Files\Git\cmd\git.exe" log $args[0]
} 


function setProxy() {
	netsh winhttp show proxy
	
	$proxy = "http://proxy.sr.se:8080";

	$env:https_proxy = $proxy;
	$env:http_proxy = $proxy;

	Write-Host "Setting npm proxy: $proxy"
	npm config set https-proxy $proxy;
	npm config set proxy $proxy;
	
	Write-Host "Setting git proxy: $proxy"
	git config --global http.proxy $proxy;
	git config --global https.proxy $proxy;

	Write-Host "Setting environment https_proxy: $proxy"
	[System.Environment]::SetEnvironmentVariable("https_proxy", $proxy)
	Write-Host "Setting environment http_proxy: $proxy"
	[System.Environment]::SetEnvironmentVariable("http_proxy", $proxy)

	netsh winhttp set proxy proxy-server=$proxy bypass-list="127.0.0.1;localhost;*.sr.se"
}

function unsetProxy() {
	Clear-Variable $env:https_proxy
	Clear-Variable $env:http_proxy

	Clear-Variable $https_proxy
	Clear-Variable $http_proxy

	npm config delete https-proxy
	npm config delete proxy

	git config delete https.proxy
	git config delete http.proxy

	netsh winhttp reset proxy
}

function editProfile() {
	code $env:profile
}

function editNpm() {
	code "C:\Users\Zouz\.npmrc"
}

function editBash() {
	code "C:\Users\Zouz\.bashrc"
}

#&"C:\Program Files\Git\cmd\git.exe" status 
[System.Environment]::SetEnvironmentVariable("profile", "C:\Users\Zouz\Documents\PowerShell\profile.ps1")
[System.Environment]::SetEnvironmentVariable("planera", "C:\Dev\JOBB\WORK-PROJECTS\planera\")
[System.Environment]::SetEnvironmentVariable("dev", "C:\Dev\JOBB\WORK-PROJECTS\")