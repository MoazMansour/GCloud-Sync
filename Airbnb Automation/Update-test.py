from selenium import webdriver
import base64

username = "moaz.mansour@blink.la"
password = base64.b64decode("TmFubmFzJlpvenphMTgwMQ==")

# Using Chrome to access web
driver = webdriver.Chrome (executable_path = "/Users/moazmansour/OneDrive/Blink/Programs/Airbnb Automation/chromedriver")
# Open the website
driver.get('https://cs.blink.la/photosets/update/26/63')
id_box = driver.find_element_by_name('email')
passwd_box = driver.find_element_by_name('password')

# Send id information
id_box.send_keys(username)
passwd_box.send_keys(password)

# Find login button
login_button = driver.find_element_by_tag_name('button')
# Click login
login_button.click()

#Find and click browse CSV find_element_by_name
CSV_input = driver.find_element_by_xpath('//input[@type="file"]')
massupdater_path = "/Users/moazmansour/Desktop/MassUpdater_20190102.csv"
CSV_input.send_keys(massupdater_path)
update_button = driver.find_element_by_id('importInformation')
update_button.click()
