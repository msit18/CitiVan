#Original code written by Wajeeha Ahmad and Tawanda Zimuto
#Major reconstruction edits by Michelle Sit

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
 
    def DELETE(uri) 
      request(Net::HTTP::Delete.new(uri)) 
    end 
 
    def GET(uri) 
      request(Net::HTTP::get.new(uri)) 
    end 
 
    def PUT(uri, json) 
      req = Net::HTTP::Put.new(uri) 
      req["content-type"] = "application/json"
      req.body = json 
      request(req) 
    end 
 
    def request(req) 
      res = Net::HTTP.start(@host, @port) { |http|http.request(req) } 
      unless res.kind_of?(Net::HTTPSuccess) 
        handle_error(req, res) 
      end 
      res 
    end 
 
    private 
 
    def handle_error(req, res) 
      e = RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}") 
      raise e 
    end 
  end 
end
 
#This is a helper method to get data from couchDB 
def getCounchDBData 
  url = URI.parse("http://citivan.cloudant.com/mainDataBase/")
  server = Couch::Server.new(url.host, url.port) 
  res = server.get("/") 
  json = res.body 
  json = JSON.parse(json) 
end
 
def updateCouchDBData(callerID, extra)

    excep = false
 
    begin     
        #Call the getCounchDBData method to get the database information
        log "***************************** BEFORE JSON *************************"
        json = getCounchDBData 
        log "***************************** JSON IS SET *************************"
        url = URI.parse("http://citivan.cloudant.com/mainDataBase/") 
        server = Couch::Server.new(url.host, url.port) 
        log "***************************** NEW SERVER **************************"
        if json != nil
            server.delete("/sms")
            log "******************** SERVER DELETED ***************************"
        server
        end.put("/sms", "") 
        log "************************ SERVER WAS PUT ***************************"
        sessions = json["people"] 
        log "***************************** SESSIONS IS SET *********************"
        failover = sessions
        log "***************************** FAILOVER IS SET ******************"
 
        i = 1
        not_exit = true
        not_found = true
 
        while i <= sessions["total"].to_i && not_exit
            log "****************** WHILE LOOP BEGUN ********************"
 
            if callerID == sessions["users"][i.to_s]["callerID"]
 
                not_found = false
                not_exit = false
 
                #If the user sent an incorrect reply to an answer, set the convoNum back one and ask
                #the question again
                if extra == "back" or extra == "Back"
                    arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i
                    convoNum = sessions["users"][i.to_s]["convoNum"].to_i
 
                    if convoNum != 0
                        convoNum = sessions["users"][i.to_s]["convoNum"].to_i - 1
                        sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s
                    end
                    log "******************** UNDER EXTRA **********************"
                else
                    #The number exists, increment the conversation number
                    convoNum = sessions["users"][i.to_s]["convoNum"].to_i + 1
        
                    #If all four questions have been asked and recorded, 
                    #increment the array index to start survey again
                    if convoNum == 6
                        arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i + 1
                        sessions["users"][i.to_s]["Message"][arrayIndex.to_i] = {}
                        
                        sessions["users"][i.to_s]["arrayIndex"] = (arrayIndex).to_s
                        convoNum = 0           
                        sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s 
                        timeStamp = Time.now.to_i
                        sessions["users"][i.to_s]["Message"][arrayIndex][convoNum] = "#{timeStamp}"
                    else
                        arrayIndex = sessions["users"][i.to_s]["arrayIndex"].to_i
                        sessions["users"][i.to_s]["convoNum"] = (convoNum).to_s
                        sessions["users"][i.to_s]["Message"][arrayIndex][convoNum] = "#{extra}"
                    end
                    log "******************** UNDER EXTRA ELSE *********************"
                end
            end
            i += 1
        end    
 
        #Number does not exists, create it.  
        if not_found
            arrayIndex = 0
            convoNum = 0
            timeStamp = Time.now.to_i
            sessions["total"] = (sessions["total"].to_i + 1).to_s
            messages = Array.new
            messages[arrayIndex] = {}
            sessions["users"]["#{sessions["total"]}"] = {"callerID"=>"#{callerID}", "arrayIndex"=>"#{arrayIndex}", "convoNum"=>"0", "timeStamp" => "#{timeStamp}", "Message" => messages}
        log "************************ NOT FOUND ********************************"
        end  
        
        log "******************BEGIN IS HERE ***********"
        
        #Get JSON ready
        doc = <<-JSON
        {"type":"SMS Database","people": #{sessions.to_json}}
        JSON
        
    
    rescue 
        excep = true
        log "************************ UNDER RESCUE ****************************"
        #Check if variable failover is set.
        #Update the db only if failover is set.   
        if failover == sessions
            log "********************* UNDER RESCUE IF **********************"
            excep = false
            #An exception was thrown, update the DB with the original session
            #The original session in this case is in the variable "sessions"
            #Get JSON ready
            doc = <<-JSON
            {"type":"SMS Database","people": #{failover.to_json}}
            JSON
        
        end
            
    ensure
        log "****************** BEFORE ENSURE IF ***************************"
        if failover != nil && sessions != nil && excep == false 
            # need to add if failover != null
            log "****************** AFTER ENSURE IF ************************"
            #If not, then update the DB with the new information 
            #send the JSON back to the database
            server.put("/sms/currentUsers", doc.strip) 
            return convoNum
        end
    end
end
 
#Main method :
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
 
if $currentCall
    
    log "*********** GETTING CURRENT CALL *************************"
    
    #This variable will use the users response to give the appropriate answer
    #Also note, I downcased the initial text so capitalization won't matter
    $reply = $currentCall.initialText
    $replyLower = $reply.downcase!
    
    log "************** REPLY RECEIVED **************"
    
    if $replyLower == 'rate'
        log "****************** REPLY IS RATE *******************"
        session = getCounchDBData
        log "***************** GETS COUCHDB DATA *************************"
        busCount = 0 
        quality = 0 
        speeding = 0 
        courtesy = 0 
        cleanliness = 0
        
        busNum = $replyLower.split(" ").last
        log " ******************** busNum below ********************* "
        log " ******************** The busNum is - #{busNum} ********************** "
        
        
        #Go through "people" to get to "users"
        session["people"]["users"].keys.each {|user|
            #ratings = user["Message"]
            log "************** GETS RATINGS FOR THE USER *******************"
            
            session["people"]["users"][user]["Message"].each{|rating|
                log "*************** FOR RATING IN RATINGS *********************"
                log " ********* This is the rating variable - #{rating} **********"
                
                busIndex = rating.keys[1]
                log " ************** The Bus Index is - #{busIndex} ****************** "
                
                currentBusNum = rating[busIndex]
                log " ************** The Current Bus No. is - #{currentBusNum} ****************** "
                
                if busNum == currentBusNum
                log " ***************** busNum EXISTS IN DB!!!!! *************** "
                    busCount += 1
                    log " ************ busCount was incremented **************** "
                    
                    log " *********** This is quality rating INDEX - #{rating.keys[2]} **********"
                    
                    log " *********** This is quality rating VALUE - #{rating[rating.keys[2]]} **********"
                    
                    quality += (rating[rating.keys[2]]).to_i
                    log "******** quality - #{quality} ****************"
                    
                    speeding += (rating[rating.keys[3]]).to_i
                    log " ********* speeding - #{speeding} ************"
                    
                    courtesy += (rating[rating.keys[4]]).to_i 
                    log " ********** courtesy - #{courtesy} **************"
                    
                    cleanliness += (rating[rating.keys[5]]).to_i
                    log " ********** cleanliness - #{cleanliness} ************"
                    
                end
            }
        }
        
        #for user in session["people"]["users"].keys
            #log "************ FOR USER IN SESSION *************************"
            #log "#{user}"
            
            #ratings = user["Message"] 
            #log "************** GETS RATINGS FOR THE USER *******************"
            
            #Iterate through all the users and hit "Messages"
            #for rating in ratings 
            #log "*************** FOR RATING IN RATINGS *********************"
            #log "#{rating}"
                
                #busIndex = rating.keys[1]
                #currentBusNum = rating[busIndex]
                
                #if busNum == currentBusNum
                #log "***************** nusNum EXISTS IN DB!!!!! ***************"
                    
                    #busCount += 1
                    #quality += rating[rating.keys[2]]
                    #speeding += rating[rating.keys[3]]
                    #courtesy += rating[rating.keys[4]] 
                    #cleanliness += rating[rating.keys[5]]
                #end 
            #end
        #end
        
        if busCount == 0 
            say "Sorry, bus not found." 
        else
            log "************* BUS FOUND *****************"
            avg_quality = quality/busCount 
            avg_speeding = speeding/busCount 
            avg_courtesy = courtesy/busCount 
            avg_cleanliness = cleanliness/busCount 
            say "Ride quality: " + (avg_quality).to_s + "\n Driver speeding: " + (avg_speeding).to_s + "\n Driver courtesy: " + (avg_courtesy).to_s + "\n Cleanliness: " + (avg_cleanliness).to_s  
        end
    end
  
  #This variable will correspond to which message should be played
  $status = updateCouchDBData($currentCall.callerID, $currentCall.initialText)
  
  log "******************** status => #{$status} &&&&&& reply => #{$replyLower}"
  
  if $status == 1
      say "#{messages[$status.to_i]['value']} #{$replyLower}. #{messages[$status.to_i]['message']}"
  
  #If this is a new user, send the first message out, create the user and start the first session.
  elsif $status == 0
  #This sends the initial message with the first question
    say "#{messages[$status.to_i]['1']}"
    wait(3000)
    say "#{messages[$status.to_i]['message']}"
  else
    #The rest of the questions and answers are short enough to have in one say
    #If the user responds with an answer that does not correspond to my answers,
    #It will ask the question again
    if messages[$status.to_i][$replyLower] == nil 
      $newStatus = updateCouchDBData($currentCall.callerID, "back") 
      say "Sorry, you have entered a wrong choice. #{messages[$newStatus.to_i]['message']}" 
    else
      say "#{messages[$status.to_i][$replyLower]} #{messages[$status.to_i]['message']}"
    end
  end
  
  #There is no reason to keep the session alive, so we hangup 
  hangup
 
else  
  #Grab the $numToDial parameter and initiate the SMS conversation
  event = call($numToDial, {:network => "SMS"})
   
  #This primarily updates the database with the new number. This variable should always be 0.
  $status = updateCouchDBData($numToDial, nil)
  
  #This sends the initial message with the first question
  say "#{messages[$status.to_i]['1']}"
  wait(3000)
  say "#{messages[$status.to_i]['message']}"
  
  #There is no reason to keep the session alive, so we hangup 
  hangup
 
end