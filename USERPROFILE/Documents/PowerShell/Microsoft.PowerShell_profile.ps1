# Load the .env file and store common variables into environment

Get-Content "$env:USERPROFILE\.env" | ForEach-Object {
    [System.Environment]::SetEnvironmentVariable($_.Split('=')[0], $_.Split('=')[1], [System.EnvironmentVariableTarget]::Process)
}

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
$isElevated = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

function SetProxy() {
    netsh winhttp show proxy

    Write-Host "Setting environment http_proxy: $env:PROXY"
    [System.Environment]::SetEnvironmentVariable("http_proxy", $env:PROXY)
   
    Write-Host "Setting environment https_proxy: $env:PROXY"
    [System.Environment]::SetEnvironmentVariable("https_proxy", $env:PROXY)

    Write-Host "Setting npm proxy: $env:PROXY"
    npm config set https-proxy $env:PROXY;
    npm config set proxy $env:PROXY;

    if($env:NVM_HOME -match "nvm"){
        Write-Host "Setting nvm proxy: $env:PROXY"
        nvm proxy $env:PROXY;
    }
    else{}
    
    Write-Host "Setting git proxy: $env:PROXY"
    git config --global http.proxy $env:PROXY;
    git config --global https.proxy $env:PROXY;

    if($env:ChocolateyLastPathUpdate -match "." -and $isElevated){
        Write-Host "Setting choco proxy: $env:PROXY"
        choco config set --name proxy --value $env:PROXY 
    }
    else{}

    if($isElevated){
        netsh winhttp set proxy proxy-server=$env:PROXY bypass-list=$env:NO_PROXY
    }
    else{}

    if(Test-Path "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"){
        (Get-Content "$env:USERPROFILE\AppData\Roaming\Docker\settings.json" -Raw) -replace '("overrideProxyHttps?"):\W?"(.*)",',('$1: ' + "$env:PROXY") | Set-Content "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    }else{}
}

function UnsetProxy() {
    $env:https_proxy = $null
    $env:http_proxy = $null
    
    Write-Host "Clear npm proxy"
    npm config delete https-proxy
    npm config delete proxy

    if($env:NVM_HOME -match "nvm"){
        Write-Host "Clear nvm proxy"
        nvm proxy none
    }
    else{}

    Write-Host "Clear git proxy"
    git config --unset --global https.proxy
    git config --unset --global http.proxy 

    if($env:ChocolateyLastPathUpdate -match "." -and $isElevated){
        Write-Host "Clear choco proxy"
        choco config unset proxy
    }
    else{}

    if($isElevated){
        Write-Host "Clear winhttp proxy"
        netsh winhttp reset proxy
    }
    else{}

    if(Test-Path "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"){
        Write-Host "Setting Docker Desktop Proxy: $env:PROXY"
        (Get-Content "$env:USERPROFILE\AppData\Roaming\Docker\settings.json" -Raw) -replace '("overrideProxyHttps?"):\W?"(.*)",',('$1: ""') | Set-Content "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    }else{}
}

function Edit-Profile() {
    if($env:PATH -match "code"){
        Write-Host "Opening your Powershell user profile using VS Code...."
        code $PROFILE
    }
    else{
        Write-Host "Unable to locate VS Code on your Windows PATH."
    }
}
$name = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host "Hello $name (from: $PSSCRIPTROOT\$($MyInvocation.Mycommand.Name))"
