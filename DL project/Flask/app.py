import os
import uuid
import json

from flask import Flask, redirect, render_template, request, url_for, Response

from model import Classifier
from camera import Video


class_names = list("ABCDEFGHI KLMNOPQRSTUVWXY")

MODELS_PATH = "Models/"
MODEL_NAME = "model.h5"
FULL_PATH = MODELS_PATH + MODEL_NAME

clf_model = Classifier(FULL_PATH, class_names)



app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = 'static/uploads'

@app.route("/", methods=["GET", "POST"])
def index():

    if request.method == "POST":
        if request.form.get("basic") == "Choose":
            return redirect(url_for("basic_model"))
        elif request.form.get("extra") == "Choose":
            return redirect(url_for("extra_model"))
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
        predict = clf_model.get_predict(img_path, class_names)
        
        
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

app.run(debug=True)