#import os
#import uuid
#import json
import cv2

#from keras.models import load_model
#from keras.preprocessing import image

from flask import Flask, redirect, render_template, request, url_for, Response
#from werkzeug.utils import secure_filename
from camera import Video



app = Flask(__name__)
#app.config['UPLOAD_FOLDER'] = 'static/uploads'


#MODELS_PATH = "Models/"
#BASIC_MODEL_NAME = "first"
#EXTRA_MODEL_NAME = "extra_model.h5"

#IMAGE_PATH = "zdjecie.png"

#model = load_model(filepath = MODELS_PATH + BASIC_MODEL_NAME)


# def model_predict(model, img_path):
    
#     image = cv2.cvtColor(cv2.resize(cv2.imread(img_path), (28, 28)), cv2.COLOR_BGR2GRAY)
#     pred = model.predict(image)
    
#     return pred



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
    
    # do odczytu zdjęć
    # if request.method == 'POST':
    #     file = request.files['file']
    #     extension = os.path.splitext(file.filename)[1]
    #     file_name = str(uuid.uuid4()) + extension
        
    #     file.save(os.path.join(app.config["UPLOAD_FOLDER"], file_name))
    #     return json.dumps({'filename':file_name})

    return render_template("basic_model.html")





@app.route('/extra_model')
def extra_model():

    return render_template('extra_model.html')

def gen(camera):

    while True:
        frame=camera.get_frame()
        yield(b'--frame\r\n'
       b'Content-Type:  image/jpeg\r\n\r\n' + frame +
         b'\r\n\r\n')


@app.route('/video')
def video():
    
    return Response(gen(Video()),
    mimetype='multipart/x-mixed-replace; boundary=frame')


app.run(debug=True)