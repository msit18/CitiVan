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
		return "GET METHOD FOR XML PAGE. HELLO WORLD FROM SCL. UPDATE 4/19 02:34"
	elif request.method == 'POST':
		print "HEADERS", request.headers
		print "REQ_path", request.path
		print "ARGS",request.args
		print "DATA",request.data
		print "FORM",request.form
		print "DATA ARGS: ", type(request.form)
		print "XML all: ", request.form['XML']

		soup = BeautifulSoup(request.form['XML'], "html.parser")
		# print "second soup: ", soup
		# content = soup.content.string
		# print "sscontent: ", content

		print "true or false: ", soup.gvisms
		print "Verify: ", soup.gvisms != None
		print "Second: ", soup.gvisms == None
		print "True or false too: ", soup.responseType
		print "TF: null?: ", soup.responseType == None
		print "null again?: ", soup.responseType != None

		cellNumber = soup.cellnumber.string
		print "cellNumber: ", cellNumber

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
			return "Sorry, we could not handle that request"

	else:
		return "This page does not exist!"

def analyzeSMSInfo(ID, msg):
	s = Server()
	print "Message from the server: ", msg
	return s.main(ID, msg)


# if __name__ == "__main__":
#     port = int(os.environ.get("PORT", 5000))
#     app.run(host='0.0.0.0', port=port)