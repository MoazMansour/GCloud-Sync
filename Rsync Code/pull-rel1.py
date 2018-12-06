import time
from subprocess import call #import subprocess library to run bash commands in script
from subprocess import check_output
from google.cloud import pubsub_v1

project_id = "production-backup-194719"
subscription_name = "mySub"

subscriber = pubsub_v1.SubscriberClient()
subscription_path = subscriber.subscription_path(project_id, subscription_name)

def callback(message):
	#print('\n Received message: {}'.format(message.data))
	if message.attributes:
	   print('\nAttributes:')
	   for key in message.attributes:
	       value = message.attributes.get(key)
	       print('{}: {}'.format(key, value))
	       if(key == "eventType"):
	         event = value
	       elif(key == "objectId"):
		 object = value
	fsplit = object.rfind('/')+1
	psplit = object.find('/')+1
	file = object[fsplit:]
	path = object[psplit:fsplit]
	dir = path[:-1]
	print('FILE: %s' % file)
	print('PATH: %s' % path)
	if file:
		if event == "OBJECT_FINALIZE":
	 		dir_check = call(["gsutil","-m","rsync","gs://rsync-trigger-test/GSync/"+path,"/rsync-test/"+path])
			if dir_check == 1:
				new_dir = "/rsync-test"
				subfolders = dir.split("/")
				for folder in subfolders:
					new_dir = new_dir+"/"+folder
					call(["mkdir",new_dir])
				call(["gsutil","-m","rsync","gs://rsync-trigger-test/GSync/"+path,"/rsync-test/"+path])
		elif event == "OBJECT_DELETE":
			call(["rm","/rsync-test/"+path+file])
			call(["rmdir","/rsync-test/"+path])
	else:
		if event == "OBJECT_FINALIZE":
			call(["mkdir","/rsync-test/"+dir])
		elif event == "OBJECT_DELETE":
			call(["rm","-r","/rsync-test/"+dir])
	message.ack()
subscriber.subscribe(subscription_path, callback=callback)

# The subscriber is non-blocking, so we must keep the main thread from
# exiting to allow it to process messages in the background.
print('Listening for messages on {}'.format(subscription_path))
while True:
	time.sleep(60)
