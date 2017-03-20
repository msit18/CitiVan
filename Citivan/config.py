from cloudant.client import Cloudant

cloudantUsername = "citivan"
cloudantPassword = "CityVan1"
serviceURL = "https://citivan.cloudant.com"
client = Cloudant(cloudantUsername, cloudantPassword, url=serviceURL,\
				connect=True, auto_renew=True)

questions = ["What are the last four digits of the minibus license plate? (Example: for CA34578, enter 4578).", 
		"Pick a number from 1 to 5 to rate the quality of your ride. 1) Very poor. 2) Poor. 3) Average. 4) Good. 5) Excellent.",
		"Rate from 1 to 5, how comfortable you are in the vehicle? 1) Very Uncomfortable 2) Uncomfortable 3) Average 4) Good 5) Very Comfortable",
		"Does the driver drive safely? Enter 1 for yes or 2 for no.",
		"Was your driver courteous? Enter 1 for yes or 2 for no.", 
		"Do you feel safe in this vehicle? Enter 1 for yes or 2 for no.", 
		"Thank you for your responses! Have a great day."]