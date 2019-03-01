$config_file = "C:\Users\Blink Workstation\Desktop\folders.txt"
Set-Variable -Name "content" -Value (Get-Content -Path $config_file) -Scope Global
ForEach ($line in $content) {
    $target = "C:\Users\Blink Workstation\Desktop\Trulia Delivery\02-08-2019\$($line)\Photo"    
      if (-Not (Test-Path $target -PathType Container)) {
        New-Item -ItemType directory -Path $target
        }
    }


    