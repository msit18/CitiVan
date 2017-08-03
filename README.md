# CitiVan

MIT Senseable City Lab collaboration with the City of Cape Town’s Transport and Urban Development Authority (TDA). These files are used on the Heroku server:

- requirements.txt: Add library names to this file to add them to the app
- CitiVan/analyzeSMSResponses.py: analyzes the parsed text from the SMS messages. Returns the appropriate response.
- CitiVan/config.py: contains the cloudant login info and survey questions
- CitiVan/manage.py: handles all POST messages. Has a 3 different methods of parsing XML messages as multiple fail-safes. It's better to process the information somehow than throw an error in this situation.


**Possibly useful links:**
- Documentation on how to use the Heroku server: https://devcenter.heroku.com/articles/deploying-python#django-applications-on-heroku
- Flask documentation: http://flask.pocoo.org/docs/0.12/quickstart/#a-minimal-application
- Requests documentation: http://docs.python-requests.org/en/latest/user/quickstart/


For further questions, please contact Michelle Sit at msit@mit.edu
