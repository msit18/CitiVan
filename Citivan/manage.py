from flask import request, Response
# from Citivan import app
import xmltodict
import requests

from analyzeSMSResponses import CitivanSMS
from analyzeSMSResponses import Server

from flask import Flask
import os
app = Flask(__name__)

@app.route('/')
def hello_world():
	return 'Hello, World from SCL!'

@app.route('/exchange', methods=['GET', 'POST'])
def login():
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
		if 'gviSms' in xmltodict.parse(request.data):
			obj = xmltodict.parse(request.data)['gviSms']
			cellNumber = obj['cellNumber']
			content = obj['content']
			contentSplit = content[8:].split(']')

			print "TYPE: ", type(obj)
			print "OBJ: ", cellNumber
			print "MESSAGE: ", content

			print "Parse: ", contentSplit
			print "Sent Message: ", contentSplit[0]

			returnVal = analyzeSMSInfo(cellNumber, content)
			print "returnVal: ", returnVal
			print type(returnVal)

			#post the xml data to their server

			xmlMessage = \
				"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"\
				"<gviSmsMessage>"\
				    "<affiliateCode>CIT003-485</affiliateCode>"\
				    "<authenticationCode>19070017</authenticationCode>"\
				    "<submitDateTime>yyyy-MM-ddTHH:mm:ss</submitDateTime>"\
				    "<messageType>text</messageType>"\
				    "<recipientList>"\
				        "<message>{0}</message>"\
				        "<recipient>"\
				            "<msisdn>{1}</msisdn>"\
				        "</recipient>"\
				    "</recipientList>"\
				"</gviSmsMessage>".format(returnVal, cellNumber)

			print xmlMessage

			headers = {'Content-Type': 'application/xml'}
			r = requests.post('http://bms27.vine.co.za/httpInputhandler/ApplinkUpload', data=xmlMessage, headers=headers)
			print "Status code: ", r.status_code
			#post back to server

			return "Response received" #Is this sent back as a POST or what kind of message?

		elif 'reply' in xmltodict.parse(request.data)['gviSmsResponse']['responseType']:
			responseText = xmltodict.parse(request.data)['gviSmsResponse']
			replyMsg = responseText['response']
			cellphoneNum = responseText['recipient']['msisdn']
			print "REPLY MESSAGE", replyMsg
			print "CELLNUM: ", cellphoneNum
			returnReply = analyzeSMSInfo(cellphoneNum, replyMsg)
			print "returnReply: ", returnReply

			xmlReplyMessage = \
				"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"\
				"<gviSmsMessage>"\
				    "<affiliateCode>CIT003-485</affiliateCode>"\
				    "<authenticationCode>19070017</authenticationCode>"\
				    "<submitDateTime>yyyy-MM-ddTHH:mm:ss</submitDateTime>"\
				    "<messageType>text</messageType>"\
				    "<recipientList>"\
				        "<message>{0}</message>"\
				        "<recipient>"\
				            "<msisdn>{1}</msisdn>"\
				        "</recipient>"\
				    "</recipientList>"\
				"</gviSmsMessage>".format(returnReply, cellphoneNum)

			print "replyXMLMSG: ", xmlReplyMessage

			headers = {'Content-Type': 'application/xml'}
			r = requests.post('http://bms27.vine.co.za/httpInputhandler/ApplinkUpload', data=xmlReplyMessage, headers=headers)
			print "Status code: ", r.status_code

			print "Response text. No needed effort unless error or reply"
			return "Thank you for the response message."
			#what to do if error or reply messagae? Error handling...
		else:
			print "KEYS: ", xmltodict.parse(request.data).keys()
			return "Sorry, we could not handle that request"

	else:
		return "This page does not exist!"

def analyzeSMSInfo(ID, msg):
	s = Server()
	return s.main(ID, msg)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)