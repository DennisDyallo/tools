# Location: C:\Users\Zouz\Documents\Powershell

$env:dev="C:\Users\dendya01\Documents\GitHub"
$env:NPM_TOKEN=""

function SetProxy() {
    netsh winhttp show proxy
    $proxy = "http://proxy.sr.se:8080";

    $env:https_proxy = $proxy;
    $env:http_proxy = $proxy;

    Write-Host "Setting npm proxy: $proxy"
    npm config set https-proxy $proxy;
    npm config set proxy $proxy;

    Write-Host "Setting nvm proxy: $proxy"
    nvm proxy $proxy;

    Write-Host "Setting git proxy: $proxy"
    git config --global http.proxy $proxy;
    git config --global https.proxy $proxy;

    Write-Host "Setting environment https_proxy: $proxy"
    [System.Environment]::SetEnvironmentVariable("https_proxy", $proxy)
    [System.Environment]::SetEnvironmentVariable("HTTPS_PROXY", $proxy)

    Write-Host "Setting environment http_proxy: $proxy"
    [System.Environment]::SetEnvironmentVariable("http_proxy", $proxy)
    [System.Environment]::SetEnvironmentVariable("HTTP_PROXY", $proxy)

    netsh winhttp set proxy proxy-server=$proxy bypass-list="127.0.0.1;localhost;*.sr.se"
}

function UnsetProxy() {
    Clear-Variable $env:https_proxy
    Clear-Variable $env:http_proxy

    npm config delete https-proxy
    npm config delete proxy
    nvm proxy none

    git config --unset --global https.proxy
    git config --unset --global http.proxy 

    netsh winhttp reset proxy
}

function Edit-Profile() {
    code $PROFILE
}

function Edit-Npm() {
    code "C:\Users\Zouz\.npmrc"
}

function Edit-Bash() {
    code "C:\Users\Zouz\.bashrc"
}

function Goto-Dev(){
    Set-Location $env:dev
}

Write-Host "Hello Dennis (from: $PSSCRIPTROOT\$($MyInvocation.Mycommand.Name))"
