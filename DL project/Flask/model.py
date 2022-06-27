import cv2
import numpy as np
from tensorflow.keras.models import load_model


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

        predict = model.predict(x)
        classes = np.argmax(predict, axis=1)

        return np.array(self.class_names)[classes][0]