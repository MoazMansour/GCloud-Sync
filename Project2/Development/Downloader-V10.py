###############################################################################
# NAME:      MassUploader-V10.py
# AUTHOR:    Moaz Mansour
# E-MAIL:	 moaz.mansour@gmail.com
# DATE:      01/09/2019
# LANG:      Python
#
# This script uses chrome to upload the mass updater csv file to CS
#
# VERSION HISTORY:
# 1.0    01/09/2019    Initial Version
###############################################################################

#####################################################
################## MassUpdater upload ###############
#####################################################
from selenium import webdriver
import base64
import sys
import os.path
import time

## Changable Parameters
username = str(sys.argv[1])                                                                     # Username
encoded_pass = str(sys.argv[2])                                                                 # The b64 encoded user password
chrome_driver = str(sys.argv[3])                                                                # Path to chrome driver executable file on Windows
cs_link = str(sys.argv[4])                                                                      # Link to CS
file_path = str(sys.argv[5])                                                                    # Path to downloads


# Using Chrome to access web
driver = webdriver.Chrome(chrome_driver)                                                        # Open Chrome

# Open the website
driver.get(cs_link)                                                                             # Send a get request to CS
id_box = driver.find_element_by_name('email')                                                   # Find the e-mail/username field
passwd_box = driver.find_element_by_name('password')                                            # Find the password field

# Send id information
id_box.send_keys(username)                                                                      # Send username
password = base64.b64decode(encoded_pass)                                                       # decoding password to be sent to chrome
password = password.decode("utf-8")                                                             # Convert decoded password from bytes to string
passwd_box.send_keys(password)                                                                  # Send password

# Find login button
login_button = driver.find_element_by_tag_name('button')                                        # Get the only button in the page
login_button.click()                                                                            # click this button

#Check Download status
now = time.time()
time_out = now + 20
while not os.path.isfile(file_path):
    if (time.time() < time_out):
        time.sleep(1)
    else:
        break

driver.quit()                                                                                  # Comment this for testing

########################################### Massupdater Upload Script###########################################
