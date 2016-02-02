#!/usr/bin/ruby

require "rubygems"
require "net/http"
require "uri"
require "json"

user = ENV['citivan']
pass = ENV['CityVan1']
db = ENV['citivan']

#baseUriStr = "http://#{user}:#{pass}@#{user}.cloudant.com/#{db}/"
baseUriStr = "http://citivan.cloudant.com/citivan/_all_docs"
baseUri = URI.parse(baseUriStr)
http = Net::HTTP.new(baseUri.host, baseUri.port)

# request = Net::HTTP::Post.new(baseUri.request_uri)
# request.basic_auth(user, pass)
# request["Content-Type"] = "application/json"
# request.body = '{"name": "john", "age": 35}'
# response = http.request(request)
# id = JSON.parse(response.body)["id"]
# puts "The new document's ID is #{id}."

request = Net::HTTP::Get.new(baseUri.request_uri + "mainDataBase")
request.basic_auth(user, pass)
response = http.request(request)
doc = JSON.parse(response.body)
puts doc
#puts "The first revision is #{doc['_rev']}."

request = Net::HTTP::Put.new(baseUri.request_uri + id)
request.basic_auth(user, pass)
request["Content-Type"] = "application/json"
doc['age'] = 36
request.body = JSON.generate(doc)
response = http.request(request)
rev2 = JSON.parse(response.body)["rev"]
puts "The second revision is #{rev2}."

request = Net::HTTP::Delete.new(baseUri.request_uri + id + "?rev=#{rev2}")
request.basic_auth(user, pass)
response = http.request(request)
rev2 = JSON.parse(response.body)["rev"]
puts "Now we will try to delete the document. This is the response we got:"
puts response.body