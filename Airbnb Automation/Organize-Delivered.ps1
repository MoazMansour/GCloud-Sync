$path = "C:\Users\Blink Workstation\Desktop\New folder"
$listings = @()
$folders = @()
$folders = Get-ChildItem -Directory $path -Exclude "Home*"
$listings = Get-ChildItem -Directory $path -Filter "Home*"
ForEach ($list in $listings){
    Write-Host "$($list): " -NoNewline
    Write-Host $list.LastWriteTime
    $pattern = '(\d+/\d+/\d\d\d\d)'
    $check = $list.LastWriteTime -match $pattern
    $mdate = $matches[0]
    $mdate = $mdate-replace "/", "-"

    Write-Host $mdate
}
