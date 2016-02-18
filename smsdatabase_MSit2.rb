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
    @busName = @json["people"]["#{callerID}"]["#{@surveyNum}"]["1"]
    puts "BUSNAME: #{@busName}"
    if @busName.to_s == "0"
      @busName = userText
      if @busJson.has_key?(userText.to_s) == false && userText.to_s != "back" && userText != "rate" && userText != "cancel" && @json["people"]["#{callerID}"]["noMoreCancel"] == false
        puts "CREATING NEW BUS DATA"
        @busJson["#{userText}"] = {"1" => "#{userText}", "2" => 0, "3" => 0, "4" => 0, "5" => 0, "6" => 0, "7" => 0, "8" => 0, "9" => 0, "10" => 0}
      end
      puts "MAYBE CREATED NEW SURVEY?"
    end
    return @busName
  end

  def calculateAverage(questionNum)
    return avg = (@busJson["#{@busName}"]["#{questionNum}"].to_f)/(@busJson["#{@busName}"]["#{questionNum +5}"])
  end

  def runNew(callerID, userText)
    #Connects to database server in initilize

    begin
      ###DOES USER EXIST? If so, then all the other functions are allowed.
      #If this is a new user, disregard the input text and just create a new profile
      if @json["people"].has_key?(callerID.to_s) == true
        puts "VERIFY USER EXISTS: USER ALREADY EXISTS"
        newUser = false
        byPassOverrideReturnValue = false
        @busJson = getDBData("http://citivan.cloudant.com/citivan/busData/")

#Creates new survey hash if last is full
        if @callerHashInfo["convoNum"] > 5 && userText != "back" && userText != "rate" && userText != "cancel"
          puts "CREATING NEW SURVEY HASH. LAST SURVEY IS FULL"
          @json["people"]["#{callerID}"]["convoNum"] = 1
          @json["people"]["#{callerID}"]["#{@callerHashInfo.length-1}"] = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}
        else
          currentConvoNum = @callerHashInfo["convoNum"]
          puts "NUM ITEMS IN CALLERID: #{@callerHashInfo.length}"
          @surveyNum = @callerHashInfo.length-2 #Note: convoNum and noMoreCancel item is removed from length
          overrideReturnValue = nil

  ###BACK CMD
          # if userText == "back" && @json["people"]["#{callerID}"]["noMoreCancel"] == false
          #   puts "BACK FUNCTION SUCCESS"
          #   if currentConvoNum <= 6 && currentConvoNum > 1
          #     getBusName(callerID, userText)
          #     puts "Previous message sent"
          #     currentConvoNum -= 1
          #     @json["people"]["#{callerID}"]["convoNum"] -= 1
          #     @busJson["#{@busName}"]["#{currentConvoNum +5}"] -= 1
          #     #Note: Removes values from json and busJson
          #     if @json["people"]["#{callerID}"]["convoNum"] == 1
          #       puts "REMOVE BUS NAME and INCORRECT BUS"
          #       @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"] = 0
          #       @busJson.delete("#{@busName}")
          #     else
          #       puts "REMOVE LAST VALUE"
          #       @busJson["#{@busName}"]["#{currentConvoNum}"] -= @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"]
          #       @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"] = 0
          #     end
          #   else
          #     @json["people"]["#{callerID}"]["convoNum"] = 1
          #     puts "Welcome message sent"
          #   end

          # elsif userText == "back" && @json["people"]["#{callerID}"]["noMoreCancel"] == true
          #   puts "BACK FUNCTION: overrideReturnValue activated"
          #   overrideReturnValue = "Sorry, you cannot go back. Please start a new survey by sending another message."

  ###RATE CMD
          elsif userText == "rate"
            puts "RATE FUNCTION"
            getBusName(callerID, userText)
            puts "BUSNAME: #{@busName}"
            if @busJson["#{@busName}"].has_value?(0)
              puts "BUS HAS NOT BEEN RATED YET"
              overrideReturnValue = "This bus has not been rated yet."
            else
              puts "BUS RATING IS THE FOLLOWING"
              overrideReturnValue = "#{@busName} rating:\n"\
              "Quality of ride: #{calculateAverage(2)}\n"\
              "Speeding: #{calculateAverage(3)}\n"\
              "Courteous: #{calculateAverage(4)}\n"\
              "Clean: #{calculateAverage(5)}"
            end

  ###CANCEL CMD
          # elsif userText == "cancel"
          #   puts "CANCEL FUNCTION: Deleted survey"
          #   if @json["people"]["#{callerID}"]["noMoreCancel"] == false
          #     getBusName(callerID, userText)
          #     puts "convoNum #{@json["people"]["#{callerID}"]["convoNum"]}"
          #     #Note: sets convoNum to 6 so a new survey can be created next time the user inputs
          #     @json["people"]["#{callerID}"]["convoNum"] = 6
          #     @json["people"]["#{callerID}"]["noMoreCancel"] = true
          #     puts "jsons are fine"
          #     puts @busJson.keys
          #     puts @busJson.has_key?("#{@busName}")
          #     if @busJson.has_key?("#{@busName}") == true
          #       puts "busJson has key"
          #       @busJson["#{@busName}"]["6"] -= 1
          #       puts "before for loop"
          #       for i in 2..5
          #         puts "inside for loop"
          #         @busJson["#{@busName}"]["#{i}"] -= @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{i}"]
          #         @busJson["#{@busName}"]["#{i +5}"] -= 1
          #       end
          #     end
          #     puts "SurveyNum = #{@surveyNum}"
          #     @json["people"]["#{callerID}"].delete("#{@surveyNum}")
          #     puts "finished with for loops"
          #     byPassOverrideReturnValue = true
          #     overrideReturnValue = "Survey has been discarded. Thanks!"
          #   else
          #     overrideReturnValue = "Sorry, you cannot delete this survey. Please continue this survey."
          #   end

  ###INPUT TEXT INTO SURVEY
          #TODO: error handling if NIL
          else
            puts "INPUTTING DATA FUNCTION"
            #TODO: Revise when the bus ID format is provided
            puts currentConvoNum
            if userText.to_i == 0 && currentConvoNum != 1
              puts "INCORRECT ANSWER FORMAT"
              #FIX: IF THEY SAY YES OR NO, PROMPT THEM TO PUT IN THE NUMBER INSTEAD put in the correct number if they do
              overrideReturnValue = "Sorry, you have entered a wrong choice. Please try again! Reply with \"help\" for options."
            #elsif if it's a different number, limit their answers to either 1 or 2
            else
              puts "INFO INTO SURVEY SYSTEM"
              if @json["people"]["#{callerID}"]["#{@surveyNum}"] == nil
                puts "RAISING NIL ERROR BECAUSE I'M THE WORST"
                raise "nilError"
              else
                getBusName(callerID, userText)
                puts "BUSNAME: #{@busName}"
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
            end #if/ElseEND

          end # elseEND

        end #if/elsif/elsif/elsifEND

 ###NEW USER. Create new account. Disregarded input text.
      else
        puts "VERIFY USER EXISTS: CREATE NEW PROFILE"
        newCaller = {"1" => {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}, "convoNum" => 1, "noMoreCancel" => false}
        @json["people"]["#{callerID}"] = newCaller
        newUser = true
      
      end #begin if/elseEnd

    rescue => nilError
      overrideReturnValue = "Sorry, there is an error with this survey. Please discard this survey by sending \"cancel\" and try again. Reply with \"help\" for more options."
    
    ensure
      puts "overrideReturnValue: #{overrideReturnValue}"
      puts byPassOverrideReturnValue
      puts overrideReturnValue == nil || byPassOverrideReturnValue == true
      if overrideReturnValue == nil || byPassOverrideReturnValue == true
        ###Note: store information into user databases
        if byPassOverrideReturnValue == false
          returnValue = @json["people"]["#{callerID}"]["convoNum"]
        end
        jsonFormat = @json.to_json
        url = URI.parse("http://citivan.cloudant.com/citivan/testSample/") 
        server = Couch::Server.new(url.host, url.port) 
        server.PUT("http://citivan.cloudant.com/citivan/testSample/", jsonFormat) 
        if newUser == false
          busJsonFormat = @busJson.to_json
          busUrl = URI.parse("http://citivan.cloudant.com/citivan/busData/") 
          busServer = Couch::Server.new(url.host, url.port) 
          busServer.PUT("http://citivan.cloudant.com/citivan/busData/", busJsonFormat)
        end
      else
        returnValue = overrideReturnValue
      end
      puts "RETURNVALUE: #{returnValue}"
    return returnValue
    
    end #begin/ensureEnd

  end #defEnd

end #citivanServer End

# def simulateSMS(callerID, initialText)
#   connect = Citivan.new(callerID)
#   #This variable will use the users response to give the appropriate answer
#   reply = initialText.downcase
#   #This variable will correspond to which message should be played
#   status = connect.runNew(callerID, reply)
#   puts "class: #{status.class}"

#   if reply == "help"
#     puts "TEXT MESSAGE BACK"
#     puts "Send \"back\" to go back a question. Send \"rate VanNumber\" to see the ratings of that van. Send \"cancel\" to discard your survey."
#   elsif status.class != String && status.to_i <= 1
#     puts "TEXT MESSAGE BACK"
#     puts "Welcome to CitiVan! Please answer the following questions. Reply with \"help\" for more options."
#     #wait(3000)
#     puts "#{$questions[0]}"
#   elsif status.class != Fixnum
#     puts "TEXT MESSAGE BACK"
#     puts "#{status}"
#   else
#     puts "TEXT MESSAGE BACK"
#     puts "You chose #{reply}. #{$questions[status-1.to_i]}"
#   end

# end


############### Main method starts here:


#FIX: NO QUESTION NUMBERS
#Text messages to send to user
$questions = ["1. What is your bus number?", "2. Pick a number from 1 to 5 to rate the quality of your ride. 1) Very poor. 2) Poor. 3) Average. 4) Good. 5) Excellent.",
"3. Was your driver speeding? Pick 1 or 2. 1) Yes 2) No.", "4. Was your driver courteous? Pick 1 or 2. 1) Yes 2) No.",
"5. Was your minibus clean? Pick 1 or 2. 1) Yes 2) No.", "6. Thank you for your responses! Have a great day."]

###################Execute code here

# puts "Welcome. What is your callerID?"
# caller = gets.chomp!

# continue = true
# while continue == true
#   puts "What is your message?"
#   input = gets.chomp!
#   if input == "stop"
#     break
#   else
#     simulateSMS(8583807847, input)
#   end
# end


#FIX: SOMETIMES FREEZES....?
#FIX: OR REPLY WITH HELP
#FIX: REPEAT THE QUESTION AFTER THE ERROR THING HAPPENS
#FIX: IF CANCEL AND DONOTCANCEL IS TRUE, THEN DO NOT SEND THE ERROR MESSAGE. FIX IT SOMEHOW
#FIX: IF YOU CANCEL, IT RESTARTS AUTOMATICALLY?
#FIX: IF IT SAYS YOU CANNOT DELETE THIS SURVEY, PLEAE CONTINUE WITH SURVEY, SEND QUESTION INSTEAD. NOT ERROR MESSAGE


#Grab the $numToDial parameter and initiate the SMS conversation
log "I HAVE LOGGED THIS MESSAGE"
log "THIS IS THE CURRENT CALLER ID: #{$currentCall.callerID} ---------------------"
log "THIS IS THE CURRENT MESSAGE I RECIEVED: #{$currentCall.initialText} -----------------"
call "+13392044253", { :network => "SMS"}
connect = Citivan.new($currentCall.callerID.to_s)
#This variable will use the users response to give the appropriate answer
log "THIS IS THE CURRENT CALL AFTER CONNECT: #{$currentCall.initialText.downcase}"
reply = $currentCall.initialText.downcase
#This variable will correspond to which message should be played
status = connect.runNew($currentCall.callerID.to_s, reply)

if reply == "help"
  say "Send \"back\" to go back a question. Send \"rate VanNumber\" to see the ratings of that van. Send \"cancel\" to discard your survey."
elsif status.class != String && status.to_i <= 1
  say "Welcome to CitiVan! Please answer the following questions. Reply with \"help\" for more options."
  wait(3000)
  say "#{$questions[0]}"
elsif status.class != Fixnum
  say "#{status}"
else
  say "You chose #{reply}. #{$questions[status-1.to_i]}"
end

hangup