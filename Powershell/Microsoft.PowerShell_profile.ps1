# Location: C:\Users\Zouz\Documents\Powershell

Write-Host "Hello Dennis (from: $PSSCRIPTROOT)"


function gits { 
	&"C:\Program Files\Git\cmd\git.exe" status
} 

function gitl { 
	&"C:\Program Files\Git\cmd\git.exe" log $args[0]
} 