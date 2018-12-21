###############################################################################
# NAME:      rsync-rel-12.sh
# AUTHOR:    Moaz Mansour, Blink
# E-MAIL:    moaz.mansour@blink.la
# DATE:      12/17/2018
# LANG:      Bash Script
#
# This script manages monitoring changes on Google Cloud and updating
# local NAS server accordingly
#
# VERSION HISTORY:
# 1.0    12/10/2018		  Initial Version
# 1.1    12/12/2018    	Exlcuded rsync
# 1.2    12/17/2018    	Adding a queue function
# 1.3    12/21/2018    	Moving deleted files to trash
###############################################################################

##############################################################
################## GC-Sync NAS Side Monitor ##################
##############################################################


#! /bin/bash

EVENTS="CREATE,DELETE,MOVED_TO,MOVED_FROM"          #specifying kind of events to be monitored
bucket="gs://dam-staging/"         						      #Bucket path
g_root="Post-Production/" 												  #root folder subject to change on the cloud
l_root="/dam-postproduction/"											  #root folder subject to change on the local server
g_trash="Trash/"                                    #Trash path on the cloud bucket
l_trash="$l_root@Recycle/"                          #Trash path on the local server
proc=0                                              #counter to control number of running procceses
max_proc=7                                          #set max number of allowed proccesses at once

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
  path="$1"                                         #passing path to the function
  folder="$2"                                       #passing folder to the function
  event="$3"                                        #passing event to the function
  file="$4"                                         #passing file to the function

# If the object changed was a directory then copy a dummy file into the bucket to create the folder
  if [[ $event == *"ISDIR"* ]]; then                                                          #check directory change
    if [[ $event == *"CREATE"* ]]; then                       #check creating types of changes
      proc_control&
      gsutil -m cp -P dummy "$bucket$g_root$folder$file/.initate"
      gsutil -m cp -P dummy "$l_root$folder$file/.initate"                                   #creates a dummy file to create a folder on the cloud
      proc=$(( proc-1 ))
      trap "kill 0" EXIT
    else
      if [[ $event == *"MOVED_TO"* ]]; then
        proc_control&
        gsutil -m rsync -r -P "$l_root$folder$file" "$bucket$g_root$folder$file"&
        proc=$(( proc-1 ))
        trap "kill 0" EXIT
      else
        if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then                    #check deleting types of changes
          proc_control&
          gsutil -m mv "$bucket$g_root$folder$file" "$bucket$g_trash$folder$file"&                                             #remove folder recersuively from cloud
          proc=$(( proc-1 ))
          trap "kill 0" EXIT
        fi
      fi
    fi
  else
    #If change was not a directory change the below are the checks run per file change
    if [[ $event == "CREATE" ]] || [[ $event == "MOVED_TO" ]]; then                           #check creation types of changes
      proc_control&
      gsutil -m cp -P "$path$file" "$bucket$g_root$folder$file"&
      proc=$(( proc-1 ))
      trap "kill 0" EXIT
    else
      if [[ $event == "DELETE" ]] || [[ $event == "MOVED_FROM" ]]; then                       #check deletion types of changes
        proc_control&
        gsutil -m mv "$bucket$g_root$folder$file" "$bucket$g_trash$folder$file"&                                                #delete only this specific file
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
  line="$1"                                                                          #Passing on line info to the callback function
  path=${line%/*}                                                                    #Parsing the path variable from the change message
  path="$path/"
  folder=${path##*"$l_root"}                                                         #Exclduing the root folder "rsync-test" from path for sync purposes
  rest=${line##*/}                                                                   #reading the rest of the message except the path
  read hour event file <<<"${rest}"                                                  #reading the change_time event_type and subjected obiect of change

  #####
  # Check if it was a local or remote change to run sync
  if [[ $event == *"CREATE"* ]] || [[ $event == *"MOVED_TO"* ]]; then                 #check if it was a create to get owner
  uname="$(stat --format '%U' "$path$file")"                                         #extract owner of file
  if [ "${uname}" = "root" ]; then                                                   #if root is owner then change was local
    proc_control&
    run_sync "$path" "$folder" "$event" "$file"&                                     #call the sync function
  fi
  else
    if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then                #check if it was a deletion
      proc_control&
      run_sync "$path" "$folder" "$event" "$file"&                                    #run the sync function
    fi
  fi
  proc=$(( proc-1 ))
  trap "kill 0" EXIT
  ######
  ## End of while loop and calling the inotify watch to monitor changes on rsync-test root folder
}
while read -r line
do
  printf "CHANGE LOG: $line\n"                                                       #print recevied message on screen
  proc_control&
  callback "$line"&                                                                  #call the callback function
done< <(inotifywait -e "$EVENTS" -m -r --timefmt '%H:%M' --format '%w %T %e %f' "$l_root")

#############################################
