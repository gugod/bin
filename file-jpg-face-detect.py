#!/usr/bin/env python

import cv2
import sys
import json

cascPath = sys.argv[1]
imagePath = sys.argv[2]

faceCascade = cv2.CascadeClassifier(cascPath)
image = cv2.imread(imagePath)
faces = faceCascade.detectMultiScale(image)

receipt={'file': imagePath, 'faces': []}

for (x,y,w,h) in faces:
    receipt['faces'].append({'x': x, 'y': y, 'w': w, 'h': h})

print json.dumps(receipt, separators=(',',':') )
