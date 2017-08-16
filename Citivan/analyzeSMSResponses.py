"""

Written by Michelle Sit

Notes:
For Cloudant, you must include the _id and _rev items to write to the online database

convoNum behaviors - It must never go to 0 otherwise there will be one too many survey items
- At 1 = lowest number. input +1
- At 5 = input should +1
- At 7 = If input, produce new survey set, reset convoNum to 1

Everything in the json starts from 1 instead of 0. This is to improve readability for
non-computer science people.

If the user inputs an incorrect answer, the same question will be repeated and sent back to 
the user. Adding specialized error messages would be a great feature to add.


"""

from __future__ import division
from cloudant.client import Cloudant
from cloudant.result import Result, ResultByKey
from time import gmtime, strftime
import config as cf
import random


class Server:
	def main (self, participantCellNum, participantMsg):
		### For testing locally in terminal:
		# caller = raw_input("what is your phone number?")
		# text = raw_input("What is your message? ")

		caller = str(participantCellNum)
		text = str(participantMsg)
		c = CitivanSMS(caller, cf.client)
		sendBack = c.runNew(text.lower())
		print "\n\nCELLPHONE TEXT: "
		print "----------------------"
		print sendBack
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
		try:
			avg = float((self.busJson[str(inputBusName)][str(questionNum)])/ \
					    (self.busJson[str(inputBusName)][str(questionNum+5)]))
			if decimalPlace == "percent":
				avg = avg*100
			print "avg: ", avg
		except:
			avg = 0.0
		return round(avg, 1)

	def getBusRating(self, rateBusName):
		print "getBusRating method"
		print "rateBusName:", rateBusName
		if (rateBusName not in self.busJson):
			print "BUS HAS NOT BEEN RATED YET: "
			return "The bus {0} has not been rated yet. \n".format(rateBusName)
		elif [r for r in range (8,13) if self.busJson[rateBusName]["{0}".format(r)] == 0] != []:
			print "Surveyors have not finished survey. "
			return "The bus {0} has not been rated yet. \n".format(rateBusName)
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
									"{6}% feel safe\n"\
									.format(rateBusName, self.busJson[rateBusName]["9"], question2Answer,\
									question3Answer, question4Answer, question5Answer, question6Answer)
				return overrideReturnValue
			except:
				print "There was an error in the getBusRating method"
				return "The bus {0} has not been rated yet. \n".format(rateBusName)

	###Note: The logic of checking the license plates may change depending on which plates are included.
	###For now, the system only allows for license plate numbers that are 4 characters long.
	def verifyBusInCloudant(self, userText, surveyNum):
		print "verifyBusInCloudant Method"
		busName = self.json[self.callerID][str(surveyNum)]["1"]
		print "BUSNAME VALUE: ", busName
		if busName == 0:
			print "BUS NAME HAS NOT BEEN ENTERED IN THE USER SURVEY"
			busName = userText
			print "BusName not in busJson?: ", str(busName) not in self.busJson
			print "len of bus text is equal to 4?: ", (len(str(userText)) == 4)

			if (str(busName) not in self.busJson) & (len(str(userText)) == 4):
				print "CREATING NEW BUS DATA"
				self.busJson[str(busName)] = {"1":"{0}".format(userText), "2":0, "3":0, "4":0, "5":0, "6":0,
											  "7":1, "8":0, "9":0, "10":0, "11":0, "12":0}
				busJsonFormat = self.busJson
				end_point_bus = "{0}/citivan/{1}/".format(cf.serviceURL, "busData")
				r_bus = self.client.r_session.put(end_point_bus, json=busJsonFormat)
				print "BUS: {0}\n".format(r_bus.json())
				print "FINISHED WRITING TO DATABASE"
			else:
				print "Bus was not added as a new bus"

		else:
			print "BusName exists in database. Return busName: ", busName
			
		return busName

	def inputDataToCloudant(self, currentConvoNum, userText, surveyNum, currentQuestionNum):
		print "InputDataToCloudant method"
		print "CurrentConvoNum for Input: ", currentConvoNum
		try:
			_busName = self.verifyBusInCloudant(userText, surveyNum)
		except:
			print "ERROR: verifyBusInCloudant did not work for some reason. Using userText as busname"
			_busName = userText

		print "userText: ", userText
		print "Is Usertext a number?: ", isinstance(userText, int)
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
			if (3<len(userText)<5) & (userText != "rate"):
				print "BUSNAME IS FOUR CHARACTERS."
				self.json[self.callerID][strSurveyNum][strCurrentConvoNum] = userText
				self.busJson[_busName]["7"] += 1
				nextQuestion = self.pickNextSurveyQuestion(surveyNum, currentConvoNum)
				self.json[self.callerID]["convoNum"] = nextQuestion
				self.json[self.callerID]["currentQuestionNum"] += 1
				self.json[self.callerID][strSurveyNum]["LastSubmitTime"] = strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime())
			else:
				print "userText was rate correct?: ", userText
		
		elif (2<=currentConvoNum<=3) & (1<=intUserText<=5):
			print  "QUESTION TWO OR QUESTION 3. PUTTING IN INFO"
			self.json[self.callerID][strSurveyNum][strCurrentConvoNum] = intUserText
			self.busJson[_busName][strCurrentConvoNum] += intUserText
			self.busJson[_busName][str(currentConvoNum+6)] += 1
			nextQuestion = self.pickNextSurveyQuestion(surveyNum, currentConvoNum)
			self.json[self.callerID]["convoNum"] = nextQuestion
			self.json[self.callerID]["currentQuestionNum"] += 1
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
			nextQuestion = self.pickNextSurveyQuestion(surveyNum, currentConvoNum)
			self.json[self.callerID]["convoNum"] = nextQuestion
			self.json[self.callerID]["currentQuestionNum"] += 1
			self.json[self.callerID][strSurveyNum]["LastSubmitTime"] = strftime("%a, %d %b %Y %H:%M:%S GMT", gmtime())
		
		else:
			print "currentConvoNum is greater than 6"

	def pickNextSurveyQuestion(self, surveyNum, currentConvoNum):
		print "CURRENT CONVONUM: ", self.json[self.callerID]["convoNum"]
		remainingQuestions = [q for q in range (2,7) if self.json[self.callerID][str(surveyNum)]["{0}".format(q)] == 0]
		print "remaining questions: ", remainingQuestions
		if remainingQuestions == []:
			print "set is empty. Create new survey"
			return 7
		else:
			try:
				return random.sample(remainingQuestions, 1).pop()
			except:
				return int(currentConvoNum)+1

	### MAIN METHOD
	def runNew(self, userText):
		#Connects to database server in initialized
		print "RUNNEW Method"
		print "callerID from runnew: ", self.callerID
		print "input text: ", userText
		overrideReturnValue = ""
		userTextSplit = userText.split()
		print "USERTEXTSPLIT LEN: ", len(userTextSplit)
		try:
			###Does user exist?
			if self.callerID in self.json:
				print "VERIFY USER EXISTS: USER ALREADY EXISTS"
				print "self.jsonPeopleCallerIDConvoNum", self.json[self.callerID]["convoNum"]
				newUser = False
				callerHashInfo = self.json[self.callerID]
				currentConvoNum = callerHashInfo["convoNum"]
				currentQuestionNum = callerHashInfo["currentQuestionNum"]
				print "LEN OF callerhashInfo: ", len(callerHashInfo)

				if (currentConvoNum>6):
					print "CREATING NEW SURVEY HASH. LAST SURVEY IS FULL"
					self.json[self.callerID]["convoNum"] = 1
					self.json[self.callerID]["currentQuestionNum"] = 1
					newHash = {"LastSubmitTime":0, "1":0, "2":0, "3":0, "4":0, "5":0, "6":0}
					self.json[self.callerID][len(callerHashInfo)-1] = newHash
				else:
					print "NOT CREATING NEW SURVEY HASH"
				surveyNum = len(callerHashInfo)-2 #Note: convoNum and currentQuestionNum item is removed from length
				
				###INPUT TEXT INTO SURVEY
				print "len(userTextSplit): ", len(userTextSplit)
				print "len(userTextSplit)<=1: ", len(userTextSplit) <= 1
				print "userTextSplit[0] is rate?: ", userTextSplit[0]
				print "Conditions are satisfied?: ", (userTextSplit[0] != "rate") & (len(userTextSplit) <= 1)
				if (userTextSplit[0] != "rate") & (len(userTextSplit) <= 1):
					print "Will analyze data"
					self.inputDataToCloudant(currentConvoNum, userText, surveyNum, currentQuestionNum) 

			###NEW USER. Create new account. Disregard input text.
			else:
				print "VERIFY USER EXISTS: CREATE NEW PROFILE"
				newCaller = {"1": {"LastSubmitTime":0, "1":0, "2":0, "3":0, "4":0, "5":0, "6":0}, "convoNum":1, "currentQuestionNum": 1}
				self.json[self.callerID] = newCaller
				newUser = True

			###Processes rate input if valid
			if (userTextSplit[0] == "rate") & (len(userTextSplit) > 1):
				print "running rate function"
				overrideReturnValue = self.getBusRating(userTextSplit[1])


		finally:
			print "OverrideReturnValue :", overrideReturnValue
			print "OverrideTrueTest: ", overrideReturnValue == ""
			currentConvoNum = self.json[self.callerID]["convoNum"]
			currentQuestionNum = self.json[self.callerID]["currentQuestionNum"]
			if overrideReturnValue == "":
				print "overrideReturnValue is null"
				if currentQuestionNum == 1:
					print "currentQuestionNum is == 1. Adding welcome message"
					returnValue = "Welcome to CitiVan! Please answer the following questions."\
								" To see a van's rating, send \"rate (last four digits of license)\"\n{0}{1}"\
								.format(currentQuestionNum, cf.questions[currentConvoNum-1])
				elif currentConvoNum == 7:
					print "currentConvoNum was 7"
					returnValue = "{0}".format(cf.questions[currentConvoNum-1])
				else:
					returnValue = "{0}{1}".format(currentQuestionNum, cf.questions[currentConvoNum-1])
			else:
				returnValue = "{0}{1}{2}".format(overrideReturnValue, str(currentQuestionNum), cf.questions[currentConvoNum-1])

			###Store information into databases
			jsonFormat = self.json
			end_point = "{0}/citivan/{1}/".format(cf.serviceURL, "testSample2")
			r = self.client.r_session.put(end_point, json=jsonFormat)
			print "ENDPT {0}\n".format(r.json())

			###If the user already exists, the bus information should not be added again
			if (newUser == False):
				print "newUser is False"
				busJsonFormat = self.busJson
				end_point_bus = "{0}/citivan/{1}/".format(cf.serviceURL, "busData")
				r_bus = self.client.r_session.put(end_point_bus, json=busJsonFormat)
				print "BUS: {0}\n".format(r_bus.json())

			print "RETURNVALUE :", returnValue
			return returnValue

# if __name__ == '__main__':
# 	s = Server()
# 	while True:
# 		s.main('1234', '')