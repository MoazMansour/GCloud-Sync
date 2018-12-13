
#Folders paths parameters
$Main_path = "X:\Concierge\Production\Airbnb\Plus\00 - DARYL Pull\Upload\"
$Index_txt = "X:\Concierge\Production\Airbnb\Plus\00 - DARYL Pull\Upload\File Count List.txt"
$total_count = "total.txt"

#Clear file and add new header
Set-Content -Path $Index_txt -Value ">>>Cheat Sheet Upload Index File<<< `r`n"
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
	Get-ChildItem -File $Main_Path$folder/* -exclude *.txt | Measure-Object | %{$_.Count} | Add-Content $Index_txt

	#Check inside each folder if primary and vertical files exist by counting the files with this abberivation
	$primary_check = Get-ChildItem -File $Main_Path$folder/* -filter "*_primary_0_0*" | Measure-Object | %{$_.Count}
	$vertical_check = Get-ChildItem -File $Main_Path$folder/* -filter "*_vertical_0_0*" | Measure-Object | %{$_.Count}

	#Runs the if statement to check primary file count and print out results in the cheat sheet
	Add-Content -Path $Index_txt -Value "Primary Check:"
		If ($primary_check -eq 1) {
			Add-Content -Path $Index_txt -Value "OK"
		} Else {
			Add-Content -Path $Index_txt -Value "Error"
		}
	#Runs the if statement to check vertical file count and print out results in the cheat sheet
		Add-Content -Path $Index_txt -Value "Vertical Check:"
			If ($vertical_check -eq 1) {
				Add-Content -Path $Index_txt -Value "OK"
			} Else {
				Add-Content -Path $Index_txt -Value "Error"
			}

	Add-Content -Path $Index_txt -Value "`r"
	Get-ChildItem -File $Main_Path$folder/* -exclude *.txt | Measure-Object | %{$_.Count} | Set-Content $Main_Path$folder/$total_count
}

#Add some space
Add-Content -Path $Index_txt -Value "`r"

#Adding Timestamp
Add-Content -Path $Index_txt -Value ">>>>End of file :)"
