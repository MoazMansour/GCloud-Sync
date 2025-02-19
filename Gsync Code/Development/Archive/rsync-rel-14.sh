###############################################################################
# NAME:      rsync-rel-14.sh
# AUTHOR:    Moaz Mansour, Blink
# E-MAIL:    moaz.mansour@blink.la
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
###############################################################################

##############################################################
################## GC-Sync NAS Side Monitor ##################
##############################################################


#! /bin/bash

EVENTS="CREATE,DELETE,MOVED_TO,MOVED_FROM"          # specifying kind of events to be monitored
bucket="gs://rsync-trigger-test/"         				  # Bucket path
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
  if [[ $event == *"ISDIR"* ]]; then                                                        # check directory change
    if [[ $event == *"CREATE"* ]]; then                                                     # check creating types of changes
      proc_control&
      gsutil -m cp -P dummy "$bucket$g_root$folder$file/.initate"                           # creates a dummy file to create a folder on the cloud
      cp -P dummy "$l_root$folder$file/.initate"
      proc=$(( proc-1 ))
      trap "kill 0" EXIT
    else
      if [[ $event == *"MOVED_TO"* ]]; then
        proc_control&
        gsutil -m rsync -r -P "$l_root$folder$file" "$bucket$g_root$folder$file"&
        proc=$(( proc-1 ))
        trap "kill 0" EXIT
      else
        if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then                # check deleting types of changes
          proc_control&
          echo -e "$(cat $NAS_log)$folder$file| " > $NAS_log
          gsutil -m mv "$bucket$g_root$folder$file" "$bucket$g_trash$g_root$folder$file"&    # remove folder recersuively from cloud
          proc=$(( proc-1 ))
          trap "kill 0" EXIT
        fi
      fi
    fi
  else
    #If change was not a directory change the below are the checks run per file change
    if [[ $event == "CREATE" ]] || [[ $event == "MOVED_TO" ]]; then                           # check creation types of changes
      proc_control&
      gsutil -m cp -P "$path$file" "$bucket$g_root$folder$file"&
      proc=$(( proc-1 ))
      trap "kill 0" EXIT
    else
      if [[ $event == "DELETE" ]] || [[ $event == "MOVED_FROM" ]]; then                       # check deletion types of changes
        proc_control&
        echo -e "$(cat $NAS_log)$folder$file| " > $NAS_log
        gsutil -m mv "$bucket$g_root$folder$file" "$bucket$g_trash$g_root$folder$file"&       # delete only this specific file
        proc=$(( proc-1 ))
        trap "kill 0" EXIT
      fi
    fi
  fi
  proc=$(( proc-1 ))
  trap "kill 0" EXIT
}

#############################################
#The while is to read the output that comes out from the inotifywatch which is monitoring all the above events
# The line is in this format "PATH CHANGE_TIME EVENT_TYPE FILE/FOLDER(OBJECT)"
#read lines recersuively into string variable line
######

function callback() {
  path="$1"                                                                          # Passing on line info to the callback function
  file="$2"
  folder=${path##*"$l_root"}                                                         # Exclduing the root folder "rsync-test" from path for sync purposes
  event="$3"

  #####
  # Check if it was a local or remote change to run sync
  if [[ $event == *"CREATE"* ]] || [[ $event == *"MOVED_TO"* ]]; then                 # check if it was a create to get owner
  uname="$(stat --format '%U' "$path$file")"                                          # extract owner of file
  if [ "${uname}" = "root" ]; then                                                    # if root is owner then change was local
    proc_control&
    run_sync "$path" "$folder" "$event" "$file"&                                      # call the sync function
  fi
  else
    if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then             # check if it was a deletion
      read log_file< <(grep -w "$cloud_log" -e "$folder$file|")                        # check if the deletion was performed by the cloud
      if echo "$log_file" | grep -q "$folder$file|"; then
        printf "\nDeletion performed by GCloud\n\n"
        python replace.py "$cloud_log" "$folder$file|"                                 # removes the file path from the cloud deletion log
      else
        proc_control&
        run_sync "$path" "$folder" "$event" "$file"&                                  # run the sync function
      fi
    fi
  fi
  proc=$(( proc-1 ))
  trap "kill 0" EXIT
  ######
  ## End of while loop and calling the inotify watch to monitor changes on rsync-test root folder
}
while read -r line
do
  [[ $line == *"@Recycle"* ]] && continue                                            # Skip synchronizing @Recycle folder
  [[ $line == *".gstmp"* ]] && continue                                            # Skip synchronizing @Recycle folder
  path=${line%/*}                                                                    # Parsing the path variable from the change message
  path="$path/"
  rest=${line##*/}                                                                   # reading the rest of the message except the path
  read hour date event file <<<"${rest}"                                             # reading the change_time event_type and subjected obiect of change
  [[ $file == "."* ]] && continue                                            # Skip synchronizing hidden files
  printf "CHANGE LOG: $date $hour $event $path$file\n"                               # print recevied message on screen
  proc_control&
  callback "$path" "$file" "$event"&                                                 # call the callback function
done< <(inotifywait -e "$EVENTS" -m -r --timefmt '%H:%M %m-%d-%y' --format '%w %T %e %f' "$l_root")

#############################################
