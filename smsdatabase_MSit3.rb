#This code is written by Michelle Sit

#Notes:
#When putting values into the hash table, you must input the values into the variable "json".
#If you create a variable to hold the json values and input the values into that variable,
#the values will not transfer to the json that is written into the system.

#For Cloudant, you must include the _id and _rev items to write to the online database

#convoNum behaviors - It must never go to 0 otherwise there will be one too many survey items
#- At 1 = lowest number. input +1
#- At 5 = input should +1
#- At 6 = If input, produce new survey set, reset convoNum to 1

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
    @json = getDBData("http://citivan.cloudant.com/citivan/testSample2/")
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
      if @busJson.has_key?(userText.to_s) == false && userText != "rate"
        puts "CREATING NEW BUS DATA"
        @busJson["#{userText}"] = {"1" => "#{userText}", "2" => 0, "3" => 0, "4" => 0, "5" => 0, "6" => 0, "7" => 0, "8" => 0, "9" => 0, "10" => 0}
      end
      puts "MAYBE CREATED NEW SURVEY?"
    end
    return @busName
  end

  def calculateAverage(inputBusName, questionNum)
    return avg = (@busJson["#{inputBusName}"]["#{questionNum}"].to_f)/(@busJson["#{inputBusName}"]["#{questionNum +5}"])*100
  end

  def runNew(callerID, userText)
    #Connects to database server in initilize

    begin
      ###DOES USER EXIST? If so, then all the other functions are allowed.
      #If this is a new user, disregard the input text and just create a new profile
      if @json["people"].has_key?(callerID.to_s) == true
        puts "VERIFY USER EXISTS: USER ALREADY EXISTS"
        newUser = false
        @busJson = getDBData("http://citivan.cloudant.com/citivan/busData/")

#Creates new survey hash if last is full
        if @callerHashInfo["convoNum"] > 5 && userText != "rate"
          puts "CREATING NEW SURVEY HASH. LAST SURVEY IS FULL"
          @json["people"]["#{callerID}"]["convoNum"] = 1
          @json["people"]["#{callerID}"]["#{@callerHashInfo.length-1}"] = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}
        else
          currentConvoNum = @callerHashInfo["convoNum"]
          puts "NUM ITEMS IN CALLERID: #{@callerHashInfo.length}"
          @surveyNum = @callerHashInfo.length-1 #Note: convoNum item is removed from length
          overrideReturnValue = nil

  ###RATE CMD
          if userText.start_with?("rate ") == true
            puts "RATE FUNCTION"
            puts userText
            puts userText.slice!(0..4)
            puts rateBusName = userText
            puts @busJson.has_key?(rateBusName)
            puts @busJson["#{rateBusName}"]
            if @busJson.has_key?(rateBusName) == false
              puts "BUS HAS NOT BEEN RATED YET"
              overrideReturnValue = "The bus #{rateBusName} has not been rated yet."
            elsif @busJson["#{rateBusName}"]["10"] == 0
              overrideReturnValue = "The bus #{rateBusName} has not been rated yet."
            else
              puts "BUS RATING IS THE FOLLOWING"
              question2Answer = calculateAverage(rateBusName, 2)/100
              overrideReturnValue = "Rating for #{rateBusName} from #{@busJson[rateBusName]["10"]} riders:\n"\
              "Avg quality of ride: #{question2Answer}/5\n"\
              "#{calculateAverage(rateBusName, 3)}% think the driver speeds.\n"\
              "#{calculateAverage(rateBusName, 4)}% think the driver is courteous.\n"\
              "#{calculateAverage(rateBusName, 5)}% think the van is clean."
            end

  ###INPUT TEXT INTO SURVEY
          #TODO: error handling if NIL
          else
            puts "INPUTTING DATA FUNCTION"
            #TODO: Revise when the bus ID format is provided
            puts currentConvoNum
            getBusName(callerID, userText)
            puts userText
            #All the incorrect inputs
            if currentConvoNum == 1
              puts "FIRST QUESTION. PUTTING BUS NAME INTO THE SYSTEM"
              @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"] = userText
              @busJson["#{@busName}"]["#{currentConvoNum +5}"] += 1
              @json["people"]["#{callerID}"]["convoNum"] += 1
            elsif currentConvoNum == 2 && userText.to_i.between?(1,5) == true
              puts "QUESTION TWO. PUTTING IN INFO"
              @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"] = userText.to_i
              @busJson["#{@busName}"]["#{currentConvoNum}"] += userText.to_i
              @busJson["#{@busName}"]["#{currentConvoNum +5}"] += 1
              @json["people"]["#{callerID}"]["convoNum"] += 1
            elsif currentConvoNum > 2 && (userText.to_s == "yes" || userText.to_s == "no" || userText.to_i.between?(1,2))
              puts "QUESTIONS THREE THROUGH FIVE. PUTTING IN INFO"
              if userText.to_s == "yes" || userText.to_i == 1
                @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"] = "yes"
                @busJson["#{@busName}"]["#{currentConvoNum}"] += 1
              elsif userText.to_s == "no" || userText.to_i == 2
                @json["people"]["#{callerID}"]["#{@surveyNum}"]["#{currentConvoNum}"] = "no"
                #Does not add to busJson question number if the answer is no
              end
              @busJson["#{@busName}"]["#{currentConvoNum +5}"] += 1
              @json["people"]["#{callerID}"]["convoNum"] += 1
            else
              #Repeat question
            end #if/elsif/elsif/elsif/else END

          end # elseEND

        end #if/elsif/elsif/elsifEND

 ###NEW USER. Create new account. Disregarded input text.
      else
        puts "VERIFY USER EXISTS: CREATE NEW PROFILE"
        newCaller = {"1" => {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}, "convoNum" => 1}
        @json["people"]["#{callerID}"] = newCaller
        newUser = true
      
      end #begin if/elseEnd
    
    ensure
      puts "overrideReturnValue: #{overrideReturnValue}"
      puts overrideReturnValue == nil
      if overrideReturnValue == nil
        ###Note: store information into user databases
        returnValue = @json["people"]["#{callerID}"]["convoNum"]
        jsonFormat = @json.to_json
        url = URI.parse("http://citivan.cloudant.com/citivan/testSample2/") 
        server = Couch::Server.new(url.host, url.port) 
        server.PUT("http://citivan.cloudant.com/citivan/testSample2/", jsonFormat) 
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

def simulateSMS(callerID, initialText)
  connect = Citivan.new(callerID)
  reply = initialText.downcase
  status = connect.runNew(callerID, reply)
  puts "TEXT BACK"

  if status.class != String && status.to_i <= 1
    puts "Welcome to CitiVan! Please answer the following questions. To see the ratings of a van, send: \"RATE (insert VanNumber)\""
    #wait(3000)
    puts "#{$questions[0]}"
  elsif status.class != Fixnum
    puts "#{status}"
  else
    puts "#{$questions[status-1.to_i]}"
  end

end


############### Main method starts here:


#Text messages to send to user
$questions = ["What is your bus number?", "Pick a number from 1 to 5 to rate the quality of your ride. 1) Very poor. 2) Poor. 3) Average. 4) Good. 5) Excellent.",
"Was your driver speeding? Enter 1 for yes or 2 for no.", "Was your driver courteous? Enter 1 for yes or 2 for no.",
"Was your minibus clean? Enter 1 for yes or 2 for no.", "Thank you for your responses! Have a great day."]

###################Execute code here

# puts "Welcome. What is your callerID?"
# caller = gets.chomp!

continue = true
while continue == true
  puts "What is your message?"
  input = gets.chomp!
  if input == "stop"
    break
  else
    simulateSMS(8583807847, input)
  end
end


#FIX: OR REPLY WITH HELP
#FIX: REPEAT THE QUESTION AFTER THE ERROR THING HAPPENS


# call "+13392044253", { :network => "SMS"}
# connect = Citivan.new($currentCall.callerID.to_s)
# reply = $currentCall.initialText.downcase
# status = connect.runNew($currentCall.callerID.to_s, reply)

# if status.class != String && status.to_i <= 1
#   say "Welcome to CitiVan! Please answer the following questions. To see the ratings of a van, send \"rate VanNumber\""
#   wait(3000)
#   say "#{$questions[0]}"
# elsif status.class != Fixnum
#   say "#{status}"
# else
#   say "#{$questions[status-1.to_i]}"
# end

# hangup