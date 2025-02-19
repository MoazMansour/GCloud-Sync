###############################################################################
# NAME:      rsync-rel-14.sh
# AUTHOR:    Moaz Mansour
# E-MAIL:	   moaz.mansour@gmail.com
# DATE:      12/17/2018
# LANG:      Bash Script
#
# This script manages monitoring changes on NAS local servers and updating
# Google Cloud accordingly.
#
# VERSION HISTORY:
# 1.0    12/10/2018		  Initial Version
# 1.1    12/12/2018    	Exlcuded rsync
# 1.2    12/17/2018    	Adding a queue function
# 1.3    12/21/2018    	Moving deleted files to trash
# 1.4    01/14/2019     Adding a deletion log to allow override
# 1.5    01/22/2019     Changing addition logic to allow copy and adding logs
###############################################################################

##############################################################
################## GC-Sync NAS Side Monitor ##################
##############################################################


#! /bin/bash

EVENTS="CREATE,DELETE,MOVED_TO,MOVED_FROM"          # specifying kind of events to be monitored
bucket="gs://rsync-trigger-test/"              				  # Bucket path
g_root="GSync/" 												            # root folder subject to change on the cloud
l_root="/rsync-test/"											          # root folder subject to change on the local server
g_trash="Trash/"                                    # Trash path on the cloud bucket
l_trash="$l_root@Recycle/"                          # Trash path on the local server
proc=0                                              # counter to control number of running procceses
max_proc=7                                          # set max number of allowed proccesses at once
g_del_log="/home/blink/programs/logs/cloud_del"  		# Path to cloud deleting log
l_del_log="/home/blink/programs/logs/NAS_del"  			# Path to NAS deleting log
g_add_log="/home/blink/programs/logs/cloud_add"     # Path to cloud adding log
l_add_log="/home/blink/programs/logs/NAS_add"       # Path to NAS adding log

#############################################
#Queue function
function proc_control {
  proc=$(( proc+1 ))
  if [[ $proc > max_proc ]]; then
    wait
  fi
}

#############################################
#Main synchronization function
function run_sync {
  path="$1"                                         # passing path to the function
  folder="$2"                                       # passing folder to the function
  event="$3"                                        # passing event to the function
  file="$4"                                         # passing file to the function

# If the object changed was a directory then copy a dummy file into the bucket to create the folder
  if [[ $event == *"ISDIR"* ]]; then                                                                               # Check directory change
    if [[ $event == *"CREATE"* ]] || [[ $event == *"MOVED_TO"* ]]; then                                            # Check creating types of changes
      proc_control&                                                                                                # Call the process control function
      echo -e "$(cat $l_add_log)$folder$file/.initate| " > $l_add_log                                              # Write the change to the NAS log
      echo -e "$(cat $g_add_log)$folder$file/.initate| " > $g_add_log                                              # Write the change to the cloud log to avoide overwriting
      gsutil -m cp -P dummy "$bucket$g_root$folder$file/.initate"                                                  # Creates a dummy file to create a folder on the cloud
      printf "[info] Created $bucket$g_root$folder$file/.initate\n"                                                # Log the copy process
      cp -P dummy "$l_root$folder$file/.initate"                                                                   # Copy the initiate file to the local server
      printf "[info] Created $l_root$folder$file/.initate\n"                                                       # Log the copy process
      if [[ $event == *"MOVED_TO"* ]]; then
        printf "[info] Building Sync for $l_root$folder$file and $bucket$g_root$folder$file\n"                     # Log the sync process
        files="$l_root$folder$file/*"                                                                              # Read all files in the folder to be synced
        for f in $files                                                                                            # Loop on the files to avoid overwriting
        do
          new_f=${f##*"$l_root"}                                                                                   # Exclduing the root folder "rsync-test" from path for sync purposes
          printf "[sync-info] Would Copy $f to $bucket$g_root$folder$file\n"                                       # Log the copy process
          echo -e "$(cat $l_add_log)$new_f| " > $l_add_log                                                         # Write the change to the NAS log
        done
        gsutil -m rsync -r "$l_root$folder$file" "$bucket$g_root$folder$file"&                                     # In case it was a moved to (Rename) this sync the whole folder
      fi
      proc=$(( proc-1 ))
      trap "kill 0" EXIT
    else
      if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then                                        # Check deleting types of changes
        proc_control&
        echo -e "$(cat $l_del_log)$folder$file| " > $l_del_log                                                     # Write the delete chane to the NAS log
        printf "[info] Deleted $bucket$g_root$folder$file\n"                                                       # Log the deletion process
        gsutil -m mv "$bucket$g_root$folder$file" "$bucket$g_trash$g_root$folder$file"&                            # Move folder to the trash on the cloud
        proc=$(( proc-1 ))                                                                                         # Once done decrement the proccesses run for the process control
        trap "kill 0" EXIT                                                                                         # Kill the running process (Function)
      fi
    fi
  else
    #If change was not a directory change the below are the checks run per file change
    if [[ $event == "CREATE" ]] || [[ $event == "MOVED_TO" ]]; then                                               # Check creation types of changes
      proc_control&                                                                                               # Call the process control function
      echo -e "$(cat $l_add_log)$folder$file| " > $l_add_log                                                      # Write the change to the local add log
      gsutil -m cp "$path$file" "$bucket$g_root$folder$file"&                                                     # Copies the file to the cloud
      printf "[info] Created $bucket$g_root$folder$file\n"                                                        # Log the copy process
      proc=$(( proc-1 ))                                                                                          # Once done decrement the proccesses run for the process control
      trap "kill 0" EXIT                                                                                          # Kill the running process (Function)
    else
      if [[ $event == "DELETE" ]] || [[ $event == "MOVED_FROM" ]]; then                                           # Check deletion types of changes
        proc_control&                                                                                             # Call the proccess control function
        echo -e "$(cat $l_del_log)$folder$file| " > $l_del_log                                                    # Write the change to the local delete log
        printf "[info] Deleted $bucket$g_root$folder$file\n"                                                      # Log the deletion process
        gsutil -m mv "$bucket$g_root$folder$file" "$bucket$g_trash$g_root$folder$file"&                           # Move this file to the cloud trash
        proc=$(( proc-1 ))                                                                                        # Once done decrement the proccesses run for the process control
        trap "kill 0" EXIT                                                                                        # Kill the running process (Function)
      fi
    fi
  fi
  proc=$(( proc-1 ))                                                                                              # Once done decrement the proccesses run for the process control
  trap "kill 0" EXIT                                                                                              # Kill the running process (Function)
}

#############################################
#The while is to read the output that comes out from the inotifywatch which is monitoring all the above events
# The line is in this format "PATH CHANGE_TIME EVENT_TYPE FILE/FOLDER(OBJECT)"
#read lines recersuively into string variable line
######

function callback() {
  path="$1"                                                                                                       # Passing on line info to the callback function
  file="$2"
  folder=${path##*"$l_root"}                                                                                      # Exclduing the root folder "rsync-test" from path for sync purposes
  event="$3"

  #####
  # Check if it was a local or remote change to run sync
  if [[ $event == *"CREATE"* ]] || [[ $event == *"MOVED_TO"* ]]; then                                              # Check if it was a create to get owner
    log_check="$g_add_log"                                                                                         # Set the log check file as the add log
    read log_file< <(grep -w "$log_check" -e "$folder$file|")                                                      # Check if the action was performed by the cloud
    if echo "$log_file" | grep -q "$folder$file|"; then                                                            # Checks if the change was logged from the cloud side
      printf "[info] $folder$file Created by GCloud No sync needed\n"                                              # Log changes
      python replace.py "$log_check" "$folder$file|"                                                               # Removes the file path from the cloud Add log
    else                                                                                                           # If it wasn't a gcloud change then sync
      proc_control&                                                                                                # Call the process control function
      run_sync "$path" "$folder" "$event" "$file"&                                                                 # Run the sync function
    fi
  else
    if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then                                          # Check if it was a deletion
      log_check="$g_del_log"                                                                                       # Set the log check file as the delete log
      read log_file< <(grep -w "$log_check" -e "$folder$file|")                                                    # Check if the action was performed by the cloud
      if echo "$log_file" | grep -q "$folder$file|"; then                                                          # Checks if the change was logged from the cloud side
        printf "[info] $folder$file deleted by GCloud no sync needed\n"                                            # Log changes
        python replace.py "$log_check" "$folder$file|"                                                             # Removes the file path from the cloud deletion log
      else                                                                                                         # If the change wasn't done by the cloud then sync
        proc_control&                                                                                              # Call the process control function
        run_sync "$path" "$folder" "$event" "$file"&                                                               # Run the sync function
      fi
    fi
  fi
  proc=$(( proc-1 ))                                                                                               # Once done decrement the proccesses run for the process control
  trap "kill 0" EXIT                                                                                               # Kill the running process (Function)
  ######
  ## End of while loop and calling the inotify watch to monitor changes on rsync-test root folder
}
###############################################
## Main Function
while read -r line
do
  [[ $line == *"@Recycle"* ]] && continue                                            # Skip synchronizing @Recycle folder
  [[ $line == *".gstmp"* ]] && continue                                              # Skip synchronizing @Recycle folder
  path=${line%/*}                                                                    # Parsing the path variable from the change message
  path="$path/"
  rest=${line##*/}                                                                   # reading the rest of the message except the path
  read hour date event file <<<"${rest}"                                             # reading the change_time event_type and subjected obiect of change
  [[ $file == "."* ]] && continue                                                    # Skip synchronizing hidden files
  printf "[ CHANGE ]: $date $hour $event $path$file\n"                               # print recevied message on screen
  proc_control&                                                                      # Call the process control function
  callback "$path" "$file" "$event"&                                                 # call the callback function
done< <(inotifywait -e "$EVENTS" -m -r --timefmt '%H:%M %m-%d-%y' --format '%w %T %e %f' "$l_root")  # Activate the watches on the folder

#############################################
