#Original code written by Wajeeha Ahmad and Tawanda Zimuto
#Major edits by Michelle Sit

#Notes:
#When putting values into the hash table, you must input the values into the variable "json".
#If you create a variable to hold the json values and input the values into that variable,
#the values will not transfer to the json that is written into the system.
#ex - session = json["people"]. If you assign a value to session["someCategory"], it will not
#be stored in the json that is written.

#For Cloudant, you must include the _id and _rev to write to the online database

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
      puts uri
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
 
#This is a helper method to get data from couchDB 
def getDBData(urlInput)
  puts "RUNNING getDBData"
  url = URI.parse(urlInput)
  server = Couch::Server.new(url.host, url.port)
  res = server.GET(urlInput)
  json = JSON.parse(res.body)
end

def runthething(callerID, extra)
  puts "---------------------------------------------------"
  #json = getCounchDBData
  json = getDBData("http://citivan.cloudant.com/citivan/_all_docs?")
  puts "PUTTING JSON BELOW"
  puts json
  url = URI.parse("http://citivan.cloudant.com/citivan/") 
  server = Couch::Server.new(url.host, url.port)

  puts "SESSIONS BELOW"
  sessions = json["people"] 
  puts sessions

  i = 1
  puts sessions["total"]

  puts "NOT FOUND ACTIVATE"
  arrayIndex = 0
  convoNum = 0
  timeStamp = Time.now.to_i
  sessions["total"] = (sessions["total"] + 1)
  messages = Array.new
  messages[arrayIndex] = {}
  #sessions["users"]["#{sessions["total"]}"] = {"callerID"=>"#{callerID}", "arrayIndex"=>"#{arrayIndex}", "convoNum"=>"0", "timeStamp" => "#{timeStamp}", "Message" => messages}
  newUser = {"callerID"=>"#{callerID}", "arrayIndex"=>"#{arrayIndex}", "convoNum"=>"0", "timeStamp" => "#{timeStamp}", "Message" => messages}
  puts "NEW USER"
  puts newUser
  puts newUser.to_json

  puts "VARRRRRR"
  var = sessions["total"]+1
  puts var
  puts json
  puts json["people"]["total"]
  json["people"]["total"] = var
  puts json

  idNum = json["_id"]
  puts idNum
  revNum = json["_rev"]
  puts revNum

  doc = <<-JSON
  {"_id": #{idNum.to_json},
  "_rev": #{revNum.to_json},
  "people": {
    "total": #{var.to_json},
    "#{callerID}": #{newUser.to_json}}
  }
  JSON

  puts doc

  server.PUT("http://citivan.cloudant.com/citivan/testSample/", doc)

end

def tryAdd (callerID, extra)
  json = getDBData("http://citivan.cloudant.com/citivan/mainDataBase/")
  puts json
  puts "JSON----------------------------------------"
  sessions = json["people"]["users"]
  puts sessions
  puts sessions.length+1
  puts "SESSIONS------------------------------------"

  newValue = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}

  json["people"]["users"]["#{sessions.length+1}"] = newValue
  puts json
  jsonFormat = json.to_json
  puts jsonFormat

  url = URI.parse("http://citivan.cloudant.com/citivan/testSample/") 
  server = Couch::Server.new(url.host, url.port) 
  server.PUT("http://citivan.cloudant.com/citivan/mainDataBase/", jsonFormat) 


end

def runNew(callerID, userText)
  #Connects to Cloudant user database
  json = getDBData("http://citivan.cloudant.com/citivan/testSample/")
  callerHashInfo = json["people"]["#{callerID}"]
  userText.downcase!

  #Find out if CallerID exists. Create profile if not
  if json["people"].has_key?(callerID.to_s) == true
    puts "ALREADY EXISTS"
    if callerHashInfo["convoNum"] > 5 && userText != "back"
      puts "IF STATEMENT RUNNING"
      json["people"]["#{callerID}"]["convoNum"] = 0
      json["people"]["#{callerID}"]["#{callerHashInfo.length}"] = {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}
    end
  else
    puts "CREATE NEW PROFILE"
    newCaller = {"1" => {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}, "convoNum" => 0}
    json["people"]["#{callerID}"] = newCaller
  end #if/elseEND

  currentConvoNum = callerHashInfo["convoNum"]
  surveyNum = callerHashInfo.length-1 #convoNum item is removed from length

  #Could put in a while loop in this method

  #BACK CMD
  if userText == "back":
    puts "BACK FUNCTION"
    if currentConvoNum <= 6 && currentConvoNum > 0
      currentConvoNum -= 1
      json["people"]["#{callerID}"]["convoNum"] -= 1
      puts "TODO: trigger previous message"
    else
      json["people"]["#{callerID}"]["convoNum"] = 0
      puts "TODO: trigger welcome message"

    end

  #RATE CMD
  elsif userText == "rate":
    puts "TODO: rate function goes here"

  elsif userText == "exit":
    puts "TODO: delete section that was created"
  else
    #Verify that the input is a number. If not, run error message
    if userText.to_i == 0
      puts "RUN ERROR MESSAGE"
    else
      puts "put info into the system"
      json["people"]["#{callerID}"][surveyNum.to_s][currentConvoNum.to_s] = userText.to_i
      json["people"]["#{callerID}"]["convoNum"] += 1
      #put info into the bus database
    end #if/elseEND

  end #if/elsif/elsif/elseEND
  
  #TODO: CHECK IF ANY OF THE VALUES ARE A 0. IT MEANS THEY MISSED SOMETHING

  jsonFormat = json.to_json
  puts jsonFormat

  url = URI.parse("http://citivan.cloudant.com/citivan/testSample/") 
  server = Couch::Server.new(url.host, url.port) 
  server.PUT("http://citivan.cloudant.com/citivan/testSample/", jsonFormat) 

end #defEnd


###Main method starts here:

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

#Execute code here
#tryAdd(777999000, "extra")
#updateCouchDBData(666999000, "extra")
#runNew(555999000, "back")
runNew(111888000, "input")
#runNew(333888000, "back")