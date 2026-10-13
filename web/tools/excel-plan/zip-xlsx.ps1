param($src, $dst)
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
if (Test-Path $dst) { Remove-Item $dst -Force }
$zip = [System.IO.Compression.ZipFile]::Open($dst, 'Create')
$root = (Resolve-Path $src).Path.TrimEnd('\') + '\'
$files = Get-ChildItem -Path $src -Recurse -File | Sort-Object { if ($_.Name -eq '[Content_Types].xml') { 0 } else { 1 } }, FullName
foreach ($f in $files) {
  $name = $f.FullName.Substring($root.Length).Replace('\', '/')
  [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $f.FullName, $name, 'Optimal') | Out-Null
}
$zip.Dispose()
