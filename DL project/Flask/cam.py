import cv2


faceDetect = cv2.CascadeClassifier("haarcascade_frontalface_default.xml")

class Video(object):
    def __init__(self):
        self.video = cv2.VideoCapture(0)

    def __del__(self):
        self.video.release()

    def get_frame(self):
        
        frame_size = 40
        frame_color = (50, 205, 150)
        frame_thickness = 4

        ret, frame = self.video.read()
        faces = faceDetect.detectMultiScale(frame, 1.3, 5)
        for x,y,w,h in faces:
            cv2.line(frame, (x, y), (x+frame_size, y), frame_color, frame_thickness)
            cv2.line(frame, (x, y), (x, y+frame_size), frame_color, frame_thickness)
        
            cv2.line(frame, (x+w, y), (x+w-frame_size, y), frame_color, frame_thickness)
            cv2.line(frame, (x+w, y), (x+w, y+frame_size), frame_color, frame_thickness)
            
            cv2.line(frame, (x, y+h), (x+frame_size, y+h), frame_color, frame_thickness)
            cv2.line(frame, (x, y+h), (x, y+h-frame_size), frame_color, frame_thickness)
            
            cv2.line(frame, (x+w, y+h), (x+w-frame_size, y+h), frame_color, frame_thickness)
            cv2.line(frame, (x+w, y+h), (x+w, y+h-frame_size), frame_color, frame_thickness)

        ret, jpg = cv2.imencode(".jpg", frame)

        return jpg.tobytes()