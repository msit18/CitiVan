from Citivan import app

@app.route('/')
def index():
	return "This is the views file"
