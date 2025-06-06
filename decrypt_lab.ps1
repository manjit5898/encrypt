$targetFolder = "C:\Users\LabUser\Desktop\testfolder"
$keyPath = "$env:APPDATA\labkey.txt"
$encExt = ".locked"

if (-not (Test-Path $keyPath)) {
    Write-Host "[✘] Key file not found. Cannot decrypt."
    exit
}
$key = Get-Content $keyPath

$Aes = New-Object System.Security.Cryptography.AesManaged
$Aes.Key = [Convert]::FromBase64String($key)
$Aes.Mode = "CBC"
$Aes.Padding = "PKCS7"

function Decrypt-File {
    param([string]$path)
    $bytes = [IO.File]::ReadAllBytes($path)
    $iv = $bytes[0..15]
    $data = $bytes[16..($bytes.Length - 1)]
    $Aes.IV = $iv
    $transform = $Aes.CreateDecryptor()
    try {
        $output = $transform.TransformFinalBlock($data, 0, $data.Length)
        $originalPath = $path -replace [regex]::Escape($encExt), ""
        [IO.File]::WriteAllBytes($originalPath, $output)
        Remove-Item $path
        Write-Host "[-] Decrypted: $originalPath"
    } catch {
        Write-Host "[!] Failed to decrypt: $path"
    }
}

Get-ChildItem -Recurse $targetFolder -File | Where-Object {
    $_.Extension -eq $encExt
} | ForEach-Object {
    Decrypt-File $_.FullName
}
