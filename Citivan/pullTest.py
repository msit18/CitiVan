from analyzeSMSResponses import CitivanSMS
from analyzeSMSResponses import Server
# import config as var

# def main():
# 	caller = raw_input("what is your phone number?")
# 	text = raw_input("What is your message? ")
# 	c = CitivanSMS(caller, var.client)
# 	status = c.runNew(text.lower())
# 	print "STATUS TYPE: ", type(status)
# 	print "\n\nCELLPHONE TEXT: "
# 	if status <= 1:
# 		print "Welcome to CitiVan! Please answer the following questions. To see the ratings of a van, send \"rate VanNumber\" \n"
# 		print var.questions[0]
# 	elif isinstance(status, int)==False:
# 		splitMsg = status.split("@@")
# 		print splitMsg[0]
# 		print "\nsplit here \n"
# 		print splitMsg[1]
# 	else:
# 		print var.questions[status-1]
# 	print "END OF CELLPHONE TEXT"

s = Server()
s.main("123456", "hello'")