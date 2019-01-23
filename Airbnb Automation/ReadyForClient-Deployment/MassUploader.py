###############################################################################
# NAME:      MassUploader-V10.py
# AUTHOR:    Moaz Mansour, Blink
# E-MAIL:    moaz.mansour@blink.la
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

## Changable Parameters
massupdater_path = str(sys.argv[1])                                                             # Reading argument sent from powrshell which is Path to massupdater file on Windows
username = str(sys.argv[2])                                                                     # Username
encoded_pass = str(sys.argv[3])                                                                 # The b64 encoded user password
chrome_driver = str(sys.argv[4])                                                                # Path to chrome driver executable file on Windows
cs_link = str(sys.argv[5])                                                                      # Link to CS


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

#Find and click browse CSV find_element_by_name
CSV_input = driver.find_element_by_xpath('//input[@type="file"]')                               # Finding the browse for CSV file button
CSV_input.send_keys(massupdater_path)                                                           # sending the massupdater path
update_button = driver.find_element_by_id('importInformation')                                  # Find the button to update information
update_button.click()                                                                           # Click the update button
driver.quit()                                                                                  # Comment this for testing

########################################### Massupdater Upload Script###########################################
