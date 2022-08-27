# Importing all the required libraries
from flask import Flask
from flask import request
import pickle
import sklearn
import psutil
import os
import random
import json
from helper import *

pid = os.getpid()
py = psutil.Process(pid)
memoryUse = py.memory_info().rss
print('RAM INIT: ', memoryUse)
UPLOAD_FOLDER = '/var/www/html/uploads'

#'''
#DIRECTIVE!!!
#Add the path where you have saved your machine learning model and uncomment the next line
#'''
# pkl_filename = 'saved_models/iforest.pkl'
threshold = -0.313

app = Flask(__name__)
@app.route('/', methods=['POST', 'GET'])

# Load the ML model in memory
#'''
#DIRECTIVE!!!
#Uncomment the following 2 lines to load the file to the server.
#'''
# with open(pkl_filename, 'rb') as file:
#     ml_model = pickle.load(file)

@app.route('/', methods=['POST', 'GET'])
def query_ml():
    if request.method == 'POST':
        # Retrieve arguments from the request
        method = request.form['method']
        path = request.form['path']
        args = json.loads(request.form['args'])
        files = request.form['files']
        for k, v in args.items():
            args[k] = v.replace("$#$", '"')
        hour = int(request.form['hour'])
        day = int(request.form['day'])
        print(request.form)

        # Predict a score (1 for normal, -1 for attack)
        score = predict(method, path, args, hour, day)

        # Return the score to the Lua script
        if score > 0:
            return str(score), 200
        return str(score), 401
    elif request.method == 'GET':
        # Simply return 200 on GET / for health checking
        return "Service is up", 200
    return "Bad Request", 400

def predict(method, path, args, hour, day):
    #'''
    #DIRECTIVE!!!
    #Uncomment the following lines to complete the machine learning plugin.
    #Comment the line which generates a random score to stub the score in the absence of a machine learing model.
    #'''
    # Example of function to predict score using ML
    #features = get_features(method, path, args, hour, day)
    #print(features)

    # scores = ml_model.decision_function(features)
    # for now, stubing score compute
    score = random.randint(-5,5)

    #print(scores[0])
    labels = 1 - 2 * int(score < threshold)
    # return labels[0]
    print(score)
    return labels

if __name__ == '__main__':
    app.run()
