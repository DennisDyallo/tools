
# This function loads the environment variables from the .env file in the user's
# home directory. The .env file is a simple text file that contains the environment
# variables in the format: VARIABLE_NAME=VARIABLE_VALUE
# If checked out, add a sym link from the repo to the user's PowerShell User Profile directory (e.g. C:\Users\YourName\Documents\PowerShell)
# With cmd: 
# > mklink %USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 C:\Users\YourName\Documents\tools\USERPROFILE\PowerShell\Microsoft.PowerShell_profile.ps1


function Install-OhMyPosh() {
    $powershellConfigPath = "$env:USERPROFILE\Documents\PowerShell\powershell.json"
    try {
        oh-my-posh --version *>$null
    } catch {
        if (-not $isElevated){
            Write-Host "Installing Oh My Posh requires elevated privileges"
            return
        }

        Write-Output "Installing Oh My Posh..."
        winget install JanDeDobbeleer.OhMyPosh -s winget
        Reload-Path

        Write-Host "Installing fonts"
        oh-my-posh font install
        # You may need to set this font in your settings.json for Powershell (to be scripted in the future)
        
        Write-Host "Installing config"
        Create-OhMyPosh-Config $powershellConfigPath

    } finally {
        oh-my-posh init pwsh --config $powershellConfigPath | Invoke-Expression *>$null
    }
}

function Create-OhMyPosh-Config($powershellConfigPath) {
    Get-OhMyPosh-Json | Out-File -FilePath $powershellConfigPath
}

function Get-OhMyPosh-Json() {
    '{
        "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
        "blocks": [
          {
            "alignment": "left",
            "newline": true,
            "segments": [
              {
                "background": "#d75f00",
                "foreground": "#f2f3f8",
                "properties": {
                  "alpine": "\uf300",
                  "arch": "\uf303",
                  "centos": "\uf304",
                  "debian": "\uf306",
                  "elementary": "\uf309",
                  "fedora": "\uf30a",
                  "gentoo": "\uf30d",
                  "linux": "\ue712",
                  "macos": "\ue711",
                  "manjaro": "\uf312",
                  "mint": "\uf30f",
                  "opensuse": "\uf314",
                  "raspbian": "\uf315",
                  "ubuntu": "\uf31c",
                  "windows": "\ue70f"
                },
                "style": "diamond",
                "leading_diamond": "\u256d\u2500\ue0b2",
                "template": " {{ .Icon }} ",
                "type": "os"
              },
              {
                "background": "#e4e4e4",
                "foreground": "#4e4e4e",
                "style": "powerline",
                "powerline_symbol": "\ue0b0",
                "template": " {{ .UserName }} ",
                "type": "session"
              },
              {
                "background": "#0087af",
                "foreground": "#f2f3f8",
                "properties": {
                  "style": "agnoster_short",
                  "max_depth": 3,
                  "folder_icon": "\u2026",
                  "folder_separator_icon": " <transparent>\ue0b1</> "
                },
                "style": "powerline",
                "powerline_symbol": "\ue0b0",
                "template": " {{ .Path }} ",
                "type": "path"
              },
              {
                "background": "#378504",
                "foreground": "#f2f3f8",
                "background_templates": [
                  "{{ if or (.Working.Changed) (.Staging.Changed) }}#a97400{{ end }}",
                  "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#54433a{{ end }}",
                  "{{ if gt .Ahead 0 }}#744d89{{ end }}",
                  "{{ if gt .Behind 0 }}#744d89{{ end }}"
                ],
                "properties": {
                  "branch_max_length": 25,
                  "fetch_stash_count": true,
                  "fetch_status": true,
                  "branch_icon": "\uf418 ",
                  "branch_identical_icon": "\uf444",
                  "branch_gone_icon": "\ueab8"
                },
                "style": "diamond",
                "leading_diamond": "<transparent,background>\ue0b0</>",
                "template": " {{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} <transparent>\ue0b1</> <#121318>\uf044 {{ .Working.String }}</>{{ end }}{{ if .Staging.Changed }} <transparent>\ue0b1</> <#121318>\uf046 {{ .Staging.String }}</>{{ end }}{{ if gt .StashCount 0 }} <transparent>\ue0b1</> <#121318>\ueb4b {{ .StashCount }}</>{{ end }} ",
                "trailing_diamond": "\ue0b0",
                "type": "git"
              }
            ],
            "type": "prompt"
          },
          {
            "alignment": "right",
            "segments": [
              {
                "background": "#e4e4e4",
                "foreground": "#585858",
                "properties": {
                  "style": "austin",
                  "always_enabled": true
                },
                "invert_powerline": true,
                "style": "powerline",
                "powerline_symbol": "\ue0b2",
                "template": " \ueba2 {{ .FormattedMs }} ",
                "type": "executiontime"
              },
              {
                "background": "#d75f00",
                "foreground": "#f2f3f8",
                "properties": {
                  "time_format": "15:04:05"
                },
                "invert_powerline": true,
                "style": "diamond",
                "template": " \uf073 {{ .CurrentDate | date .Format }} ",
                "trailing_diamond": "\ue0b0",
                "type": "time"
              }
            ],
            "type": "prompt"
          },
          {
            "alignment": "left",
            "newline": true,
            "segments": [
              {
                "foreground": "#d75f00",
                "style": "plain",
                "template": "\u2570\u2500 {{ if .Root }}#{{else}}${{end}}",
                "type": "text"
              }
            ],
            "type": "prompt"
          }
        ],
        "final_space": true,
        "version": 2
      }'
}

function Reload-Path() {
    $Env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")  
}

function Install-WslInterop() {
    if (!(Get-Module -ListAvailable -Name WslInterop)) {
        Write-Host "Installing module WslInterop"
        Install-Module WslInterop
    } else {
        # Write-Host "Module WslInterop already installed"
    }

    #Create a hashtable
    Set-Variable WslDefaultParameterValues @{
        ls = "-AFh --group-directories-first --color=auto"
    } -Scope Global

    Import-WslCommand "apt", "awk", "emacs", "find", "grep", "head", "less", "ls", "man", "sed", "seq", "ssh", "sudo", "tail", "touch", "vim", "cat" 
}

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
    # Write-Host "Setting environment variable $name = $value"
    #[System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::Process)
}

function UnsetVariable($name) {
    # Write-Host "Unsetting environment variable $name"
    #[System.Environment]::SetEnvironmentVariable($name, $null, [System.EnvironmentVariableTarget]::User)
    [System.Environment]::SetEnvironmentVariable($name, $null, [System.EnvironmentVariableTarget]::Process)
}

function SetProxy() {
    SetVariable "http_proxy" $env:PROXY
    SetVariable "https_proxy" $env:PROXY
    SetVariable "no_proxy" $env:NO_PROXY

    npm config set https-proxy $env:PROXY;
    npm config set proxy $env:PROXY;

    if ($env:NVM_HOME -match "nvm") {
        Write-Host "Setting nvm proxy: $env:PROXY"
        nvm proxy $env:PROXY;
    }
    else {}
    
    Write-Host "Setting git proxy: $env:PROXY"
    git config --global http.proxy $env:PROXY;
    git config --global https.proxy $env:PROXY;

    if ($env:ChocolateyLastPathUpdate -match "." -and $isElevated) {
        Write-Host "Setting choco proxy: $env:PROXY"
        choco config set --name proxy --value $env:PROXY 
    }
    else {}

    if ($isElevated) {
        Write-Host "Setting winhttp proxy: $env:PROXY, bypass-list: $env:NO_PROXY"

        netsh winhttp set proxy proxy-server=$env:PROXY bypass-list=$env:NO_PROXY
    }
    else {}

    $dockerSettingsPath = "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    if (Test-Path $dockerSettingsPath) {
        Write-Host "Setting Docker proxy: $env:PROXY at $dockerSettingsPath"
        Write-Host "Setting Docker no_proxy: $env:NO_PROXY at $dockerSettingsPath"
        (Get-Content $dockerSettingsPath -Raw) `
            -replace '("overrideProxyHttps?"):\W?"(.*)",', ('$1: "' + $env:PROXY + '",') `
            -replace '("overrideProxyExclude?"):\W?"(.*)",', ('$1: "' + $env:NO_PROXY + '",') `
            -replace '("proxyHttpMode"):\W?"(.*)",', '$1: "manual",' | Set-Content $dockerSettingsPath
    }
    else {}
}

function UnsetProxy() {
    UnsetVariable "http_proxy"
    UnsetVariable "https_proxy"
    
    Write-Host "Clear npm proxy"
    npm config delete https-proxy
    npm config delete proxy

    if ($env:NVM_HOME -match "nvm") {
        Write-Host "Clear nvm proxy"
        nvm proxy none
    }
    else {}

    Write-Host "Clear git proxy"
    git config --unset --global https.proxy
    git config --unset --global http.proxy 

    if ($env:ChocolateyLastPathUpdate -match "." -and $isElevated) {
        Write-Host "Clear choco proxy"
        choco config unset proxy
    }
    else {}

    if ($isElevated) {
        Write-Host "Clear winhttp proxy"
        netsh winhttp reset proxy
    }
    else {}

    $dockerSettingsPath = "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
    if (Test-Path "$dockerSettingsPath") {
        Write-Host "Clear Docker proxy"
        (Get-Content "$dockerSettingsPath" -Raw) `
            -replace '("overrideProxyHttps?"):\W?"(.*)",', ('$1: "' + '' + '",') `
            -replace '("overrideProxyExclude?"):\W?"(.*)",', ('$1: "' + '' + '",') `
            -replace '("proxyHttpMode"):\W?"(.*)",', '$1: "system",' | Set-Content $dockerSettingsPath
    }
    else {}
}

function Edit-Profile() {
    Write-Host "Trying to open your Powershell profile in VS Code.."
    if ($env:PATH -match "code") {
        code $PROFILE
    }
    else {
        Write-Host "Unable to locate VS Code on your Windows PATH."
    }
}

function Reload-Profile () {
    . $profile
}

function Edit-Npm() {
    code "C:\Users\Zouz\.npmrc"
}

function Edit-Bash() {
    code "C:\Users\Zouz\.bashrc"
}

function Goto-Dev() {
    $env:dev = "$env:USERPROFILE\Documents\GitHub"
    Set-Location $env:dev
}

function Add-DefenderExclusions() {
    if ($isElevated) {
        & $env:USERPROFILE\Documents\PowerShell\defender-exclusions.ps1
    }
    else {
        Write-Host "(Add-DefenderExclusions) This command requires elevated privileges."
    }
}

function Verify-FileHash {
    param(
        [string]$fileName,
        [string]$expectedHash
    )

    $computedHash = (Get-FileHash -Path $fileName -Algorithm SHA256).Hash.ToLower()

    if ($computedHash -eq $expectedHash.ToLower()) {
        Write-Host "The file's hash matches the expected hash. Verification successful."
    } else {
        Write-Host "The file's hash does not match the expected hash. Verification failed."
    }
}

function gs{git status}
function ga{git add .}
function gfa{git fetch --all}

function grman{git rebase -i main}
function grmas{git rebase -i master}
function grdev{git rebase -i develop}

function gitc{ git commit -m @args }
function gac{git add .;git commit -m @args}
function pushmas{git push origin master}
function pushman{git push origin main}
function pushdev{git push origin develop}

function pullman{git pull origin main}
function pullmas{git pull origin main}
function pulldev{git pull origin develop}

function gpu{git pull}
function gpr{git pull --rebase}
function gl{git log}
function glo{git log --oneline}
function gch{git checkout @args}
function gcn{git checkout -b @args}

function gman{git checkout main}
function gmas{git checkout master}
function gdev{git checkout develop}

function gb{git branch @args}
function gs{git status}
function gd{git diff}

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}



$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
$isElevated = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

Load-Vars
$work="$env:USERPROFILE\Documents\Work"
Add-DefenderExclusions
Install-WslInterop
Install-OhMyPosh

Write-Host ''
Write-Host "Hello Dennis (from: $PSSCRIPTROOT\$($MyInvocation.Mycommand.Name))"
Write-Host "Commands:"
Write-Host "Enter 'SetProxy' to set proxy (requires elevated privileges to set all proxies)"
Write-Host "Enter 'UnsetProxy' to unset proxy (requires elevated privileges to unset all proxies)"
Write-Host "Enter 'Edit-Profile' to edit your Powershell profile using VS Code"
Write-Host "Enter 'Reload-Profile' to reload your Powershell profile"
Write-Host "Enter 'Add-DefenderExclusions' to exclude Windows Defender from certain path (requires elevated privileges)"
Write-Host ''
Write-Host ''
