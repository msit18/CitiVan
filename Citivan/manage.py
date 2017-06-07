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
		print "END OF LOGS"
		return "GET METHOD FOR XML PAGE. HELLO WORLD FROM SCL. UPDATE 06/06 9:54"
	elif request.method == 'POST':
		print "HEADERS", request.headers
		print "REQ_path", request.path
		print "ARGS",request.args
		print "DATA",request.data
		print "FORM",request.form
		print "DATA ARGS: ", type(request.form)
		print "XML all: ", request.form['XML']

		print "try the various methods---------"

		trySoupMethod = soupMethod(request.form['XML'])
		print "SOUP TRYMETHOD RESULT: ", trySoupMethod
		if trySoupMethod == "error":
			tryXMLMethod = xmltodictMethod(request.form['XML'])
			print "XMLTODICT TRYMETHOD RESULT: ", tryXMLMethod
			if tryXMLMethod == "error":
				tryStrParseMethod = stringParse(request.form['XML'])
				print "STRPARSE TRYMETHOD RESULT: ", tryStrParseMethod
				if tryStrParseMethod == "error":
					print "ERROR. COULD NOT PROCESS THIS REQUEST"
					print "END OF LOGS"
					# return "ERROR. COULD NOT PROCESS THIS REQUEST"
		print "END OF LOGS. SOME SUCCESS"
		# return "Response received"

	else:
		return "This page does not exist!"

def analyzeSMSInfo(ID, msg):
	s = Server()
	print "Message from the server: ", msg
	return s.main(ID, msg)

def sendXMLBack (sendBackMessage, cellNumber):
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
		"</gviSmsMessage>".format(sendBackMessage, cellNumber)
	print xmlMessage

	headers = {'Content-Type': 'application/xml'}
	r = requests.post('http://bms27.vine.co.za/httpInputhandler/ApplinkUpload', data=xmlMessage, headers=headers)
	print "Status code: ", r.status_code
	return r

def soupMethod(xmlText):
	print "verifying soup works---------"
	# soup = BeautifulSoup(request.form['XML'], "html.parser")
	soup = BeautifulSoup(xmlText, "html.parser")
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

		print "SENDING XML MESSAGE BACK"
		sendXMLBack(returnVal, cellNumber)

		return "success"

	elif soup.responseType != None:
		print "gvismsresponse"
		replyMsg = soup.response.string
		cellNumber = soup.msisdn.string

		print "REPLY MESSAGE", replyMsg
		print "CELLNUM: ", cellNumber
		returnReply = analyzeSMSInfo(cellNumber, replyMsg)
		print "returnReply: ", returnReply

		print "SENDING XML MESSAGE BACK"
		sendXMLBack(returnReply, cellNumber)

		return "success"

	else:
		print "THIS IS THE ELSE STATEMENT. SOUP IS NONE. TRYING ANOTHER METHOD"
		print "---------"
		return "error"

def xmltodictMethod(xmlText):
	print "XML text: ", xmlText
	print "find keys: ", xmltodict.parse(xmlText)
	# try:
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

		print "SENDING XML MESSAGE BACK"
		sendXMLBack(returnVal, cellNumber)

		return "success"

	elif 'reply' in xmltodict.parse(xmlText)['gviSmsResponse']['responseType']:
		responseText = xmltodict.parse(xmlText)['gviSmsResponse']
		replyMsg = responseText['response']
		cellNumber = responseText['recipient']['msisdn']
		print "REPLY MESSAGE", replyMsg
		print "CELLNUM: ", cellNumber
		returnReply = analyzeSMSInfo(cellNumber, replyMsg)
		print "returnReply: ", returnReply

		print "SENDING XML MESSAGE BACK"
		sendXMLBack(returnReply, cellNumber)

		print "Response text. No needed effort unless error or reply"
		return "success"

	elif ('error' in xmltodict.parse(xmlText)['gviSmsResponse']['responseType']) | ('receipt' in xmltodict.parse(xmlText)['gviSmsResponse']['responseType']):
		print "GRAPEVINE SERVER IS SENDING AN ERROR OR RECEIPT BACK TO THIS SERVER."
		return "success"

	else:
		print "XMLTODICT DID NOT WORK. TRYING STRING PARSE"
		return "error"
	# except:
	# 	print "KEYS: ", xmltodict.parse(xmlText)
	# 	print "XMLTODICT DID NOT WORK. TRYING STRING PARSE"
	# 	return "error"

def stringParse(text):
	print "stringParse received this: ", text
	parse = text.split(">")
	print "PARSE: ", parse
	whichMessage = ""

	for word in range(len(parse)):

		if (parse[word] == "<gvisms") | (parse[word] == "<gviSms"):
			whichMessage = "gvisms"
			print "This is a gvisms message"
		elif parse[word] == "<cellNumber":
			s = parse[word+1].split("<")
			print "SPLIT WORDS: ", s
			cellNumber = s[0]
			print "CellNum: ", cellNumber
		elif parse[word] == "<content":
			s = parse[word+1].split("<")
			print "SPLIT WORDS: ", s
			content = s[0]
			print "Content: ", content


		elif parse[word][:15] == "<gviSmsResponse":
			print "This is a response message"
			whichMessage = "gvismsresponse"
		elif parse[word] == "<responseType":
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
			cellNumber = s[0]
			print "cellNum: ", cellNumber
		elif parse[word] == "<response":
			s = parse[word+1].split("<")
			print "SPLIT WORDS: ", s
			replyMsg = s[0]
			print "message: ", replyMsg

	# try:
	if whichMessage == "gvisms":
		print "gvisms whichmessage"
		print "cellNumber: ", cellNumber
		print "content: ", content

		returnVal = analyzeSMSInfo(cellNumber, content)
		print "returnVal: ", returnVal

		print "SENDING XML MESSAGE BACK"
		sendXMLBack(returnVal, cellNumber)

		return "success"

	elif (whichMessage == "gvismsresponse") & (resType != "receipt") & (resType != "error"):
		print "gvismsresponse whichmessage"
		print "cellNumber: ", cellNumber
		print "replyMsg: ", replyMsg
		returnReply = analyzeSMSInfo(cellNumber, replyMsg)

		print "SENDING XML MESSAGE BACK"
		sendXMLBack(returnReply, cellNumber)

		print "Response text. No needed effort unless error or reply"
		return "success"

	else:
		print "STRINGPARSE WAS ALSO A FAILURE. CHECK FOR ERRORS. END OF METHOD"
		return "error"
	# except:
	# 	print "STRINGPARSE WAS ALSO A FAILURE. CHECK FOR ERRORS. END OF METHOD"
	# 	return "error"


# if __name__ == "__main__":
#     port = int(os.environ.get("PORT", 5000))
#     app.run(host='0.0.0.0', port=port)