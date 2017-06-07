from flask import request, Response
from Citivan import app
import xmltodict
import requests

from bs4 import BeautifulSoup

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
		return "Get method: Hello, World from SCL! This page has been removed"
	else:
		return "This page does not exist!"


@app.route('/xmlPage', methods=['GET', 'POST'])
def start():
	if request.method == 'GET':
		return "GET METHOD FOR XML PAGE. HELLO WORLD FROM SCL. UPDATE 06/06 9:54"
	elif request.method == 'POST':
		print "HEADERS", request.headers
		print "REQ_path", request.path
		print "ARGS",request.args
		print "DATA",request.data
		print "FORM",request.form
		print "DATA ARGS: ", type(request.form)
		print "XML all: ", request.form['XML']

		print "verifying soup works---------"
		soup = BeautifulSoup(request.form['XML'], "html.parser")
		print "true or false: ", soup.gvisms
		print "Verify: ", soup.gvisms != None
		print "Second: ", soup.gvisms == None
		print "True or false too: ", soup.responseType
		print "TF: null?: ", soup.responseType == None
		print "null again?: ", soup.responseType != None
		print "end soup test----------------"

		if soup.gvisms != None:
			print "GVISMS IF STATEMENT"
			cellNumber = soup.cellnumber.string
			content = soup.content.string

			print "OBJ: ", cellNumber
			print "MESSAGE: ", content

			returnVal = analyzeSMSInfo(cellNumber, content)
			print "returnVal: ", returnVal

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

		# elif 'reply' in xmltodict.parse(request.form)['gviSmsResponse']['responseType']:
		elif soup.responseType != None:
			print "gvismsresponse"
			# responseText = xmltodict.parse(request.form)['gviSmsResponse']
			replyMsg = soup.response.string
			cellphoneNum = soup.msisdn.string

			# replyMsg = responseText['response']
			# cellphoneNum = responseText['recipient']['msisdn']
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

			return "Thank you for the response message."

		else:
			print "THIS IS THE ELSE STATEMENT. SOUP IS NONE. TRYING ANOTHER METHOD"
			print "---------"
			print "xmltodict true or false: ", 'gviSms' in xmltodict.parse(request.form)
			print "replymessage maybe?: ", 'reply' in xmltodict.parse(request.form)['gviSmsResponse']['responseType']
			print "all xmltodict: ", xmltodict.parse(request.form)
			answer = alternativeMethod(request.form)
			print "ANSWER?: ", answer
			if answer == "Response received":
				pass
			else:
				print "THIS IS THE LAST ATTEMPT. STRING PARSE METHOD"
				lastattempt = stringParse(request.form)
				if lastattempt == "Response received":
					pass
				else:
					print "THAT WAS THE LAST STRAW. CANNOT WORK"
					return "THERE WAS AN ERROR"


	else:
		return "This page does not exist!"

def analyzeSMSInfo(ID, msg):
	s = Server()
	print "Message from the server: ", msg
	return s.main(ID, msg)

def alternativeMethod(xmlText):
	# print "True or false: ", ('gviSms' in xmltodict.parse(xmlText))
	print "XML text: ", xmlText
	print "find keys: ", xmltodict.parse(xmlText).keys()
	if 'gviSms' in xmltodict.parse(xmlText):
		print "GVISMS IF STATEMENT"
		obj = xmltodict.parse(xmlText)['gviSms']
		cellNumber = obj['cellNumber']
		content = obj['content']

		print "OBJ: ", cellNumber
		print "MESSAGE: ", content

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

	elif 'reply' in xmltodict.parse(xmlText)['gviSmsResponse']['responseType']:
		responseText = xmltodict.parse(xmlText)['gviSmsResponse']
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
		print "KEYS: ", xmltodict.parse(xmlText).keys()
		return "Response received"

def stringParse(text):
	parse = str.split(">")
	print "PARSE: ", parse

	if (parse[0] == "<gvisms") | (parse[0] == "gviSms"):
		print "This is a gvisms message"
		for word in range(len(parse)):
			if parse[word] == "<cellNumber":
				s = parse[word+1].split("<")
				print "SPLIT WORDS: ", s
				cellNum = s[0]
				print "CellNum: ", cellNum
			elif parse[word] == "<content":
				s = parse[word+1].split("<")
				print "SPLIT WORDS: ", s
				msg = s[0]
				print "Content: ", msg
		returnReply = analyzeSMSInfo(cellNum, msg)
		print "returnReply: ", returnReply

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
			"</gviSmsMessage>".format(msg, cellNum)

		print xmlMessage

		headers = {'Content-Type': 'application/xml'}
		r = requests.post('http://bms27.vine.co.za/httpInputhandler/ApplinkUpload', data=xmlMessage, headers=headers)
		print "Status code: ", r.status_code
		#post back to server

		return "Response received" #Is this sent back as a POST or what kind of message?


	elif parse[0][:15] == "<gviSmsResponse":
		print "This is a response message"
		for word in range(len(parse)):
			if parse[word] == "<responseType":
				s = parse[word+1].split("<")
				print "SPLIT WORDS: ", s
				print "responseType: ", s[0]
				resType = s[0]
				if (resType == "error") | (resType == "receipt"):
					print "Received an error or receipt response message. Breaking"
					break
			elif parse[word] == "<msisdn":
				s = parse[word+1].split("<")
				print "SPLIT WORDS: ", s
				cellNum = s[0]
				print "cellNum: ", cellNum
			elif parse[word] == "<response":
				s = parse[word+1].split("<")
				print "SPLIT WORDS: ", s
				msg = s[0]
				print "message: ", msg


		returnReply = analyzeSMSInfo(cellNum, msg)

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
			"</gviSmsMessage>".format(returnReply, cellNum)

		print "replyXMLMSG: ", xmlReplyMessage

		headers = {'Content-Type': 'application/xml'}
		r = requests.post('http://bms27.vine.co.za/httpInputhandler/ApplinkUpload', data=xmlReplyMessage, headers=headers)
		print "Status code: ", r.status_code

		print "Response text. No needed effort unless error or reply"
		return "Response received"


# if __name__ == "__main__":
#     port = int(os.environ.get("PORT", 5000))
#     app.run(host='0.0.0.0', port=port)