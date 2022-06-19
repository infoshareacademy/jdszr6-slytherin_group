import cv2
import numpy as np
from tensorflow.keras.models import load_model

MODELS_PATH = "Models/"
MODEL_NAME = "model.h5"

model = load_model(filepath = MODELS_PATH + MODEL_NAME)

class_names = list("ABCDEFGHI KLMNOPQRSTUVWXY")



def model_predict(model, image, batch = True):

    if batch:
        image = cv2.imread(image, cv2.IMREAD_UNCHANGED)
    
    image = cv2.cvtColor(cv2.resize(image, (28, 28)), cv2.COLOR_BGR2GRAY)
    x = image.reshape(1, 28, 28, 1)

    predict = model.predict(x)
    classes = np.argmax(predict, axis=1)

    return np.array(class_names)[classes][0]



class Video(object):
    def __init__(self):
        self.video = cv2.VideoCapture(0)

    def __del__(self):
        self.video.release()

    def get_frame(self):
        
        alpha = 0.75
        frame_color = (138, 138, 138)
        frame_thickness = 6


        _, frame = self.video.read()
        overlay = frame.copy()

        height, width, channels = frame.shape
        height, width = height // 10, width // 10

        if height > width:
            main_size = width
        else:
            main_size = height

        square_box = [(width, 3*height), (width + 4*main_size, 3*height + 4*main_size)]

        roi = frame[square_box[0][1] : square_box[1][1], square_box[0][0] : square_box[1][0]]
        result = model_predict(model, roi, batch=False)
        
        cv2.putText(frame, result, square_box[0], cv2.FONT_HERSHEY_COMPLEX, 3, frame_color, frame_thickness)
        cv2.rectangle(overlay, square_box[0], square_box[1], frame_color, -1)
        
        new_frame = cv2.addWeighted(frame, alpha, overlay, 1 - alpha, 0)
        _, jpg = cv2.imencode(".jpg", new_frame)


        return jpg.tobytes()