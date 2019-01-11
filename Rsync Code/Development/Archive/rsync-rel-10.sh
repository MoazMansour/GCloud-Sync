#! /bin/bash

#specifying kind of events to be monitored
EVENTS="CREATE,DELETE,MOVED_TO,MOVED_FROM"

#The while is to read the output that comes out from the inotifywatch which is monitoring all the above events
# The line is in this format "PATH CHANGE_TIME EVENT_TYPE FILE/FOLDER(OBJECT)"

#read lines recersuively into string variable line
while read -r line
do
   printf "CHANGE LOG: $line\n"  #print recevied message on screen
   path=${line%/*}               #Parsing the path variable from the change message
   path="$path/"
   printf "PATH: $path\n"
   folder=${path##*/rsync-test/}  #Exclduing the root folder "rsync-test" from path for sync purposes
   printf "FOLDER: $folder\n"
   rest=${line##*/}              #reading the rest of the message except the path
   #printf "REST: $rest\n"
   read hour event file <<<"${rest}" #reading the change_time event_type and subjected obiect of change
   ##printf "%s %s %s\n" "HOUR:$hour EVENT:$event FILE:$file"

# If the object changed was a directory then copy a dummy file into the bucket to create the folder
   if [[ $event == *"ISDIR"* ]]; then #check directory change
      #printf "ISDIR Done\n"
      if [[ $event == *"CREATE"* ]] || [[ $event == *"MOVED_TO"* ]]; then #check creating types of changes
         #printf "FOLDER COPY RUN\n"

         #To adapt with the flat nature of the bucket this creates a dummy file to create a folder
         gsutil cp dummy "gs://production-backup-master/GSync Test/$folder$file/.initate"
      else
         if [[ $event == *"DELETE"* ]] || [[ $event == *"MOVED_FROM"* ]]; then #check deleting types of changes
            #printf "FOLDER REOMVE RUN\n"
            gsutil rm -r "gs://production-backup-master/GSync Test/$folder$file" #remove folder recersuively from cloud
         fi
      fi
   else
      #If change was not a directory change the below are the checks run per file change
      if [[ $event == "CREATE" ]] || [[ $event == "MOVED_TO" ]]; then  #check creation types of changes
         #printf "File RSYNC RUN\n"
         #The only instant where rsync is run to capture all the changes on all the files for the specific path
         gsutil -m rsync "$path" "gs://production-backup-master/GSync Test/$folder"
      else
        if [[ $event == "DELETE" ]] || [[ $event == "MOVED_FROM" ]]; then  #check deletion types of changes
           #printf "File DELETE RUN\n"
           gsutil rm "gs://production-backup-master/GSync Test/$folder$file" #delete only this specific file
        fi
      fi
   fi
## End of while loop and calling the inotify watch to monitor changes on rsync-test root folder
done < <(inotifywait -e "$EVENTS" -m -r --timefmt '%H:%M' --format '%w %T %e %f' /rsync-test/)
