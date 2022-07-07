import cv2
from model import Classifier

class_names = list("ABCDEFGHIKLMNOPQRSTUVWXY")


class Video(object):
    
    def __init__(self, model_path):
        self.video = cv2.VideoCapture(0)
        self.clf_model = Classifier(model_path, class_names)

    def __del__(self):
        self.video.release()

    def get_frame(self):
        
        alpha = 0.7
        frame_color = (138, 138, 138)
        frame_contour = (88, 138, 48)
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
        result = self.clf_model.get_predict(roi, batch=False)
        
        cv2.putText(frame, result, (width, 3*height - 10), cv2.FONT_HERSHEY_TRIPLEX, 3, frame_contour, frame_thickness)
        
        #cv2.rectangle(frame, square_box[0], square_box[1], frame_color, -1)
        cv2.rectangle(frame, square_box[0], square_box[1], frame_contour, 6)
        
        new_frame = cv2.addWeighted(frame, alpha, overlay, 1 - alpha, 0)
        _, jpg = cv2.imencode(".jpg", new_frame)


        return result, jpg.tobytes()