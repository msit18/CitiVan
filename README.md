# CitiVan

MIT Senseable City Lab collaboration with the City of Cape Town’s Transport and Urban Development Authority (TDA). This github contains all the files that are pushed to the Heroku server. For instructions on how to push these files to the Heroku server, see the Possibly Useful Links section below.


**These files are used on the Heroku server:**

- requirements.txt: Add library names to this file to add them to the app. You may need to download these libraries on your machine if you would like to run the server locally (see below).
- CitiVan/analyzeSMSResponses.py: analyzes the parsed text from the SMS messages. Returns the appropriate response.
- CitiVan/config.py: contains the cloudant login info and survey questions
- CitiVan/manage.py: handles all POST messages. Has a 3 different methods of parsing XML messages as multiple fail-safes. It's better to process the information somehow than throw an error in this situation.

**Libraries you may have to install to run the files locally:**

- Use the instructions here to test the Heroku server locally. It gives instructions on how to download the libraries in the requirements file: https://devcenter.heroku.com/articles/deploying-python
- Link to install Cloudant: https://github.com/cloudant/python-cloudant
- Link to install Flask: http://flask.pocoo.org/docs/0.12/installation/
- Github to install xmltodict: https://github.com/martinblech/xmltodict
- Documentation to install BeautifulSoup4: https://www.crummy.com/software/BeautifulSoup/bs4/doc/
- HTMLParser is a built-in Python library


**Possibly useful links:**
- Documentation on how to use the Heroku server: https://devcenter.heroku.com/articles/deploying-python#django-applications-on-heroku
- Flask documentation: http://flask.pocoo.org/docs/0.12/quickstart/#a-minimal-application
- Requests documentation: http://docs.python-requests.org/en/latest/user/quickstart/

**Overview of the analyzeSMSResponses:**

The program first verifies if the user's cellphone number already exists in the Cloudant database. If the user is new or if the existing user's last survey was completed, it creates a new datapoint, discards the inputted text, and asks the user the first question. The program will analyze the user's input if the user is not new and if the survey has not been completed yet.

If the user's input text is simply just "rate", the system will ignore it and repeat the same question. In the above cases if the user asks for a bus rating, even if the user has not yet texted the system, the program will provide the appropriate rating and question for that user.

For the analysis portion, the program checks which question the user is currently answering. In the user database, there are two variables tracking the user's progress through each survey: convoNum and currentQuestionNum. currentQuestionNum is used to provide progress feedback to the user. At the beginning of each SMS message, it indicates how many questions the user has answered out of 6 questions. convoNum is used to match the user's input to the correct question number. Except for question 1 which will always be provided first, the remaining 5 questions are randomly provided with each survey via the pickNextSurveyQuestion method. convoNum is used to select the correct question from the config question array and match the user's response to that number in the database.

The program also checks whether the inputted bus has been created in the bus database or if it should be created. If the user's text is valid for that question, the user and bus databases will be updated. If the text is incorrect or if there are any errors, the system will simply repeat the same question. A great feature to add would be specialized error messages to inform the user how their input was incorrect and how they can fix it.

For further questions, please contact Michelle Sit at msit@mit.edu
