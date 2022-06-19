from tabnanny import verbose
from flask import Flask, render_template, request
from keras.models import load_model
from keras.preprocessing import image
import keras
import tensorflow as tf
import os
import uuid
import json
import cv2

app = Flask(__name__)

dic = {0:'A',1:'B',2:'C',3:'D',4:'E',5:'F',6:'G',
               7:'H',8:'I',9:'K',10:'L',11:'M',12:'N',
               13:'O',14:'P',15:'Q',16:'R',17:'S',18:'T',
               19:'U',20:'V',21:'W',22:'X',23:'Y'}

model = load_model('model.h5')

model.make_predict_function()

# DEF for model processing
def predict_label(img_path):
	i = cv2.imread(img_path, cv2.IMREAD_UNCHANGED)
	i = cv2.cvtColor(i, cv2.COLOR_BGR2GRAY)
	i = cv2.resize(i, (28,28))
	i = i.reshape(1,28,28,1)
	p = model.predict(i, verbose=0).argmax()
	#p = dic[p[0]]
	return p


# routes
@app.route("/", methods=['GET', 'POST'])
def main():
	return render_template("index.html")

@app.route("/about")
def about_page():
	return "Slytherin group people: Joanna Witek, Joanna Borowa, Mateusz Kunik, Dominik Mikulski, Mateusz Religa"

@app.route("/submit", methods = ['GET', 'POST'])
def get_output():
	if request.method == 'POST':

		img = request.files['my_image']
		extension = os.path.splitext(img.filename)[1]
		f_name = str(uuid.uuid4()) + extension
		app.config['UPLOAD_FOLDER'] = 'static/uploads'
		img.save(os.path.join(app.config['UPLOAD_FOLDER'], f_name))
		json.dumps({'filename':f_name})
		
		img_path = (f"static/uploads/{f_name}")

		p = predict_label(img_path)

	return render_template("index.html", img_path = img_path, prediction = dic[p])


if __name__ =='__main__':
	#app.debug = True
	app.run(debug = True)