import cv2


video = cv2.VideoCapture(0)

faceDetect = cv2.CascadeClassifier("haarcascade_frontalface_default.xml")

frame_size = 40
frame_color = (50, 205, 150)
frame_thickness = 4

while True:
    ret, frame = video.read()
    faces = faceDetect.detectMultiScale(frame, 1.3, 5)

    for x,y,w,h in faces:
        # cv2.rectangle(frame, (x, y), (x+w, y+h), (50, 205, 50), 4)
        cv2.line(frame, (x, y), (x+frame_size, y), frame_color, frame_thickness)
        cv2.line(frame, (x, y), (x, y+frame_size), frame_color, frame_thickness)
       
        cv2.line(frame, (x+w, y), (x+w-frame_size, y), frame_color, frame_thickness)
        cv2.line(frame, (x+w, y), (x+w, y+frame_size), frame_color, frame_thickness)
        
        cv2.line(frame, (x, y+h), (x+frame_size, y+h), frame_color, frame_thickness)
        cv2.line(frame, (x, y+h), (x, y+h-frame_size), frame_color, frame_thickness)
        
        cv2.line(frame, (x+w, y+h), (x+w-frame_size, y+h), frame_color, frame_thickness)
        cv2.line(frame, (x+w, y+h), (x+w, y+h-frame_size), frame_color, frame_thickness)

    cv2.imshow("Frame", frame)
    k = cv2.waitKey(1)

    if k==ord("q"):
        break

video.release()
cv2.destroyAllWindows