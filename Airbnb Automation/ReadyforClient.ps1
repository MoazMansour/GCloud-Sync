
#Folders paths parameters
$csv_path = "C:\Users\Blink Workstation\Downloads\photo_sets.csv"
$Index_txt = "C:\Users\Blink Workstation\Downloads\DeliveryCheck.txt"
$client_path = "Z:\06 - Ready for Client"

#initate a list for photosets
$SetID = @()
$FileNames = @()

#read Set Ids from the CSV file
Import-Csv $csv_path |`
    ForEach-Object {
        $SetID += $_."Photo set ID"
    }

#Clear file and add new header
Set-Content -Path $Index_txt -Value ">>>Delivery Check Sheet<<< `r`n"
Add-Content -Path $Index_txt -Value ">Total Number of Folders:"

#Count number of folders
Get-ChildItem -Directory $client_path | Measure-Object | %{$_.Count} | Add-Content $Index_txt

#Add some space
Add-Content -Path $Index_txt -Value "`r"

#Count number of sets on the CS
Add-Content -Path $Index_txt -Value ">Total Number of Reported Asets:"
$SetID | Measure-Object | %{$_.Count} | Add-Content $Index_txt

Add-Content -Path $Index_txt -Value "`r"
Add-Content -Path $Index_txt -Value ">Missing SetIDs from CS:"

#Get a list of all the folders in this directory
$folders = Get-ChildItem -Directory $client_path
$pattern = '(\d+)' #match a number pattern

Foreach ($folder in $folders) {
    $check = $folder -match $pattern
    $name = $matches[0]
    $FileNames += $name
}

#Check that all folder ids exist in the SetIds
Foreach ($id in $FileNames) {
    if (-Not ($SetID -like "$id*")) {
        $id | Add-Content $Index_txt
    }
}

$inputNumber = Read-Host -Prompt "SetID"

if ($SetID -like "$inputNumber*")
    {
    Write-Host "True!"
    } 
    else { Write-Host "False" }