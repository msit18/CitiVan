# CitiVan

MIT Senseable City Lab collaboration with the City of Cape Town’s Transport and Urban Development Authority (TDA). These files are used on the Heroku server:

- requirements.txt: Add library names to this file to add them to the app. You may need to download these libraries on your machine if you would like to run the server locally (see below).
- CitiVan/analyzeSMSResponses.py: analyzes the parsed text from the SMS messages. Returns the appropriate response.
- CitiVan/config.py: contains the cloudant login info and survey questions
- CitiVan/manage.py: handles all POST messages. Has a 3 different methods of parsing XML messages as multiple fail-safes. It's better to process the information somehow than throw an error in this situation.

**Libraries you may have to install to run the files locally**

- Use the instructions here to test the Heroku server locally. It gives instructions on how to download the libraries in the requirements file: https://devcenter.heroku.com/articles/deploying-python
- Link to install Cloudant: https://github.com/cloudant/python-cloudant
- Link to install Flask: http://flask.pocoo.org/docs/0.12/installation/
- Github to install xmltodict: https://github.com/martinblech/xmltodict
- Documentation to install BeautifulSoup4: https://www.crummy.com/software/BeautifulSoup/bs4/doc/
- HTMLParser is a built-in python library


**Possibly useful links:**
- Documentation on how to use the Heroku server: https://devcenter.heroku.com/articles/deploying-python#django-applications-on-heroku
- Flask documentation: http://flask.pocoo.org/docs/0.12/quickstart/#a-minimal-application
- Requests documentation: http://docs.python-requests.org/en/latest/user/quickstart/


A great feature to add would be specialized error messages to inform the user how their input was incorrect and how they can fix it.

For further questions, please contact Michelle Sit at msit@mit.edu
