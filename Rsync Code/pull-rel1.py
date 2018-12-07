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
	   #print('\nAttributes:')
	   for key in message.attributes:
	       value = message.attributes.get(key)
	       #print('{}: {}'.format(key, value))
	       if(key == "eventType"):
			   event = value
	       elif(key == "objectId"):
			   object = value
	fsplit = object.rfind('/')+1
	psplit = object.find('/')+1
	file = object[fsplit:]
	path = object[psplit:fsplit]
	dir = path[:-1]
	if file:
		if event == "OBJECT_FINALIZE":
			call(["mkdir","-p","/rsync-test/"+dir])
	 		#call(["gsutil","-m","rsync","gs://rsync-trigger-test/GSync/"+path,"/rsync-test/"+path])
			call(["gsutil","cp","gs://rsync-trigger-test/GSync/"+path+file,"/rsync-test/"+path+file])
		elif event == "OBJECT_DELETE":
			call(["rm","/rsync-test/"+path+file])
			call(["find","/rsync-test/"+path,"-type","d","-empty","-delete"])
	else:
		if event == "OBJECT_FINALIZE":
			call(["mkdir","/rsync-test/"+dir])
		elif event == "OBJECT_DELETE":
			call(["find","/rsync-test/"+path,"-type","d","-empty","-delete"])
	message.ack()
subscriber.subscribe(subscription_path, callback=callback)

# The subscriber is non-blocking, so we must keep the main thread from
# exiting to allow it to process messages in the background.
print('Listening for messages on {}'.format(subscription_path))
while True:
	time.sleep(60)
