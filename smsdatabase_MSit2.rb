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
  sessions = json["people"]
  puts sessions

  #Find out if CallerID exists
  if sessions.has_key?(callerID.to_s) == true
    puts "ALREADY EXISTS"
  else
    puts "CREATE NEW PROFILE"
    newCaller = {"1" => {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}, "convoNum" => 0}

    json["people"]["#{callerID}"] = newCaller
    puts json
    puts "BREAK--------------------------------------"
  end

  callerHashInfo = json["people"]["#{callerID}"]
  currentConvoNum = callerHashInfo["convoNum"]
  surveyNum = callerHashInfo.length-1 #convoNum item is removed from length

  userText.downcase!
  if userText == "back":
    puts "back function goes here"
  elsif userText == "rate":
    puts "rate function goes here"
  elsif userText == "exit":
    puts "delete section that was created"
  else
    #Verify that the input is a number. If not, run error message
    if userText.to_i == 0
      puts "RUN ERROR MESSAGE"
    else
      puts "put info into the system goes here"
      json["people"]["#{callerID}"][surveyNum.to_s][currentConvoNum.to_s] = userText.to_i
      json["people"]["#{callerID}"]["convoNum"] += 1
    end #if/elseEND

  end #if/elsif/elsif/elseEND
  
  #TODO: CHECK IF ANY OF THE VALUES ARE A 0. IT MEANS THEY MISSED SOMETHING

  jsonFormat = json.to_json
  puts jsonFormat

  url = URI.parse("http://citivan.cloudant.com/citivan/testSample/") 
  server = Couch::Server.new(url.host, url.port) 
  server.PUT("http://citivan.cloudant.com/citivan/testSample/", jsonFormat) 

# #Checks if the callerID exists in the system
#   if sessions["#{callerID}"] == nil
#     puts "CREATE NEW PROFILE FOR PERSON"

#     convoNum = 0
#     timeStamp = Time.now.to_i
#     newValue = {"0" => {"1" => 0, "2" => 0, "3" => 0, "4" => 0, "5" => 0}}

#     newUser = {"callerID"=>"#{callerID}", "arrayIndex"=>"#{arrayIndex}", "convoNum"=>0, "timeStamp" => "#{timeStamp}", "Message" => messages}
#     #not certain if I need to have this here
#     #Produce JSON file from information
#     doc = <<-JSON
#     {"users": #{newUser.to_json}}
#     JSON
#     puts doc

#   else
#     puts "THIS CALLERID ALREADY EXISTS"
#     arrayIndex = sessions["#{callerID}"]["arrayIndex"]
#     convoNum = sessions["#{callerID}"]["convoNum"]
#     messages = sessions["#{callerID}"]["Message"]
#     timeStamp = sessions["#{callerID}"]["timeStamp"]
#   end #if/elseEND

#   ####################goes through second parameter
#   extra.downcase!

#   #If the user sent an incorrect reply to an answer, set the convoNum back one and ask
#   #the question again
#   #NOT YET TESTED
#   if extraFilter == "back"
#     arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i
#     convoNum = sessions["users"][i.to_s]["convoNum"].to_i

#     if convoNum != 0
#       convoNum = sessions["users"][i.to_s]["convoNum"].to_i - 1
#       sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s
#     end

#   else
#     convoNum = sessions["#{callerID}"]["convoNum"] + 1
#     puts convoNum

#     #If all four questions have been asked and recorded, 
#     #increment the array index to start survey again
#     if convoNum == 6
#       arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i + 1
#       sessions["users"][i.to_s]["Message"][arrayIndex.to_i] = {}
      
#       sessions["users"][i.to_s]["arrayIndex"] = (arrayIndex).to_s
#       convoNum = 0           
#       sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s 
#       timeStamp = Time.now.to_i
#       sessions["users"][i.to_s]["Message"][arrayIndex][convoNum] = "#{timeStamp}"
#     else
#       arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i
#       sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s
#       sessions["users"][i.to_s]["Message"][arrayIndex][convoNum] = "#{extra}"
#     end
#   end

end #defEnd


def updateCouchDBData(callerID, extra)
  excep = false

  begin
    #Call the getCounchDBData method to get the database information
    json = getDBData("http://citivan.cloudant.com/citivan/testSample/")
    puts "PUTTING JSON BELOW"
    puts json
    url = URI.parse("http://citivan.cloudant.com/citivan/testSample/") 
    server = Couch::Server.new(url.host, url.port) 
    # if json != nil #####Why would I want to delete the entire database if it's nil?
    #   server.DELETE("http://citivan.cloudant.com/citivan/testSample/")
    #   puts "JSON IS NIL"
    # end
    #server.put("/mainDataBase", "")
    puts "SESSIONS BELOW"
    sessions = json["people"] 
    puts sessions
    failover = sessions

    i = 1
    not_exit = true
    not_found = true
    puts sessions["total"]

    while i <= sessions["total"] && not_exit
      puts "INSIDE WHILE LOOP"
      puts sessions[i.to_s]
      #if callerID == sessions["users"][i.to_s]["callerID"]
      if callerID == sessions["#{callerID}"]
        puts "INSIDE IF STATEMENT"
        not_found = false
        not_exit = false

    #     #If the user sent an incorrect reply to an answer, set the convoNum back one and ask
    #     #the question again
    #     if extra == "back" or extra == "Back"
    #       arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i
    #       convoNum = sessions["users"][i.to_s]["convoNum"].to_i

    #       if convoNum != 0
    #         convoNum = sessions["users"][i.to_s]["convoNum"].to_i - 1
    #         sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s
    #       end
    #     else
    #       #The number exists, increment the conversation number
    #       convoNum = sessions["users"][i.to_s]["convoNum"].to_i + 1

    #       #If all four questions have been asked and recorded, 
    #       #increment the array index to start survey again
    #       if convoNum == 6
    #         arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i + 1
    #         sessions["users"][i.to_s]["Message"][arrayIndex.to_i] = {}
            
    #         sessions["users"][i.to_s]["arrayIndex"] = (arrayIndex).to_s
    #         convoNum = 0           
    #         sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s 
    #         timeStamp = Time.now.to_i
    #         sessions["users"][i.to_s]["Message"][arrayIndex][convoNum] = "#{timeStamp}"
    #       else
    #         arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i
    #         sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s
    #         sessions["users"][i.to_s]["Message"][arrayIndex][convoNum] = "#{extra}"
    #       end
    #     end
      end #ifEnd
      i += 1
    end #whileEnd

    #Number does not exist, create it.  
    if not_found
      puts "NOT FOUND ACTIVATE"
      arrayIndex = 0
      convoNum = 0
      timeStamp = Time.now.to_i
      sessions["total"] = (sessions["total"] + 1)
      messages = Array.new
      messages[arrayIndex] = {}
      #sessions["users"]["#{sessions["total"]}"] = {"callerID"=>"#{callerID}", "arrayIndex"=>"#{arrayIndex}", "convoNum"=>"0", "timeStamp" => "#{timeStamp}", "Message" => messages}
      newUser = {"callerID"=>"#{callerID}", "arrayIndex"=>"#{arrayIndex}", "convoNum"=>"0", "timeStamp" => "#{timeStamp}", "Message" => messages}
    end #ifEnd

    #Produce JSON file from information
    doc = <<-JSON
    {"users": #{newUser.to_json}}
    JSON
    puts "DOC-------------------------------"
    puts doc


  # rescue 
  #   puts "RESCUE TO THE RESCUE"
  #   excep = true
  #   #Check if variable failover is set.
  #   #Update the db only if failover is set.   
  #   if failover == sessions
  #     excep = false
  #     #An exception was thrown, update the DB with the original session
  #     #The original session in this case is in the variable "sessions"
  #     #Get JSON ready
  #     doc = <<-JSON
  #     {"type":"SMS Database","people": #{failover.to_json}}
  #     JSON
  #   end #ifEnd

  ensure
    puts "running ENSURE"
    if failover != nil && sessions != nil && excep == false
       # need to add if failover != null
      #If not, then update the DB with the new information 
      #send the JSON back to the database
      puts doc.strip
      server.PUT("http://citivan.cloudant.com/citivan/testSample/", doc.strip) 
      return convoNum
    end #ifEnd

  end #begin/rescue/ensureEnd
 
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
runNew(555999000, "extra")
runNew(333888000, "extra")