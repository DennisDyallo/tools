# Function to create symbolic links between everything in the PSSCRIPTROOT and the USERPROFILE\Documents\PowerShell folder
# Run with: 
# & Create-SymLinks.ps1
function Create-SymLinks() {
    $path = "$env:USERPROFILE\Documents\PowerShell"
    $root = "$PSScriptRoot"
    $files = Get-ChildItem -Path $root -Recurse -Exclude "Create-SymLinks.ps1" | Where-Object { !$_.PSIsContainer }

    foreach ($file in $files) {
        $relativePath = Resolve-Path -Path $file -Relative
        $targetPath = Join-Path -Path $path -ChildPath $relativePath
        if (!(Test-Path -Path $targetPath)) {
            New-Item -Path $targetPath -ItemType SymbolicLink -Value $file.FullName
        }
    }
}

Create-SymLinks