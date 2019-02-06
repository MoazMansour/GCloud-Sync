###############################################################################
# NAME:      pull-rel-14.py
# AUTHOR:    Moaz Mansour, Blink
# E-MAIL:	 moaz.mansour@blink.la
# DATE:      12/17/2018
# LANG:		 Python 2.7
#
# This script manages monitoring changes on Google Cloud and updating
# local NAS server accordingly.
#
# VERSION HISTORY:
# 1.0    12/05/2018		Initial Version
# 1.1    12/12/2018    	Exlcuded rsync
# 1.2    12/17/2018    	Integrated flow control
# 1.3    12/21/2018    	Moving deleted files to trash
# 1.4    01/14/2019     Adding a deletion log to allow override
# 1.5    01/22/2019     Changing addition logic to allow copy and adding logs
# 1.6	 01/22/2019		Disable delete (Transation version)
# 1.7	 01/23/2019		Enable Move
###############################################################################

##############################################################
################# GC-Sync Google Side Monitor ################
##############################################################


import time
from subprocess import call                                                                     # import subprocess library to run bash commands in script
from subprocess import check_output
from google.cloud import pubsub_v1
import logging
import os


####### Information to be changed based on the type of service and bucket used ####
project_id = "production-backup-194719"                                                         # The project I am assigned to on Gcloud
subscription_name = "IngestSub"		                 		                                        # Pull subscription channel created to pull all object changes messages
bucket = "gs://dam-production/"                                                             # Bucket path
g_root = "Ingest/"		                                	                                    # root folder subject to change on the cloud
l_root = "/dam-ingest/"		                                  	                                # root folder subject to change on the local server
g_trash= "Trash/"                                                                               # Trash path on the cloud bucket
l_trash= l_root+"@Recycle/" 	                                                                # Trash path on the local server
max_proc = 10                  	                                                                # setting maximum number of messages to be processed
g_add_log = "/home/blink/programs/logs/cloud_add"  												# Path to cloud addition log
l_add_log = "/home/blink/programs/logs/NAS_add" 												# Path to NAS addition log
g_del_log = "/home/blink/programs/logs/cloud_del"  												# Path to cloud deleting log
l_del_log = "/home/blink/programs/logs/NAS_del" 												# Path to NAS deleting log
#gsync_log = "/home/blink/programs/logs/gsync-log.txt"											# Path to the main log file

subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(project_id, subscription_name)

###############################################
#Change log file
def gsync_log_fn():
	current_date = time.strftime("%m-%d-%Y")
	gsync_log = "/home/blink/programs/logs/gsync/gsync-log("+current_date+")"
	if not (os.path.isfile(gsync_log)):
		call(["touch",gsync_log])
	return gsync_log

###############################################
#Check owner function
def check_owner(change_type,change_item):
	if (change_type == "MOVE"):                                                                       # If it was a delete set the log file on the NAS deletion log
		log_check = l_del_log
	elif (change_type == "CREATE"):                                                                     # Otherwise set the log file on the NAS creation
		log_check = l_add_log
	f = open(log_check,"r")                                                					   			# Open and reads the NAS log file
	change_check = f.read()
	f.close()
	if (change_check.find(change_item+"|") != -1):                              						# Check if the changed object was logged by NAS
		output = open(gsync_log_fn,"a")
		timestamp = time.strftime("%m-%d-%Y %H:%M:%S")
		output.write("[info] "+timestamp+" "+change_type+" of "+change_item+" was perfromed by NAS, No sync required\n")
		change_check = change_check.replace(change_item+"|"," ")                                		# Removes the record from the log file
		f = open(log_check,"w")
		f.write(change_check)
		f.close()
		return False                                                         				   			# Return false to indidcate that no sync needed
	else:
		return True                                                        				   				# Return true to indicate that sync is required

###############################################
#Write log function
def log_change(change_type,change_item):
	if (change_type == "MOVE"):
		log_check = g_del_log
	if (change_type == "CREATE"):
		log_check = g_add_log
	elif (change_type == "LOCAL"):
		log_check = l_add_log
	f = open(log_check,"a")
	f.write(change_item+"| ")
	f.close()

###############################################
#New directory creaion function
def create_dir(new_dir):
	log_change("CREATE",new_dir)                        	                                       			# Log the folder change to the cloud add log
	call(["mkdir","-p",l_root+new_dir])                     	                                   			# assures that the target directory (full path) exists on NAS
	output = open(gsync_log_fn,"a")
	timestamp = time.strftime("%m-%d-%Y %H:%M:%S")
	output.write("[info] " + timestamp + " Created "+l_root+new_dir+"\n")				                                            # Log changes
	log_change("CREATE",new_dir+"/.initiate") 	      	                                                    # Log the initiate file change to the cloud add log
	log_change("LOCAL",new_dir+"/.initiate")    	                                                        # Log the initiate file change to the cloud add log
	call(["cp","-P","dummy",l_root+new_dir+"/.initiate"])      	                                			# copies the initiate file to the newly created directory
	call(["gsutil","-m","cp","-P","dummy",bucket+g_root+new_dir+"/.initiate"])                  			# copies the initiate file to the newly created directory
	output = open(gsync_log_fn,"a")
	timestamp = time.strftime("%m-%d-%Y %H:%M:%S")
	output.write("[info] "+ timestamp + " Created "+l_root+new_dir+"/initiate\n")				                                    # Log changes
	output = open(gsync_log_fn,"a")
	timestamp = time.strftime("%m-%d-%Y %H:%M:%S")
	output.write("[info] " + timestamp + " Created "+bucket+g_root+new_dir+"/initiate\n")				                                # Log changes

###############################################
#Main synchronization function
def run_sync(path,dir,event,file):
### Check the type of change and act upon it
	if file:
		if event == "OBJECT_FINALIZE":                                                                	# if file has been created or modified                                                                                      	# Checks if the action was taken on a file object (which is mostly the case with gcloud)
			log_change("CREATE",path+file)                                                              # Log the file change to the cloud add log
			if not (os.path.isdir(l_root+dir)):                                                         # Check if the full target directory exists
				create_dir(dir)                                                                         # call the create directory function
			call(["gsutil","-m","cp",bucket+g_root+path+file,l_root+path+file])                         # copies the changed/created file to its destination on NAS
			output = open(gsync_log_fn,"a")
			timestamp = time.strftime("%m-%d-%Y %H:%M:%S")
			output.write("[info] " + timestamp + " Created "+l_root+path+file+"\n")			     	                            # Log changes

###
	# else:
	# 	if event == "OBJECT_FINALIZE":                                                                	# checks if folder has been created                                                                                       		# if the file is empty it means it was a folder action (usually a new empty folder has been created or deleted)
	# 		create_dir(dir)	                                                                            # call the create directory function

#### End of object changes actions
################################################

#Function used to analyze received messages and take actions based on that
def callback(message):
	if message.attributes:                                                                         			 # Read message attributes
	   for key in message.attributes:
	       value = message.attributes.get(key)
	       if(key == "eventType"):                                                                 			  # Store event type
			   event = value
	       elif(key == "objectId"):                                                               			  # Store path and filename
			   object = value
		   elif(key == "eventTime"):
			   time = value
#####
	message.ack()                                                                                  			  # Sends ack notification to google that message has been received

####
	if event == "OBJECT_DELETE":
		event = "OBJECT_MOVED"

	output = open(gsync_log_fn,"a")
	output.write("[ CHANGE ] "+time+" "+event+" "+object+"\n")

	if event != "OBJECT_FINALIZE":                                                                      	# If it is not creation then abort
		return

### Parse filename, path, and directory from the objectID
	fsplit = object.rfind('/')+1                                                                   			# finding filename position in objectID
	psplit = object.find('/')+1                                                                    			# finding full path position exlcuding the root folder
	file = object[fsplit:]                                                                         			# Assigning the filename to a variable (will be empty of action was taken on a folder
	path = object[psplit:fsplit]                                                                   			# Assigning path to a variable
	dir = path[:-1]                                                                                			# excluding last "/" from path
#####
#Exclude .gstmp files
	if (file.find(".gstmp") != -1):                                                                     	# exclude gs tmp files from processing
		return

# Check if the file source was NAS
	if event == "OBJECT_FINALIZE":                                                                      	# Check if it was a creation change
		logging.basicConfig()                                                                               # Log handler for the google pull function
		flag = check_owner("CREATE",path+file)                                                              # Call the check owner function
		if (flag):                          					   											# If it wasn't logged from NAS then sync
			run_sync(path,dir,event,file)

### End of function
####################################################

### Calls the function whenever a message is received and limits the subscriber messages to a max
flow_control = pubsub_v1.types.FlowControl(max_messages=max_proc)
subscriber.subscribe(subscription_path, callback=callback, flow_control=flow_control)

# The subscriber is non-blocking, so we must keep the main thread from
# exiting to allow it to process messages in the background.
print('Listening for messages on {}'.format(subscription_path))
while True:
	time.sleep(60)
