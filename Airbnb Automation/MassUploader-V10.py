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

## Changable Parameters
username = "moaz.mansour@blink.la"                                                              # Username
encoded_pass = "TmFubmFzJlpvenphMTgwMQ=="                                                       # The b64 encoded user password
password = base64.b64decode(encoded_pass)                                                       # decoding password to be sent to chrome
chrome_driver = "/Users/moazmansour/OneDrive/Blink/Programs/Airbnb Automation/chromedriver"     # Path to chrome driver executable file
cs_link = 'https://cs.blink.la/photosets/update/26/63'                                          # Link to CS
massupdater_path = "/Users/moazmansour/Desktop/MassUpdater_20190102.csv"                        # Path to massupdater file

# Using Chrome to access web
driver = webdriver.Chrome (executable_path = chrome_driver)                                     # Open Chrome

# Open the website
driver.get(cs_link)                                                                             # Send a get request to CS
id_box = driver.find_element_by_name('email')                                                   # Find the e-mail/username field
passwd_box = driver.find_element_by_name('password')                                            # Find the password field

# Send id information
id_box.send_keys(username)                                                                      # Send username
passwd_box.send_keys(password)                                                                  # Send password

# Find login button
login_button = driver.find_element_by_tag_name('button')                                        # Get the only button in the page
login_button.click()                                                                            # click this button

#Find and click browse CSV find_element_by_name
CSV_input = driver.find_element_by_xpath('//input[@type="file"]')                               # Finding the browse for CSV file button
CSV_input.send_keys(massupdater_path)                                                           # sending the massupdater path
update_button = driver.find_element_by_id('importInformation')                                  # Find the button to update information
update_button.click()                                                                           # Click the update button
