###############################################################################
# NAME:      pull-rel-11.py
# AUTHOR:    Moaz Mansour, Blink
# E-MAIL:	 moaz.mansour@blink.la
# DATE:      12/12/2018
# LANG:		 Python 2.7
#
# This script manages monitoring changes on Google Cloud and updating
# local NAS server accordingly.
#
# VERSION HISTORY:
# 1.0    12/05/2018		Initial Version
# 1.1    12/12/2018    	Exlcuded rsync
###############################################################################

##############################################################
################# GC-Sync Google Side Monitor ################
##############################################################


import time
from subprocess import call 									#import subprocess library to run bash commands in script
from subprocess import check_output
from google.cloud import pubsub_v1

####### Information to be changed based on the type of service and bucket used ####
project_id = "production-backup-194719" 						#The project I am assigned to on Gcloud
subscription_name = "mySub" 									#Pull subscription channel created to pull all object changes messages
bucket = "gs://rsync-trigger-test/" 							#Bucket path
g_root = "GSync/" 												#root folder subject to change on the cloud
l_root = "/rsync-test/"											#root folder subject to change on the local server

subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(project_id, subscription_name)

###############################################
#Main synchronization function
def run_sync(path,dir,event,file):
### Check the type of change and act upon it
	if file:													#checks if the action was taken on a file object (which is mostly the case with gcloud)
		if event == "OBJECT_FINALIZE":							#if file has been created or modified
			call(["mkdir","-p",l_root+dir])						#assures that the target directory (full path) exists on NAS
			call(["gsutil","-m","cp",bucket+g_root+path+file,l_root+path+file])     #copies the changed/created file to its destination on NAS
		elif event == "OBJECT_DELETE":							#checks if file has been deleted or renamed
			call(["rm",l_root+path+file])						#removes file from NAS
			call(["find",l_root+path,"-type","d","-empty","-delete"]) #if emptied removes the target folder and its empty subordinates to comply with gcloud object logic
###
	else:														#if the file is empty it means it was a folder action (usually a new empty folder has been created or deleted)
		if event == "OBJECT_FINALIZE":							#checks if folder has been created
			call(["mkdir","-p",l_root+dir])						#creates the new folder and all its parents if needed
			call(["cp","-P","dummy",l_root+dir+"/.initate"])
			call(["cp","-P","dummy",bucket+g_root+dir+"/.initate"])
		elif event == "OBJECT_DELETE":							#checks if folder has been deleted
			call(["find",l_root+path,"-type","d","-empty","-delete"]) #removes the target folder and its empty subordinates to comply with gcloud object logic
#### End of object changes actions
################################################

#Function used to analyze received messages and take actions based on that
def callback(message):
	#print('\n Received message: {}'.format(message.data))
	if message.attributes:                                     	#read message attributes
	   #print('\nAttributes:')
	   for key in message.attributes:
	       value = message.attributes.get(key)
	       #print('{}: {}'.format(key, value))
	       if(key == "eventType"):  							#store event type
			   event = value
			   print ("Eventttpe: "+event)
	       elif(key == "objectId"): 							#store path and filename
			   object = value
			   print("ObjectID: "+object)

### Parse filename, path, and directory from the objectID
	fsplit = object.rfind('/')+1								#finding filename position in objectID
	psplit = object.find('/')+1									#finding full path position exlcuding the root folder
	file = object[fsplit:]										#Assigning the filename to a variable (will be empty of action was taken on a folder)
	path = object[psplit:fsplit]								#Assigning path to a variable
	dir = path[:-1]												#excluding last "/" from path

#####
# Check if the file source was NAS
	if event == "OBJECT_FINALIZE":
		change_check = check_output(["gsutil","ls","-L",bucket+g_root+path+file])
		if (change_check.find('posix-uid:') == -1):
			run_sync(path,dir,event,file)
	elif event == "OBJECT_DELETE":
		run_sync(path,dir,event,file)
#####
	message.ack()												# Sends ack notification to google that message gas been received
### End of function
####################################################

### Calls the function whenever a message is received
subscriber.subscribe(subscription_path, callback=callback)

# The subscriber is non-blocking, so we must keep the main thread from
# exiting to allow it to process messages in the background.
print('Listening for messages on {}'.format(subscription_path))
while True:
	time.sleep(60)
