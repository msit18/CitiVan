from flask import request, Response
from Citivan import app
import xmltodict

from analyzeSMSResponses import CitivanSMS
from analyzeSMSResponses import Server

# from flask import Flask
# import os
# app = Flask(__name__)

@app.route('/')
def hello_world():
	return 'Hello, World from SCL!'

@app.route('/exchange', methods=['GET', 'POST'])
def login():
	# before_request_exchange()
	if request.method == 'GET':
		print "that was a get method"
		return "Get method: Hello, World from SCL!"
	elif request.method == 'POST':
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

# def before_request_exchange():
#     if True:
#         print "HEADERS", request.headers
#         print "REQ_path", request.path
#         print "ARGS",request.args
#         print "DATA",request.data
#         print "FORM",request.form

@app.route('/xmlPage', methods=['GET', 'POST'])
def start():
	if request.method == 'GET':
		return "GET METHOD FOR XML PAGE. HELLO WORLD FROM SCL"
	elif request.method == 'POST':
		#get the xml text	
		print "HEADERS", request.headers
		print "REQ_path", request.path
		print "ARGS",request.args
		print "DATA",request.data
		print "FORM",request.form
		print "DATA ARGS: ", type(request.data)
		obj = xmltodict.parse(request.data)['gviSms']
		cellNumber = obj['cellNumber']
		content = obj['content']
		contentSplit = content[8:].split(']')

		print "TYPE: ", type(obj)
		print "OBJ: ", cellNumber
		print "MESSAGE: ", content

		print "Parse: ", contentSplit
		print "1: ", contentSplit[0]

		# returnVal = analyzeSMSInfo(cellNumber, contentSplit[0])
		returnVal = analyzeSMSInfo(cellNumber, content)
		print "returnVal: ", returnVal
		print type(returnVal)

		#what format does this need to be returned as? XML?

		return returnVal

	else:
		return "This page does not exist!"

def analyzeSMSInfo(ID, msg):
	s = Server()
	return s.main(ID, msg)


# if __name__ == "__main__":
#     port = int(os.environ.get("PORT", 5000))
#     app.run(host='0.0.0.0', port=port)