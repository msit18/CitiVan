from flask import request
from Citivan import app

from analyzeSMSResponses import CitivanSMS
from analyzeSMSResponses import Server

@app.route('/')
def hello_world():
	return 'Hello, World from SCL!'

@app.route('/exchange', methods=['GET', 'PUT'])
def login():
	try:
		if request.method == 'GET':
			return "Get method: Hello, World from SCL!"
		elif request.method == 'PUT':
			cellNum = request.args.get('cellphoneNum')
			messageVal = request.args.get('message')
			print "KEYS: ",cellNum
			print "MESSAGE: ", messageVal
			# logs = "Cellphone Number: {0}\nMessage: {1}".format(cellNum, messageVal)
			if (str(cellNum) != "None") & (str(messageVal) != "None") :
				returnVal = analyzeSMSInfo(cellNum, messageVal)
			elif (str(cellNum) == "None"):
				returnVal = "Sorry, there was an error with recording your cellphone number. Please try again."
			elif (str(messageVal) == "None"):
				returnVal = "Sorry, there was an error with the message you sent. Please try again."
			else:
				returnVal = "Sorry, there was an error with the message and cellphone number. Please try again!"
			print "RETURN VAL: ", returnVal
			return returnVal
		else:
			return "This page does not exist!"
	except:
		

def analyzeSMSInfo(ID, msg):
	s = Server()
	return s.main(ID, msg)