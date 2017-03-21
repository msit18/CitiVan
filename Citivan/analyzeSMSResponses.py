#Code written by Michelle Sit

#Notes:
#For Cloudant, you must include the _id and _rev items to write to the online database

#convoNum behaviors - It must never go to 0 otherwise there will be one too many survey items
#- At 1 = lowest number. input +1
#- At 5 = input should +1
#- At 7 = If input, produce new survey set, reset convoNum to 1

#Everything in the json starts from 1 instead of 0. This is to improve readability for
#non-computer science people.

#FIX: EMPTY MESSAGES BEING SENT TO HEROKU WEBSITE

from __future__ import division
from cloudant.client import Cloudant
from cloudant.result import Result, ResultByKey
from time import gmtime, strftime
import config as cf

class Server:
	def main (self, participantCellNum, participantMsg):
		# caller = raw_input("what is your phone number?")
		# text = raw_input("What is your message? ")
		caller = str(participantCellNum)
		text = str(participantMsg)
		c = CitivanSMS(caller, cf.client)
		status = c.runNew(text.lower())
		print "status: ", status
		print "STATUS TYPE: ", type(status)
		print "\n\nCELLPHONE TEXT: "
		if status <= 1:
			sendBack = "Welcome to CitiVan! Please answer the following questions."\
						" To see the ratings of a van, send \"rate VanNumber\"\n{0}"\
						.format(cf.questions[0])
		elif isinstance(status, int)==False:
			splitMsg = status.split("@@")
			print "splitMsg : ", splitMsg
			sendBack = "{0}\n{1}".format(splitMsg[0], splitMsg[1])
		else:
			sendBack = cf.questions[status-1]
		print "SEND BACK MSG: ", sendBack
		return sendBack

class CitivanSMS:

	def __init__(self, callerID, client):
		self.callerID = str(callerID)
		self.client = client

		self.json = self.getDataFile("testSample2")
		self.busJson = self.getDataFile("busData")
		print "END OF INITIALIZED-----"

	def getDataFile(self, dataFile):
		end_point = "{0}/citivan/{1}/".format(cf.serviceURL, dataFile)
		params = {'include_docs': 'true'}
		response = self.client.r_session.get(end_point, params=params)
		jsonFile = response.json()
		return jsonFile

	def calculateAverage(self, inputBusName, questionNum, decimalPlace):
		print "CalculateAverage method"
		avg = float()
		if decimalPlace == "percent":
			avg = (self.busJson[str(inputBusName)][str(questionNum)])/ \
					(self.busJson[str(inputBusName)][str(questionNum+5)])*100
		elif decimalPlace == "fiveScale":
			avg = (self.busJson[str(inputBusName)][str(questionNum)])/ \
					(self.busJson[str(inputBusName)][str(questionNum+5)])
		print "avg: ", avg
		return round(avg, 1)

	def rateBus(self, rateBusName, currentConvoNum):
		print "RateBus method"
		print "rateBusName:", rateBusName
		if rateBusName not in self.busJson:
			print "BUS HAS NOT BEEN RATED YET: "
			return "The bus {0} has not been rated yet. @@{1}".format(rateBusName, cf.questions[currentConvoNum-1])
		elif (self.busJson[rateBusName]["12"] == 0):
			print "12 value is 0. Surveyors have not finished survey. "
			return "The bus {0} has not been rated yet. @@{1}".format(rateBusName, cf.questions[currentConvoNum-1])
		else:
			try:
				print "BUS RATING IS THE FOLLOWING"
				question2Answer = self.calculateAverage(rateBusName, 2, "fiveScale")
				question3Answer = self.calculateAverage(rateBusName, 3, "fiveScale")
				question4Answer = self.calculateAverage(rateBusName, 4, "percent")
				question5Answer = self.calculateAverage(rateBusName, 5, "percent")
				question6Answer = self.calculateAverage(rateBusName, 6, "percent")
				overrideReturnValue = "Minibus {0}: {1} ratings\n"\
									"Avg ride quality {2}/5\n"\
									"Avg comfort {3}/5\n"\
									"{4}% think the driver drives safely\n"\
									"{5}% think the driver is courteous\n"\
									"{6}% feel safe"\
									" @@{7}".\
				format(rateBusName, self.busJson[rateBusName]["12"], question2Answer,\
				question3Answer, question4Answer, question5Answer, question6Answer,\
				cf.questions[currentConvoNum-1])
				return overrideReturnValue
			except:
				print "There was an error in bus data"
				return "The bus {0} has not been rated yet. @@{1}".format(rateBusName, cf.questions[currentConvoNum-1])

	def getBusName(self, userText, surveyNum):
		print "getBusName Method"
		busName = self.json[self.callerID][str(surveyNum)]["1"]
		print "BUSNAME VALUE: ", busName
		if busName == 0:
			print "BUS NAME IS NOT ENTERED"
			busName = userText
			print str(busName) not in self.busJson
			if (str(busName) not in self.busJson) & (str(userText) != "rate"):
				print "CREATING NEW BUS DATA"
				self.busJson[str(busName)] = {"1":"{0}".format(userText), "2":0, "3":0, "4":0, "5":0, "6":0,
										"7":1, "8":0, "9":0, "10":0, "11":0, "12":0}
				busJsonFormat = self.busJson
				end_point_bus = "{0}/citivan/{1}/".format(cf.serviceURL, "busData")
				r_bus = self.client.r_session.put(end_point_bus, json=busJsonFormat)
				print "BUS: {0}\n".format(r_bus.json())
				print "FINISHED WRITING TO DATABASE"
		return busName

	def inputDataToCloudant(self, currentConvoNum, userText, surveyNum):
		print "InputDataToCloudant method"
		print "CurrentConvoNum for Input: ", currentConvoNum
		_busName = self.getBusName(userText, surveyNum)
		print "userText: ", userText
		print isinstance(userText, int)
		try:
			intUserText = int(userText)
		except:
			intUserText = 0
		print "intUserText: ", intUserText
		strCurrentConvoNum = str(currentConvoNum)
		strSurveyNum = str(surveyNum)
		if currentConvoNum == 1:
			print "FIRST QUESTION. PUTTING BUS NAME INTO THE SYSTEM"
			print "CHECKING LENGTH OF BUSNAME: ", 3<len(userText)<5
			if 3<len(userText)<5:
				print "BUSNAME IS FOUR CHARACTERS"
				self.json[self.callerID][strSurveyNum][strCurrentConvoNum] = userText
				# self.busJson[_busName]["7"] += 1
				self.json[self.callerID]["convoNum"] += 1
				self.json[self.callerID][strSurveyNum]["LastSubmitTime"] = strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime())
		elif (2<=currentConvoNum<=3) & (1<=intUserText<=5):
			print  "QUESTION TWO OR QUESTION 3. PUTTING IN INFO"
			self.json[self.callerID][strSurveyNum][strCurrentConvoNum] = intUserText
			self.busJson[_busName][strCurrentConvoNum] += intUserText
			self.busJson[_busName][str(currentConvoNum+6)] += 1
			self.json[self.callerID]["convoNum"] += 1
			self.json[self.callerID][strSurveyNum]["LastSubmitTime"] = strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime())
		elif (currentConvoNum > 3) & ((userText == "yes") | (userText == "no") | (1<=intUserText<=2)):
			print "QUESTIONS FOUR THROUGH SIX. PUTTING IN INFO"
			if (userText == "yes")  | (intUserText == 1):
				self.json[self.callerID][strSurveyNum][strCurrentConvoNum] = "yes"
				self.busJson[_busName][strCurrentConvoNum] += 1
			elif (userText == "no") | (intUserText == 2):
				self.json[self.callerID][strSurveyNum][strCurrentConvoNum] = "no"
				#Does not add to busJson question number if the answer is no
			self.busJson[_busName][str(currentConvoNum+6)] += 1
			self.json[self.callerID]["convoNum"] += 1
			self.json[self.callerID][strSurveyNum]["LastSubmitTime"] = strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime())
		else:
			pass


	###MAIN METHOD
	def runNew(self, userText):
		#Connects to database server in initialized
		print "RUNNEW Method"
		print "callerID from runnew: ", self.callerID
		print "input text: ", userText
		overrideReturnValue = ""
		# print "self.json: ", self.json
		userTextSplit = userText.split()
		try:
			###DOES USER EXIST? If so, then all the other functions are allowed.
      		#If this is a new user, disregard the input text and just create a new profile
			if self.callerID in self.json:
				print "VERIFY USER EXISTS: USER ALREADY EXISTS"
				print "self.jsonPeopleCallerIDConvoNum", self.json[self.callerID]["convoNum"]
				newUser = False
				callerHashInfo = self.json[self.callerID]

				#Creates new survey hash if last is full
				if (callerHashInfo["convoNum"]>6) & (userTextSplit[0] != "rate"):
					print "CREATING NEW SURVEY HASH. LAST SURVEY IS FULL"
					self.json[self.callerID]["convoNum"] = 1
					newHash = {"LastSubmitTime":0, "1":0, "2":0, "3":0, "4":0, "5":0, "6":0}
					self.json[self.callerID][len(callerHashInfo)] = newHash
				else:
					print "NOT CREATING NEW SURVEY HASH"
					currentConvoNum = callerHashInfo["convoNum"]
					print "NUM ITEMS IN CALLERID: ", str(len(callerHashInfo))
					surveyNum = len(callerHashInfo)-1 #Note: convoNum item is removed from length
					overrideReturnValue = ""

					###RATE CMD
					if userTextSplit[0] == "rate":
						print "running rate function"
						overrideReturnValue = self.rateBus(userTextSplit[1], currentConvoNum)

					###INPUT TEXT INTO SURVEY
					else:
						print "ELSE STATEMENT"
						self.inputDataToCloudant(currentConvoNum, userText, surveyNum)

			###NEW USER. Create new account. Disregarded input text.
			else:
				print "VERIFY USER EXISTS: CREATE NEW PROFILE"
				newCaller = {"1": {"LastSubmitTime":0, "1":0, "2":0, "3":0, "4":0, "5":0, "6":0}, "convoNum":1}
				self.json[self.callerID] = newCaller
				newUser = True

				if userTextSplit[0] == "rate":
					print "Running rate function"
					overrideReturnValue = self.rateBus(userTextSplit[1], 1)

		finally:
			print "OverrideReturnValue :", overrideReturnValue
			print "OverrideTrueTest: ", overrideReturnValue == ""
			###Note: store information into user databases
			if overrideReturnValue == "":
				print "overrideReturnValue is null"
				returnValue = self.json[self.callerID]["convoNum"]

				jsonFormat = self.json
				end_point = "{0}/citivan/{1}/".format(cf.serviceURL, "testSample2")
				r = self.client.r_session.put(end_point, json=jsonFormat)
				print "ENDPT {0}\n".format(r.json())

				if newUser == False:
					print "newUser is False"
					busJsonFormat = self.busJson
					end_point_bus = "{0}/citivan/{1}/".format(cf.serviceURL, "busData")
					r_bus = self.client.r_session.put(end_point_bus, json=busJsonFormat)
					print "BUS: {0}\n".format(r_bus.json())
			else:
				returnValue = overrideReturnValue
			
			print "RETURNVALUE :", returnValue

		return returnValue

# if __name__ == '__main__':
	# questions = ["What are the last four digits of the minibus license plate? (Example: for CA34578, enter 4578).", 
	# 			"Pick a number from 1 to 5 to rate the quality of your ride. 1) Very poor. 2) Poor. 3) Average. 4) Good. 5) Excellent.",
	# 			"Rate from 1 to 5, how comfortable you are in the vehicle? 1) Very Uncomfortable 2) Uncomfortable 3) Average 4) Good 5) Very Comfortable",
	# 			"Does the driver drive safely? Enter 1 for yes or 2 for no.",
	# 			"Was your driver courteous? Enter 1 for yes or 2 for no.", 
	# 			"Do you feel safe in this vehicle? Enter 1 for yes or 2 for no.", 
	# 			"Thank you for your responses! Have a great day."]

	# cloudantUsername = "citivan"
	# cloudantPassword = "CityVan1"
	# serviceURL = "https://citivan.cloudant.com"
	# client = Cloudant(cloudantUsername, cloudantPassword, url=serviceURL,\
	# 				connect=True, auto_renew=True)

	# # caller = 123456
	# # text = raw_input("What is your message? ")
	# # c = CitivanSMS(caller, client)
	# main()
	# status = c.runNew(text.lower())
	# print "STATUS TYPE: ", type(status)
	# print "\n\nCELLPHONE TEXT: "
	# if status <= 1:
	# 	print "Welcome to CitiVan! Please answer the following questions. To see the ratings of a van, send \"rate VanNumber\" \n"
	# 	print questions[0]
	# elif isinstance(status, int)==False:
	# 	splitMsg = status.split("@@")
	# 	print splitMsg[0]
	# 	print "\nsplit here \n"
	# 	print splitMsg[1]
	# else:
	# 	print questions[status-1]
	# print "END OF CELLPHONE TEXT"