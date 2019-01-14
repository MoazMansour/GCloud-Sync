import base64
pass1 = "Nannas&Zozza1801"
pass2 = pass1.encode("UTF8")
password = base64.b64encode(pass2)
print(password)
