
#Folders paths parameters
$Main_path = "C:\Users\Blink Workstation 5\Desktop\test\"
$Index_txt = "C:\Users\Blink Workstation 5\Desktop\test\test.txt"
$total_count = "test_count.txt"

#Clear file and add new header
Set-Content -Path $Index_txt -Value ">>>Test Folder Subdirectory Files Count<<< `r`n"
Add-Content -Path $Index_txt -Value ">>>Total Number of Folders:"

#Count number of folders
Get-ChildItem -Directory $Main_path | Measure-Object | %{$_.Count} | Add-Content $Index_txt

#Add some space
Add-Content -Path $Index_txt -Value "`r"

#Get a list of all the folders in this directory
$folders = Get-ChildItem -Directory $Main_path

#Print out file names & Number of files in each folder
Foreach ($folder in $folders) {
	Add-Content -Path $Index_txt -Value $folder.name
	$exclude = 'test_count'
	Get-ChildItem -File $Main_Path$folder/* -exclude *.txt | Measure-Object | %{$_.Count} | Add-Content $Index_txt
	Get-ChildItem -File $Main_Path$folder/* -exclude *.txt | Measure-Object | %{$_.Count} | Set-Content $Main_Path$folder/$total_count
}

#Add some space
Add-Content -Path $Index_txt -Value "`r"

#Adding Timestamp
Add-Content -Path $Index_txt -Value ">>>>End of file :)"
