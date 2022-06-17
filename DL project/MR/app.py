from flask import Flask, render_template, request
from keras.models import load_model
from keras.preprocessing import image
import keras
import tensorflow as tf

app = Flask(__name__)

dic = {0 : 'A', 1 : 'B'}

model = load_model('model.h5')

model.make_predict_function()

def predict_label(img_path):
	i = tf.keras.utils.load_img(img_path, target_size=(28,28))
	i = tf.keras.utils.img_to_array(i)/255.0
	i = i.reshape(28,28,1)
	p = model.predict(i)
	return dic[p[0]]


# routes
@app.route("/", methods=['GET', 'POST'])
def main():
	return render_template("index.html")

@app.route("/about")
def about_page():
	return "Please subscribe  Artificial Intelligence Hub..!!!"

@app.route("/submit", methods = ['GET', 'POST'])
def get_output():
	if request.method == 'POST':
		img = request.files['my_image']

		img_path = "static/" + img.filename	
		img.save(img_path)

		p = predict_label(img_path)

	return render_template("index.html", prediction = p, img_path = img_path)


if __name__ =='__main__':
	#app.debug = True
	app.run(debug = True)