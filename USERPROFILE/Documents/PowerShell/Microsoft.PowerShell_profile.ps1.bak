
# This function loads the environment variables from the .env file in the user's
# home directory. The .env file is a simple text file that contains the environment
# variables in the format: VARIABLE_NAME=VARIABLE_VALUE
function Load-Vars() {
    Write-Host "Loading environment variables from $env:USERPROFILE\.env"
    $variablesArray = @()
    Get-Content "$env:USERPROFILE\.env" | ForEach-Object {
        $name = $_.Split('=')[0]
        $value = $_.Split('=')[1]
        $variablesArray += $name

        SetVariable $name $value
    }

    SetWslEnv $variablesArray
}

# This function sets the WSL environment variable WSLENV to include the variables
# that are set in the .env file. This is necessary to make the variables available
# in WSL. The WSLEnv variable is a list of environment variables that should be
# exported to WSL. The format is a colon-separated list of environment variable
# names. The variable names are case-sensitive. The special value /p indicates
# that all environment variables should be exported to WSL. The special value
# /p:WSLENV indicates that the WSLENV variable should be exported to WSL.
# See https://learn.microsoft.com/en-us/windows/wsl/filesystems#share-environment-variables-between-windows-and-wsl-with-wslenv
# NOTE: Will not translate variables such as Windows paths into Unix paths. 
# This code can be fixed to include the different flags (/u, /p, etc)
# to allow for translation, as described in the above article 
function SetWslEnv($variablesArray) {
    $wslEnv = [System.Environment]::GetEnvironmentVariable("WSLENV")
    if ($wslEnv -match "SR_SETTINGS") {
        Write-Host "WSLENV already contains SR settings"
        return
    }

    foreach ($item in $variablesArray) {
        $concatenatedVars += $item + ":"
    }
    $concatenatedVars = $concatenatedVars.TrimEnd(':')
    $fullWslEnvString = ([string]::IsNullOrEmpty($wslEnv) `
            ? "SR_SETTINGS:" + $concatenatedVars `
            : $wslEnv[-1] -eq ":" `
                ? $wslEnv + "SR_SETTINGS" + $concatenatedVars ` # If last char is ":" then don't add ":" before appending
                : $wslEnv + ":SR_SETTINGS" + $concatenatedVars) # If last char is not ":" then add ":" before appending

    SetVariable "WSLENV" $fullWslEnvString
}


function SetVariable($name, $value) {
    Write-Host "Setting environment variable $name = $value"
    [System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::Process)
}

function UnsetVariable($name) {
    Write-Host "Unsetting environment variable $name"
    [System.Environment]::SetEnvironmentVariable($name, $null, [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable($name, $null, [System.EnvironmentVariableTarget]::Process)
}

function SetProxy() {
    SetVariable "http_proxy" $env:PROXY
    SetVariable "https_proxy" $env:PROXY
    SetVariable "no_proxy" $env:NO_PROXY

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

    $dockerSettingsPath = "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    if(Test-Path $dockerSettingsPath){
        Write-Host "Setting Docker proxy: $env:PROXY at $dockerSettingsPath"
        (Get-Content $dockerSettingsPath -Raw) `
            -replace '("overrideProxyHttps?"):\W?"(.*)",',('$1: "' + $env:PROXY + '",') `
            -replace '("overrideProxyExclude?"):\W?"(.*)",',('$1: "' + $env:NO_PROXY + '",') `
            -replace '("proxyHttpMode"):\W?"(.*)",', '$1: "manual",' | Set-Content $dockerSettingsPath
    }else{}
}

function UnsetProxy() {
    UnsetVariable "http_proxy"
    UnsetVariable "https_proxy"
    
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

    $dockerSettingsPath = "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    if(Test-Path "$dockerSettingsPath"){
        Write-Host "Clear Docker proxy"
        (Get-Content "$dockerSettingsPath" -Raw) `
            -replace '("overrideProxyHttps?"):\W?"(.*)",',('$1: "' + '' + '",') `
            -replace '("overrideProxyExclude?"):\W?"(.*)",',('$1: "' + '' + '",') `
            -replace '("proxyHttpMode"):\W?"(.*)",', '$1: "system",'| Set-Content $dockerSettingsPath
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

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
$isElevated = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

Load-Vars

$name = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
Write-Host ''
Write-Host "Hello $name (from: $PSSCRIPTROOT\$($MyInvocation.Mycommand.Name))"
Write-Host "Commands:"
Write-Host "Enter 'SetProxy' to set proxy (requires elevated privileges)"
Write-Host "Enter 'UnsetProxy' to unset proxy (requires elevated privileges)"
Write-Host "Enter 'Edit-Profile' to edit your Powershell profile using VS Code"
Write-Host "Enter 'Reload-Profile' to reload your Powershell profile (if you've made changes)"
Write-Host ''
