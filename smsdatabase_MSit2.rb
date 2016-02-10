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

  def getBusName(callerID, userText)
    puts "GETBUSNAME RUNNING"
    puts "VERIFY BUS EXISTS: #{@json["people"]["#{callerID}"]["#{@surveyNum}"]["1"]}"
    @busName = @json["people"]["#{callerID}"]["#{@surveyNum}"]["1"]
    puts "BUSNAME: #{@busName}"
    if @busName.to_s == "0"
      @busName = userText
      if @busJson.has_key?(userText.to_s) == false
        puts "CREATING NEW BUS DATA"
        @busJson["#{userText}"] = {"1" => "#{userText}", "2" => 0, "3" => 0, "4" => 0, "5" => 0, "6" => 0, "7" => 0, "8" => 0, "9" => 0, "10" => 0}
      end
      puts "MAYBE CREATED NEW SURVEY?"
    end
    return @busName
  end

  def calculateAverage(questionNum)
    return avg = (@busJson["#{@busName}"]["#{questionNum}"])/(@busJson["#{@busName}"]["#{questionNum +5}"])
  end

  def runNew(callerID, userText)
    #Connects to database server in initilize

    begin
      ###DOES USER EXIST? If so, then all the other functions are allowed.
      #If this is a new user, disregard the input text and just create a new profile
      if @json["people"].has_key?(callerID.to_s) == true
        puts "VERIFY USER EXISTS: USER ALREADY EXISTS"

        currentConvoNum = @callerHashInfo["convoNum"]
        puts "NUM ITEMS IN CALLERID: #{@callerHashInfo.length}"
        @surveyNum = @callerHashInfo.length-2 #Note: convoNum and noMoreCancel item is removed from length
        overrideReturnValue = nil
        @busJson = getDBData("http://citivan.cloudant.com/citivan/busData/")
        getBusName(callerID, userText)

        #Creates new survey hash if last is full
        if @callerHashInfo["convoNum"] > 5 && userText != "back" && userText != "rate" && userText != "cancel"
          puts "CREATING NEW SURVEY HASH. LAST SURVEY IS FULL"
          @json["people"]["#{callerID}"]["convoNum"] = 1
          @json["people"]["#{callerID}"]["#{@callerHashInfo.length-1}"] = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}

        ###BACK CMD
        #TODO: Remove info from bus database
        elsif userText == "back" && @json["people"]["#{callerID}"]["noMoreCancel"] == false
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

        elsif userText == "back" && @json["people"]["#{callerID}"]["noMoreCancel"] == true
          puts "BACK FUNCTION: overrideReturnValue activated"
          overrideReturnValue = "Sorry, you cannot go back. Please start a new survey by sending another message."

        #fin
        ###RATE CMD
        elsif userText == "rate"
          puts "RATE FUNCTION"
          puts "BUSNAME: #{@busName}"
          if @busJson["#{@busName}"].has_value?(0)
            puts "BUS HAS NOT BEEN RATED YET"
            overrideReturnValue = "This bus has not been rated yet."
          else
            puts "BUS RATING IS THE FOLLOWING"
            overrideReturnValue = "#{@busName} rating:\n"\
            "Quality of ride: #{calculateAverage(2)}\n"\
            "Speeding: #{calculateAverage(3)}\nCourteous: "\
            "#{calculateAverage(4)}\n"\
            "Clean: #{calculateAverage(5)}"
          end

        ###CANCEL CMD
        elsif userText == "cancel"
          puts "CANCEL FUNCTION: Deleted survey"
          @json["people"]["#{callerID}"].delete("#{@surveyNum}")
          #Note: sets convoNum to 6 so a new survey can be created next time the user inputs
          @json["people"]["#{callerID}"]["convoNum"] = 6
          @json["people"]["#{callerID}"]["noMoreCancel"] = true
          @busJson["#{@busName}"]["6"] -= 1
          for i in 2..5
            @busJson["#{@busName}"]["#{i}"] -= @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{i}"]
            @busJson["#{@busName}"]["#{i +5}"] -= 1
          end

        ###INPUT TEXT INTO SURVEY
        #TODO: error handling if NIL
        #TODO: NEED TO CONSIDER THAT THE ANSWERS WILL BE WORDS
        else
          puts "INPUTTING DATA FUNCTION"
          if userText.to_i == 0 && currentConvoNum != 1
            puts "TODO: RUN ERROR MESSAGE"
            raise "incorrectInput"
          else
            puts "INFO INTO SURVEY SYSTEM"
            if @json["people"]["#{callerID}"]["#{@surveyNum}"] == nil
              puts "RAISING NIL ERROR BECAUSE I'M THE WORST"
              raise "nilError"
            else
              puts "BUSNAME: #{@busName}"
              puts "#{@json["people"]["#{callerID}"]["convoNum"]}"
              if @json["people"]["#{callerID}"]["convoNum"] == 1
                puts "INPUT BUS NAME"
                @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"] = userText
              else
                puts "INPUT VALUE"
                @busJson["#{@busName}"]["#{currentConvoNum}"] += userText.to_i
                @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"] = userText.to_i
              end
              @busJson["#{@busName}"]["#{currentConvoNum +5}"] += 1
              @json["people"]["#{callerID}"]["convoNum"] += 1
              @json["people"]["#{callerID}"]["noMoreCancel"] = false
            end
          end

        end
        
        #TODO: CHECK IF ANY OF THE VALUES ARE A 0. IT MEANS THEY MISSED SOMETHING
        #TODO: rescue section. WHAT HAPPENS WHEN TWO SURVEYS HAVE THE SAME NUMBER? CREATE FOR LOOP TO INCREMENT DATA UP

      else ###NEW USER. Create new account. Disregarded input text.
        puts "VERIFY USER EXISTS: CREATE NEW PROFILE"
        newCaller = {"1" => {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}, "convoNum" => 1, "noMoreCancel" => false}
        @json["people"]["#{callerID}"] = newCaller
      end

    rescue => nilError
      puts "NIL ERROR"

    rescue => incorrectInput
      puts "INCORRECT INPUT FOOL"
    
    ensure
      puts "overrideReturnValue: #{overrideReturnValue}"
      if overrideReturnValue == nil
        ###Note: store information into user databases
        returnValue = @json["people"]["#{callerID}"]["convoNum"]
        jsonFormat = @json.to_json
        url = URI.parse("http://citivan.cloudant.com/citivan/testSample/") 
        server = Couch::Server.new(url.host, url.port) 
        server.PUT("http://citivan.cloudant.com/citivan/testSample/", jsonFormat) 

        busJsonFormat = @busJson.to_json
        busUrl = URI.parse("http://citivan.cloudant.com/citivan/busData/") 
        busServer = Couch::Server.new(url.host, url.port) 
        busServer.PUT("http://citivan.cloudant.com/citivan/busData/", busJsonFormat)
      else
        returnValue = overrideReturnValue
      end
      puts "RETURNVALUE: #{returnValue}"
    return returnValue
    
    end #begin/ensureEnd

  end #defEnd

end #citivanServer End

def simulateSMS(callerID, initialText)
  connect = Citivan.new(111222333)
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
    puts "#{status}"
    #Please try again! Reply with \"help\" for a list of commands.
  else #NEED BETTER VERIFICATION SYSTEM FOR YOU CHOSE PART
    puts "You chose #{reply}. #{$questions[status-1.to_i]}"
  end

end


############### Main method starts here:

#Text messages to send to user
  $questions = ["1. What is your bus number?", "2. Pick a number from 1 to 5 to rate the quality of your ride. 1) Very poor. 2) Poor. 3) Average. 4) Good. 5) Excellent.",
  "3. Was your driver speeding? Pick 1 or 2. 1) Yes 2) No.", "4. Was your driver courteous? Pick 1 or 2. 1) Yes 2) No.",
  "5. Was your minibus clean? Pick 1 or 2. 1) Yes 2) No.", "6. Thank you for your responses! Have a great day."]

  ###################Execute code here
  simulateSMS(111222333, "rate")




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