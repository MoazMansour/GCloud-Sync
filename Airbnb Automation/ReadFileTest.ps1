$content = Get-Content -Path "C:\Users\Blink Workstation\Desktop\automation\Airbnb Automation\config.txt"
ForEach ($line in $content){
   $var = $line.Split('=')
   New-Variable -Name $var[0] -Value $var[1]
}
Write-Host $csv_path
