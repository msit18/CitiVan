from flask import request
from Citivan import app

from analyzeSMSResponses import CitivanSMS
from analyzeSMSResponses import Server

@app.route('/')
def hello_world():
	return 'Hello, World from SCL!'

@app.route('/exchange', methods=['GET', 'PUT'])
def login():
	if request.method == 'GET':
		return "Get method: Hello, World from SCL!"
	elif request.method == 'PUT':
		searchword = request.args.get('cellphoneNum')
		messageVal = request.args.get('message')
		print "KEYS: ",searchword
		print "MESSAGE: ", messageVal
		print "Cellphone Number: {0}\nMessage: {1}".format(searchword, messageVal)
		if (searchword != "") & (messageVal != "") & (searchword != "none") & (messageVal!= "none"):
			returnVal = analyzeSMSInfo(searchword, messageVal)
		else:
			returnVal = "Empty credentials"
		print "RETURN VAL: ", returnVal
		return returnVal
	else:
		return "This page does not exist!"

def analyzeSMSInfo(ID, msg):
	s = Server()
	return s.main(ID, msg)