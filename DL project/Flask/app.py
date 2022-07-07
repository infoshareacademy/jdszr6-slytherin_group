import os
import uuid
import json

import numpy as np
import cv2

from tensorflow.keras.models import load_model
from flask import Flask, redirect, render_template, request, url_for, Response




class Classifier(object):
    def __init__(self, path, class_names):
        self.path = path
        self.class_names = class_names

    def get_predict(self, image, batch = True):

        model = load_model(self.path)

        if batch:
            image = cv2.imread(image, cv2.IMREAD_UNCHANGED)

        image = cv2.cvtColor(cv2.resize(image, (28, 28)), cv2.COLOR_BGR2GRAY)
        x = image.reshape(1, 28, 28, 1)
        
        prediction = model.predict(x)

        indicator = prediction.argmax()
        sign = np.array(class_names)[indicator]
        probability = prediction[np.arange(prediction.shape[0]), indicator][0]

        return sign, probability

class Video(object):
    def __init__(self, model_path):
        self.video = cv2.VideoCapture(0)
        self.clf_model = Classifier(model_path, class_names)

    def __del__(self):
        self.video.release()

    def get_frame(self):
        text_colour = (90, 140, 0)
        text_thickness = 2
        frame_contour = (90, 140, 50)
        frame_thickness = 6

        _, frame = self.video.read()
        overlay = frame.copy()

        height, width, channels = frame.shape
        height, width = height // 10, width // 10

        if height > width:
            main_size = width
        else:
            main_size = height

        square_box = [(width, 3*height), (width + 5*main_size, 3*height + 5*main_size)]

        roi = frame[square_box[0][1] : square_box[1][1], square_box[0][0] : square_box[1][0]]
        sign, probability = self.clf_model.get_predict(roi, batch=False)
        
        cv2.putText(frame, "Sign: {}".format(sign), (width, 3*height - 40), cv2.FONT_HERSHEY_COMPLEX_SMALL, 2, text_colour, text_thickness+1)
        cv2.putText(frame, "Probability: %.2f" % round(probability, 3), (width, 3*height - 10), cv2.FONT_HERSHEY_COMPLEX_SMALL, 1, text_colour, text_thickness)
        cv2.rectangle(frame, square_box[0], square_box[1], frame_contour, frame_thickness)
        
        _, jpg = cv2.imencode(".jpg", frame)
        return sign, jpg.tobytes()



class_names = list("ABCDEFGHIKLMNOPQRSTUVWXY")

MODELS_PATH = "Models/"
MODEL_NAME = "best_model.h5"
FULL_PATH = MODELS_PATH + MODEL_NAME

clf_model = Classifier(FULL_PATH, class_names)





app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'static/uploads'


@app.route("/", methods=["GET", "POST"])
def index():

    if request.method == "POST":
        if request.form.get("basic_button") == "Choose":
            return redirect(url_for("basic_model"))

        elif request.form.get("extra_button") == "Choose":
            return redirect(url_for("extra_model"))

        elif request.form.get("practice_button") == "Practice!":
            return redirect(url_for("learning_page"))

        else:
            pass

    elif request.method == "GET":
        return render_template("index.html")

    return render_template("index.html")



@app.route("/basic_model", methods=['GET', 'POST'])
def basic_model():
    
    return render_template("basic_model.html")

@app.route("/submit", methods = ['GET', 'POST'])
def get_output():
    if request.method == 'POST':
        img = request.files['my_image']
        extension = os.path.splitext(img.filename)[1]
        f_name = str(uuid.uuid4()) + extension

        img.save(os.path.join(app.config['UPLOAD_FOLDER'], f_name))
        json.dumps({'filename':f_name})
        
        img_path = (f"static/uploads/{f_name}")
        predict = clf_model.get_predict(img_path, class_names)[0]
        
        
    return render_template("basic_model.html", img_path = img_path, prediction = predict)



@app.route('/extra_model')
def extra_model():

    return render_template('extra_model.html')

def gen(camera):

    while True:
        result, frame=camera.get_frame()
        yield(b'--frame\r\n'
       b'Content-Type:  image/jpeg\r\n\r\n' + frame +
         b'\r\n\r\n')

        
@app.route('/video')
def video():
    
    return Response(gen(Video(FULL_PATH)),
    mimetype='multipart/x-mixed-replace; boundary=frame')



@app.route('/learning')
def practice():

    return render_template('learning.html')



app.run(debug=True)