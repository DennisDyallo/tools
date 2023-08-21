function ConvertAndReplace { 
    Get-ChildItem -Path . -Recurse -File -Include @("*.cs", "*.config", "*.csproj", "*.sln", "*.xaml", "*.aspx", "*.ashx", "*.asmx") | ForEach-Object {
        # Read the file using the default encoding
        $content = Get-Content $_.FullName -Raw
        $content = $content.Replace('Å', '[A]').Replace('å', '[a]').Replace('Ä', '[AE]').Replace('ä', '[ae]').Replace('Ö', '[O]').Replace('ö', '[o]')

        # Write the file with UTF-8 encoding and BOM
        [System.IO.File]::WriteAllLines($_.FullName, $content, [System.Text.Encoding]::UTF8)
    }
}

function RevertAndKeepUTF8 {
    Get-ChildItem -Path . -Recurse -File -Include @("*.cs", "*.config", "*.csproj", "*.sln", "*.xaml", "*.aspx", "*.ashx", "*.asmx") | ForEach-Object {
        # Read the file using UTF-8 encoding
        $content = Get-Content $_.FullName -Raw

        # Replace the placeholders back to their original characters
        $content = $content.Replace('[A]', 'Å').Replace('[a]', 'å').Replace('[AE]', 'Ä').Replace('[ae]', 'ä').Replace('[O]', 'Ö').Replace('[o]', 'ö')

        # Write the file with UTF-8 encoding and BOM
        [System.IO.File]::WriteAllLines($_.FullName, $content, [System.Text.Encoding]::UTF8)
    }
}
