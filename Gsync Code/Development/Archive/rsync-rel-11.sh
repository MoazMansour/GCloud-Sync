###############################################################################
# NAME:      rsync-rel-11.sh
# AUTHOR:    Moaz Mansour, Blink
# E-MAIL:    moaz.mansour@blink.la
# DATE:      12/12/2018
# LANG:      Bash Script
#
# This script manages monitoring changes on Google Cloud and updating
# local NAS server accordingly.
#
# VERSION HISTORY:
# 1.0    12/10/2018		  Initial Version
# 1.1    12/12/2018    	Exlcuded rsync
###############################################################################

##############################################################
################## GC-Sync NAS Side Monitor ##################
##############################################################


#! /bin/bash

EVENTS="CREATE,DELETE,MOVED_TO,MOVED_FROM"          #specifying kind of events to be monitored
bucket="gs://rsync-trigger-test/" 						      #Bucket path
g_root="GSync/" 												            #root folder subject to change on the cloud
l_root="/rsync-test/"											          #root folder subject to change on the local server

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
      gsutil -m cp -P dummy "$bucket$g_root$folder$file/.initate"··
      gsutil -m cp -P dummy "$l_root$folder$file/.initate"                                   #creates a dummy file to create a folder on the cloud
    else
      if [[ $event == *"MOVED_TO"* ]]; then
        gsutil -m rsync -r -P "$l_root$folder$file" "$bucket$g_root$folder$file"
      else
        if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then                    #check deleting types of changes
          gsutil -m rm -r "$bucket$g_root$folder$file"                                             #remove folder recersuively from cloud
        fi
      fi
    fi
  else
    #If change was not a directory change the below are the checks run per file change
    if [[ $event == "CREATE" ]] || [[ $event == "MOVED_TO" ]]; then                           #check creation types of changes
      gsutil -m cp -P "$path$file" "$bucket$g_root$folder$file"
    else
      if [[ $event == "DELETE" ]] || [[ $event == "MOVED_FROM" ]]; then                       #check deletion types of changes
        gsutil -m rm "$bucket$g_root$folder$file"                                                #delete only this specific file
      fi
    fi
  fi
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
    run_sync "$path" "$folder" "$event" "$file"                                      #call the sync function
  fi
  else
    if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then                #check if it was a deletion
      run_sync "$path" "$folder" "$event" "$file"&                                    #run the sync function
    fi
  fi
  ######
  ## End of while loop and calling the inotify watch to monitor changes on rsync-test root folder
}
while read -r line
do
  printf "CHANGE LOG: $line\n"                                                       #print recevied message on screen
  callback "$line"&                                                                   #call the callback function
done< <(inotifywait -e "$EVENTS" -m -r --timefmt '%H:%M' --format '%w %T %e %f' "$l_root")

#############################################
