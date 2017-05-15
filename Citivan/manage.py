from flask import request, Response
from Citivan import app
import xmltodict
import requests

import json

from bs4 import BeautifulSoup
from html.parser import HTMLParser

# from analyzeSMSResponses import CitivanSMS
from analyzeSMSResponses import Server

# from flask import Flask
# import os
# app = Flask(__name__)

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
		return "GET METHOD FOR XML PAGE. HELLO WORLD FROM SCL. UPDATE 4/19 02:34"
	elif request.method == 'POST':
		#get the xml text	
		print "HEADERS", request.headers
		print "REQ_path", request.path
		print "ARGS",request.args
		print "DATA",request.data
		print "FORM",request.form
		print "DATA ARGS: ", type(request.form)
		print "Request Form: ", request.form.getlist('gviSms')
		print "Request keys: ", request.form.keys()
		print "Request items: ", request.form.items()
		print "XML all: ", request.form['XML']

		split = request.form['XML'].split('\n')
		print "Split: ", split[0]
		print "Split2: ", split[1]
		soup = BeautifulSoup(split[1], "html.parser")
		print "Soup: ", soup
		soupContent = soup.find('content')
		print "content tag: ", soupContent

		content_split = soupContent.split('>')
		print "content_split"


		parser = MyHTMLParser()
		parser.feed(request.form['XML'])
		print "end of parser"


		print "True or false: ", ('gviSms' in request.form)
		if 'gviSms' in xmltodict.parse(request.form):
			print "GVISMS IF STATEMENT"
			obj = xmltodict.parse(request.form)['gviSms']
			cellNumber = obj['cellNumber']
			content = obj['content']
			# contentSplit = content[8:].split(']')

			# print "TYPE: ", type(obj)
			print "OBJ: ", cellNumber
			print "MESSAGE: ", content

			# print "Parse: ", contentSplit
			# print "Sent Message: ", contentSplit[0]

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

		elif 'reply' in xmltodict.parse(request.form)['gviSmsResponse']['responseType']:
			responseText = xmltodict.parse(request.form)['gviSmsResponse']
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
			print "KEYS: ", xmltodict.parse(request.form).keys()
			return "Sorry, we could not handle that request"

	else:
		return "This page does not exist!"

@app.route('/xmlPageV2', methods=['GET', 'POST'])
def second_start():
	if request.method == 'GET':
		return "GET METHOD FOR XML PAGE V2. HELLO WORLD FROM SCL. UPDATE 5/15"
	elif request.method == 'POST':
		#get the xml text	
		print "HEADERS", request.headers
		print "REQ_path", request.path
		print "ARGS",request.args
		print "DATA",request.data
		print "FORM",request.form
		print "DATA ARGS: ", type(request.form)
		if 'gviSms' in xmltodict.parse(request.form):
			obj = xmltodict.parse(request.form)['gviSms']
			cellNumber = obj['cellNumber']
			content = obj['content']
			# contentSplit = content[8:].split(']')

			# print "TYPE: ", type(obj)
			print "OBJ: ", cellNumber
			print "MESSAGE: ", content

			# print "Parse: ", contentSplit
			# print "Sent Message: ", contentSplit[0]

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

			print "xmlMessages: ", xmlMessage
			r = Response(response=xmlMessage, status=200, mimetype="application/xml")
			r.headers['Content-Type'] = "text/xml; charset=utf-8"
			return r

			# headers = {'Content-Type': 'application/xml'}
			# r = requests.post('http://bms27.vine.co.za/httpInputhandler/ApplinkUpload', data=xmlMessage, headers=headers)
			# print "Status code: ", r.status_code
			#post back to server

			# return "Response received" #Is this sent back as a POST or what kind of message?
			# return Response(xmlMessage, mimetype='text/xml')

		elif 'reply' in xmltodict.parse(request.form)['gviSmsResponse']['responseType']:
			responseText = xmltodict.parse(request.form)['gviSmsResponse']
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

			# headers = {'Content-Type': 'application/xml'}
			# r = requests.post('http://bms27.vine.co.za/httpInputhandler/ApplinkUpload', data=xmlReplyMessage, headers=headers)
			# print "Status code: ", r.status_code

			print "Response text. No needed effort unless error or reply"
			# return "Thank you for the response message."

			r = Response(response=xmlReplyMessage, status=200, mimetype="application/xml")
			r.headers['Content-Type'] = "text/xml; charset=utf-8"
			return r

			# return Response(xmlReplyMessage, mimetype='text/xml')
			#what to do if error or reply messagae? Error handling...
		else:
			print "KEYS: ", xmltodict.parse(request.form).keys()
			return "Sorry, we could not handle that request"

	else:
		return "This page does not exist!"

def analyzeSMSInfo(ID, msg):
	s = Server()
	print "Message from the server: ", msg
	return s.main(ID, msg)

def MyHTMLParser(HTMLParser):
	def handle_starttag(self, tag, attrs):
		print("Start tag: ", tag)
		for attr in attrs:
			print("    attr: ", attr)

	def handle_endtag(self, tag):
		print ("End tag: ", tag)

	def handle_data(self, data):
		print("Data: ", data)


# if __name__ == "__main__":
#     port = int(os.environ.get("PORT", 5000))
#     app.run(host='0.0.0.0', port=port)