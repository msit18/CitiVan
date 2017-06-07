# str = "<gviSmsResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"\
# 	"<responseDateTime>2017-06-06T13:27:00</responseDateTime>"\
# 	"<submitDateTime>2017-06-06T13:27:00</submitDateTime>"\
# 	"<recipient><msisdn>27825932725</msisdn></recipient>"\
# 	"<responseType>receipt</responseType>"\
# 	"<status><code>0</code><reason>Message is delivered to destination. stat:DELIVRD</reason></status></gviSmsResponse>"

# str = "<gviSmsResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"\
# 	"<responseDateTime>2017-06-06T13:29:53</responseDateTime>"\
# 	"<recipient><msisdn>27825932725</msisdn></recipient>"\
# 	"<responseType>reply</responseType><response>5</response></gviSmsResponse>"

# str = "<gviSmsResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"\
# "<responseDateTime>2007-03-02T13:16:20</responseDateTime>"\
# "<recipient><msisdn>27834451878</msisdn></recipient>"\
# "<responseType>reply</responseType>"\
# "<response>Thanks</response></gviSmsResponse>"\

# str = "<gviSmsResponse xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\">"\
# "<responseDateTime>2002-12-19T12:53:29</responseDateTime>"\
# "<submitDateTime>2002-12-19T12:53:48</submitDateTime>"\
# "<recipient><msisdn>27823398094</msisdn></recipient>"\
# "<responseType>error</responseType><status><code>-1</code>"\
# "<reason>SMSC Error: Message is undeliverable. stat:UNDELVR</reason>"\
# "</status></gviSmsResponse>"

# str = "<gviSms>"\
# "<smsDateTime>2005-09-08T10:06:03</smsDateTime>"\
# "<gatewayIdentifier>ThreeRandVodaRx1</gatewayIdentifier>"\
# "<cellNumber>27827891099</cellNumber>"\
# "<smsLocation>35444</smsLocation>"\
# "<content><![CDATA[Lindiwe Sisulu, KZN]]></content>"\
# "</gviSms>"

str = "<gvisms><smsdatetime>2017-06-05T13:21:19</smsdatetime>"\
	"<gatewayidentifier>cellcPremMGA1TxRx2</gatewayidentifier>"\
	"<cellnumber>27843314887</cellnumber><smslocation>48717</smslocation>"\
	"<content>Rate</content></gvisms>"

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
			print "cellNum: ", s[0]
		elif parse[word] == "<response":
			s = parse[word+1].split("<")
			print "SPLIT WORDS: ", s
			print "message: ", s[0]




# for fragment in range(len(parse)):
# 	if parse[fragment] == "<msisdn":
# 		s = parse[fragment+1].split("<")
# 		print "S: ", s
# 		print "cellNum: ", s[0]
# 	elif parse[fragment][:15] == "<gviSmsResponse":
# 		print "This is a response message"
# 	elif parse[fragment] == "<responseType":
# 		s = parse[fragment+1].split("<")
# 		print "S: ", s
# 		print "responseType: ", s[0]
# 	elif parse[fragment] == "<response":
# 		s = parse[fragment+1].split("<")
# 		print "S: ", s
# 		print "message: ", s[0]
# 	elif parse[fragment] == "<gviSms":
# 		print "This is a first pass message"
# 	elif parse[fragment] == ""