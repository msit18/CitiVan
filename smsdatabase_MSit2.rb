#Original code written by Wajeeha Ahmad and Tawanda Zimuto
#This code is written by Michelle Sit

#Notes:
#When putting values into the hash table, you must input the values into the variable "json".
#If you create a variable to hold the json values and input the values into that variable,
#the values will not transfer to the json that is written into the system.

#For Cloudant, you must include the _id and _rev items to write to the online database

#convoNum behaviors - It must never go to 0 otherwise there will be one too many survey items
#- At 1 = lowest number. back and exit functions should reset to 1. input +1
#- At 5 = back should -1, input should +1
#- At 6 = back should -1 to give last survey item. If input, produce new survey set, reset
#convoNum to 1

#Everything in the json starts from 1 instead of 0. This is to improve readability for
#non-computer science people.

require 'rubygems' 
require 'net/http' 
require 'json' 
 
#This is the HTTP request for CouchDB class 
module Couch 
 
  class Server 
    def initialize(host, port, options = nil) 
      @host = host 
      @port = port 
      @options = options 
    end 

    def request(req) 
      res = Net::HTTP.start(@host, @port) { |http|http.request(req) } 
      unless res.kind_of?(Net::HTTPSuccess) 
        handle_error(req, res) 
      end 
      res 
    end 

    def DELETE(uri) 
      request(Net::HTTP::Delete.new(uri)) 
    end 

    def GET(uri) 
      request(Net::HTTP::Get.new(uri)) 
    end 

    def PUT(uri, json) 
      req = Net::HTTP::Put.new(uri) 
      req["content-type"] = "application/json"
      req.body = json 
      request(req) 
    end 

    def handle_error(req, res) 
      e = RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}") 
      raise e 
    end
  end 

end

class Citivan
  def initialize (callerID)
    @callerID = callerID
    @json = getDBData("http://citivan.cloudant.com/citivan/testSample/")
    @callerHashInfo = @json["people"]["#{callerID}"]
  end

  #This is a helper method to get data from couchDB 
  def getDBData(urlInput)
    url = URI.parse(urlInput)
    server = Couch::Server.new(url.host, url.port)
    res = server.GET(urlInput)
    json = JSON.parse(res.body)
  end

  def deleteBusInfo(callerID)
    puts @json["people"]["#{callerID}"]["#{@surveyNum}"]["1"]
    if @json["people"]["#{callerID}"]["#{@surveyNum}"]["1"] == nil
      puts "not available"
    else
      puts @json["people"]["#{callerID}"]["#{@surveyNum}"]["1"]
    end
  end

  def runNew(callerID, userText)
    #Connects to database server in initilize

    begin
      ###DOES USER EXIST? If so, then all the other functions are allowed.
      #If this is a new user, disregard the input text and just create a new profile
      if @json["people"].has_key?(callerID.to_s) == true
        puts "VERIFY USER EXISTS: USER ALREADY EXISTS"

        #Creates new survey hash if last is full
        if @callerHashInfo["convoNum"] > 5 && userText != "back" && userText != "rate" && userText != "cancel"
          puts "CREATING NEW SURVEY HASH. LAST SURVEY IS FULL"
          @json["people"]["#{callerID}"]["convoNum"] = 1
          @json["people"]["#{callerID}"]["#{callerHashInfo.length}"] = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}
        end

        currentConvoNum = @callerHashInfo["convoNum"]
        puts "CURRENTCONVONUM LENGTH: #{@callerHashInfo.length}"
        @surveyNum = @callerHashInfo.length-2 #Note: convoNum and noMoreCancel item is removed from length
        overrideReturnValue = ""
        busJson = getDBData("http://citivan.cloudant.com/citivan/busData/")

  ##errors following here:
        ###BACK CMD
        #TODO: Remove info from bus database
        if userText == "back" && @json["people"]["#{callerID}"]["noMoreCancel"] == false:
          puts "BACK FUNCTION SUCCESS"
          if currentConvoNum <= 6 && currentConvoNum > 1
            currentConvoNum -= 1
            @json["people"]["#{callerID}"]["convoNum"] -= 1
            # "TODO: Remove info from bus database"
            puts "Previous message sent"
          else
            @json["people"]["#{callerID}"]["convoNum"] = 1
            puts "Welcome message sent"
          end

        elsif userText == "back" && @json["people"]["#{callerID}"]["noMoreCancel"] == true:
          puts "BACK FUNCTION: overrideReturnValue activated"
          overrideReturnValue = "Sorry, you cannot go back. Please start a new survey by sending another message."

        ###RATE CMD
        #TODO: Pull info from bus database
        elsif userText == "rate":
          puts "TODO: rate function goes here"
          deleteBusInfo(callerID)

        ###EXIT CMD
        #TODO: REMOVE VALUES FROM BUS INFO DATABASE
        elsif userText == "cancel":
          puts "CANCEL FUNCTION: Deleted survey"
          @json["people"]["#{callerID}"].delete(surveyNum.to_s)
          #Note: sets convoNum to 6 so a new survey can be created next time the user inputs
          @json["people"]["#{callerID}"]["convoNum"] = 6
          @json["people"]["#{callerID}"]["noMoreCancel"] = true

        ###INPUT TEXT INTO SURVEY
        #TODO: run error message
        #TODO: error handling if NIL
        #TODO: put info into the bus database
        #TODO: NEED TO CONSIDER THAT THE ANSWERS WILL BE WORDS
        else
          puts "INPUTTING DATA FUNCTION"
          #TODO: Verify that the input is appropriate. If not, run error message
          if userText.to_i == 0 && currentConvoNum != 1
            puts "TODO: RUN ERROR MESSAGE"
          else
            puts "INFO INTO SURVEY SYSTEM"
            if @json["people"]["#{callerID}"][surveyNum.to_s] == nil
              raise "nilError"
            else
              @json["people"]["#{callerID}"][surveyNum.to_s][currentConvoNum.to_s] = userText.to_i
              @json["people"]["#{callerID}"]["convoNum"] += 1
              @json["people"]["#{callerID}"]["noMoreCancel"] = false
              puts "TODO: put info into the bus database"
            end
          end

        end
        
        #TODO: CHECK IF ANY OF THE VALUES ARE A 0. IT MEANS THEY MISSED SOMETHING

      ###NEW USER. Create new account. Disregarded input text.
      else
        puts "VERIFY USER EXISTS: CREATE NEW PROFILE"
        newCaller = {"1" => {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}, "convoNum" => 1, "noMoreCancel" => false}
        @json["people"]["#{callerID}"] = newCaller
      end

    rescue => nilError
      puts "NIL ERROR"

    #TODO: rescue section. WHAT HAPPENS WHEN TWO SURVEYS HAVE THE SAME NUMBER? CREATE FOR LOOP TO INCREMENT DATA UP
    #WHAT HAPPENS WHEN A SURVEY ITEM IS INCORRECT? MAKE SURE IT GETS REMOVED AND QUESTION GETS ASKED AGAIN

    ensure
      puts "overrideReturnValue: #{overrideReturnValue}"
      if overrideReturnValue == ""
        ###Note: store information into user database
        returnValue = @json["people"]["#{callerID}"]["convoNum"]
        jsonFormat = @json.to_json
        url = URI.parse("http://citivan.cloudant.com/citivan/testSample/") 
        server = Couch::Server.new(url.host, url.port) 
        server.PUT("http://citivan.cloudant.com/citivan/testSample/", jsonFormat) 
      else
        returnValue = overrideReturnValue
      end
      puts "RETURNVALUE: #{returnValue}"
      puts returnValue.class
    return returnValue
    
    end #begin/ensureEnd

  end #defEnd

end #citivanServer End


#TODO: NEED A WAY TO SEND ERROR MESSAGE TO USERS IF THEIR ANSWER IS NOT INPUTED
#TODO: DON'T NEED TO SEND WELCOME MESSAGE EVERY SINGLE TIME THE SURVEY STARTS
def simulateSMS(callerID, initialText)
  connect = Citivan.new(8583807847)
  #This variable will use the users response to give the appropriate answer
  reply = initialText.downcase
  #This variable will correspond to which message should be played
  status = connect.runNew(callerID, reply)

  if reply == "help"
    puts "Send \"back\" to go back a question. Send \"rate VanNumber\" to see the ratings of that van. Send \"cancel\" to discard your survey."
  elsif reply == "cancel"
    puts "Your current survey has been deleted. Thank you!"
  elsif status == 1
    puts "Welcome to CitiVan! Please answer the following questions." #TODO: ADD MORE INFO ABOUT FUNCTIONS
    #wait(3000)
    puts "#{$questions[status-1.to_i]}"
  elsif status.class != Fixnum
    puts "Sorry, you have entered a wrong choice. Please try again! Reply with \"help\" for a list of commands."
  else #NEED BETTER VERIFICATION SYSTEM FOR YOU CHOSE PART
    puts "You chose #{reply}. #{$questions[status-1.to_i]}"
  end

end


############### Main method starts here:

#Text messages to send to user
  messages = [
  {"1"=>"Welcome to CitiVan! Please answer the following questions.",
  "message"=> "1. What is your bus number?"},
   
  {"value" => "Your bus number is ", 
  "message" => "2. Pick a number from 1 to 5 to rate the quality of your ride. 1) Very poor. 2) Poor. 3) Average. 4) Good. 5) Excellent."}, 
   
  {"1" => "You chose 1.", 
  "2"=>"You chose 2.", 
  "3" => "You chose 3.", 
  "4" => "You chose 4.",
  "5" => "You chose 5.",
  "message"=>"3. Was your driver speeding? Pick 1 or 2. 1) Yes 2) No."},
   
  {"1"=>"You chose 1.", 
  "2"=>"You chose 2.",
  "message"=>"4. Was your driver courteous? Pick 1 or 2. 1) Yes 2) No."},
   
  {"1"=>"You chose 1.", 
  "2"=>"You chose 2.",
  "message"=>"5. Was your minibus clean? Pick 1 or 2. 1) Yes 2) No."},
   
  {"1"=>"You chose 1.", 
  "2"=>"You chose 2.",
  "message"=>"6. Thank you for your responses! Have a great day."}
  ]

  $questions = ["1. What is your bus number?", "2. Pick a number from 1 to 5 to rate the quality of your ride. 1) Very poor. 2) Poor. 3) Average. 4) Good. 5) Excellent.",
  "3. Was your driver speeding? Pick 1 or 2. 1) Yes 2) No.", "4. Was your driver courteous? Pick 1 or 2. 1) Yes 2) No.",
  "5. Was your minibus clean? Pick 1 or 2. 1) Yes 2) No.", "6. Thank you for your responses! Have a great day."]

  ###################Execute code here
  simulateSMS(8583807847, "rate")

# if currentCall
#   #This variable will use the users response to give the appropriate answer
#   reply = currentCall.initialText.downcase!
#   #This variable will correspond to which message should be played
#   status = runNew(currentCall.callerID, reply)
#   puts status

#   if reply == "help"
#     say "Send \"back\" to go back a question. Send \"rate VanNumber\" to see the ratings of that van. Send \"exit\" to discard your answers and start over."
#   elsif status == 1
#     say "Welcome to CitiVan! Please answer the following questions." #TODO: ADD MORE INFO ABOUT FUNCTIONS
#     wait(3000)
#     say "#{questions[status-1.to_i]}"
#   else #NEED BETTER VERIFICATION SYSTEM FOR YOU CHOSE PART
#     say "You chose #{reply}. #{questions[status-1.to_i]}"

#   end

#   hangup


#   # if $status == 1
#   #     say "#{messages[$status.to_i]['value']} #{reply}. #{messages[$status.to_i]['message']}"
  
#   # #If this is a new user, send the first message out, create the user and start the first session.
#   # elsif $status == 0
#   # #This sends the initial message with the first question
#   #   say "#{messages[$status.to_i]['1']}"
#   #   wait(3000)
#   #   say "#{messages[$status.to_i]['message']}"
#   # else
#   #   #If the user responds with an answer that does not correspond to my answers,
#   #   #It will ask the question again
#   #   if messages[$status.to_i][$reply] == nil 
#   #     $newStatus = runNew($currentCall.callerID, "back") 
#   #     say "Sorry, you have entered a wrong choice. #{messages[$newStatus.to_i]['message']}" 
#   #   else
#   #     say "#{messages[$status.to_i][$reply]} #{messages[$status.to_i]['message']}"
#   #   end
#   # end
  
#   # #There is no reason to keep the session alive, so we hangup 
#   # hangup
 
# else  
#   #Grab the $numToDial parameter and initiate the SMS conversation
#   event = call(numToDial, {:network => "SMS"})
   
#   #This primarily updates the database with the new number. This variable should always be 0.
#   status = runNew(numToDial, currentCall.initialText)
  
#   #This sends the initial message with the first question
#   say "Welcome to CitiVan! Please answer the following questions."
#   wait(3000)
#   say "#{questions[status-1.to_i]}"
  
#   #There is no reason to keep the session alive, so we hangup 
#   hangup
 
# end








# def runthething(callerID, extra)
#   puts "---------------------------------------------------"
#   #json = getCounchDBData
#   json = getDBData("http://citivan.cloudant.com/citivan/_all_docs?")
#   puts "PUTTING JSON BELOW"
#   puts json
#   url = URI.parse("http://citivan.cloudant.com/citivan/") 
#   server = Couch::Server.new(url.host, url.port)

#   puts "SESSIONS BELOW"
#   sessions = json["people"] 
#   puts sessions

#   i = 1
#   puts sessions["total"]

#   puts "NOT FOUND ACTIVATE"
#   arrayIndex = 0
#   convoNum = 0
#   timeStamp = Time.now.to_i
#   sessions["total"] = (sessions["total"] + 1)
#   messages = Array.new
#   messages[arrayIndex] = {}
#   #sessions["users"]["#{sessions["total"]}"] = {"callerID"=>"#{callerID}", "arrayIndex"=>"#{arrayIndex}", "convoNum"=>"0", "timeStamp" => "#{timeStamp}", "Message" => messages}
#   newUser = {"callerID"=>"#{callerID}", "arrayIndex"=>"#{arrayIndex}", "convoNum"=>"0", "timeStamp" => "#{timeStamp}", "Message" => messages}
#   puts "NEW USER"
#   puts newUser
#   puts newUser.to_json

#   puts "VARRRRRR"
#   var = sessions["total"]+1
#   puts var
#   puts json
#   puts json["people"]["total"]
#   json["people"]["total"] = var
#   puts json

#   idNum = json["_id"]
#   puts idNum
#   revNum = json["_rev"]
#   puts revNum

#   doc = <<-JSON
#   {"_id": #{idNum.to_json},
#   "_rev": #{revNum.to_json},
#   "people": {
#     "total": #{var.to_json},
#     "#{callerID}": #{newUser.to_json}}
#   }
#   JSON

#   puts doc

#   server.PUT("http://citivan.cloudant.com/citivan/testSample/", doc)

# end

# def tryAdd (callerID, extra)
#   json = getDBData("http://citivan.cloudant.com/citivan/mainDataBase/")
#   puts json
#   puts "JSON----------------------------------------"
#   sessions = json["people"]["users"]
#   puts sessions
#   puts sessions.length+1
#   puts "SESSIONS------------------------------------"

#   newValue = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}

#   json["people"]["users"]["#{sessions.length+1}"] = newValue
#   puts json
#   jsonFormat = json.to_json
#   puts jsonFormat

#   url = URI.parse("http://citivan.cloudant.com/citivan/testSample/") 
#   server = Couch::Server.new(url.host, url.port) 
#   server.PUT("http://citivan.cloudant.com/citivan/mainDataBase/", jsonFormat) 


# end