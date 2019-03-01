import sys
cloud_log = sys.argv[1]
text = sys.argv[2]
f = open(cloud_log,"r")
content = f.read()
content = content.replace(text," ")
f = open(cloud_log,"w")
f.write(content)
f.close()
