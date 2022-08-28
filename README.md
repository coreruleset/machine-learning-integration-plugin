# OWASP ModSecurity Core Rule Set - Machine Learning Plugin

## Description

This is a plugin that serves to integrate machine learning support to the CRS.

The plugin consists of 3 parts -
1. Plugin rules
2. Lua script
3. Flask server

### Plugin Rules
The plugin contains rules which call the Lua script and pass or block the request based on the status returned to the rule.

### Lua Script
The lua script receives the request from the rule, reads the data sent in the request and reconstructs the request to form a http POST request to be sent to the flask server ```ml_model_server```. 
After receiving the response from the server, the lua script sends the status response back to the CRS plugin. 

### Flask Server
This server receives a http POST request from the lua script. It extracts the different parameters from the request. The parameters extracted are request method, path, arguements, file names, file sizes, hour and day. These parameters are sent to a function which is supposed to call a machine learning model. This function has been stubbed by a random function for now. 
This function is supposed to return a ml_anomaly_score. Based on this score, the server reuturns a 200 OK or 401 status. 

This workflow has been depicted in the diagram below. 

```
┌───────────────────────────┐                         ┌────────────────────────────┐                  ┌────────────────────────┐
│                           │  SecRuleScript          │                            │ HTTP POST        │                        │
│CRS                        ├────────────────────────►│ LUA Script                 ├─────────────────►│                        │
│machine-learning-after.conf│                         │ machine-learning-client.lua│                  │  Stub ml_model_server  │
│                           │  inbound_ml_status: 0|1 │                            │ HTTP 200|401|400 │                        │
│                           │◄────────────────────────┤                            │◄─────────────────┤                        │
└───────────────────────────┘                         └────────────────────────────┘                  └────────────────────────┘
```
Currently, the machine learning model has been stubbed with a random score generator function due to the absence of a machine learning model. Directives have been provided to add your own machine learning model to the plugin.

## Installation

For full and up to date instructions for the different available plugin
installation methods, refer to [How to Install a Plugin](https://coreruleset.org/docs/concepts/plugins/#how-to-install-a-plugin)
in the official CRS documentation.

## Pre-Requisites
You will need to install the following libraries-

### lua-socket library installation
LuaSocket library should be part of your linux distribution. Here is an example of installation on Debian linux:
```apt install lua-socket```

#### CRS Container
The official CRS container does not yet have the lua-socket library installed. Currently, this has to be installed manually.
When you get the following error, the lua-socket library is missing.
```
ModSecurity: Lua: Script execution failed: attempt to call a nil value [hostname "localhost"] [uri "/"] [unique_id "Yv4H9oxd8Kvjozs0DGkhWAAAAIA"]
```

### ml_model_server/placeholder.py
- flask
- request 
- pickle 
- sklearn
- psutil
- os
- random
- helper

## Configration of the flask server 
1. Copy the ```ml_model_server``` folder into ```/var/www/html```.
2. Add your machine learning model in ```ml_model_server/saved_models``` and follow the directives in ```placeholder.py``` to include the model in the server.
3. Start the flask server. To run the flask server, 
   1. Create a file ```runflash.sh``` in the home directory.
   2. Add the following lines in the file:
      ```
       export FLASK_APP=/var/www/html/ml-model-server/placeholder.py
       <path of your local flask installation> run
      ```
   3. Start your virtual environment.
   4. Run the command ``` ./runflash.sh ```
4. Update the variable ```ml_server_url``` in ```machine-learning-client.lua``` to the url where the server is running on your system.
5. The plugin is now ready to use.

## Working

This plugin works in two modes - 
1. False positive detection mode
2. General detection mode.

You can change the mode by going to machine-learning-config.conf and modifying the value of ```machine-learning-plugin_mode```. If the value of this variable is 1 the plugin works in false positive detection mode and if the value of the variable is 2, the plugin works in general detection mode.

### False Positive Detection Mode
In mode 1, the requests which have an inbound anomaly score greater than the inbound anomaly threshold are scanned by the machine learning model. Only if the machine learning model gives an anomaly score greater than the machine learning anomaly threshold the request is blocked. Else, the request is passed and labeled as a false positive.

### General Detection Mode
In mode 2, all requests are scanned by the machine learning model and the decision to pass or block the request is made solely by the model. If the machine learning anomaly score crosses the machine learning threshold, the request is blocked.

This plugin has been developed without an actual machine learning model in place. Hence, the score has been stubbed to generate a random score. A user can choose to run the plugin with any machine learning model of his/her choice. To do so, directives have been provided in ```placeholder.py``` to add the machine learning model file.

## Testing
After configuration, the plugin should be tested in both modes. 

### False positive detection mode 
This mode can be tested with a request which returns an anomaly score higher than the configured anomaly score. 

### General detection mode 
This mode can be tested with any request. 


For example, both modes can be tested using 
```
curl -v localhost/?arg=../../etc/passwd
``` 
Using the default CRS configurations, the request would either end in a 403 Forbidden status or would go through. This is because the plugin has been stubbed by a function which returns a random score.
If the request goes through, the logs would contain the following lines 
```
ModSecurity: Warning. 1 [file "/etc/modsecurity/plugins/machine-learning-after.conf"] [line "77"] [id "9516210"] [msg "ML kicked in for evaluation."] [severity "NOTICE"] [ver "machine-learning-plugin/1.0.0"] [tag "anomaly-evaluation"] [hostname "localhost"] [uri "/"] [unique_id "YwXtyjaXH2S_WKCQ3YNWKQAAAEI"]
ModSecurity: Warning. Operator EQ matched 1 at TX:inbound_ml_status. [file "/etc/modsecurity/plugins/machine-learning-after.conf"] [line "90"] [id "95161310"] [msg "ML Model passed"] [data "ML model status: 1. ML model anomaly score: 1. CRS anomaly score: 40"] [severity "NOTICE"] [ver "machine-learning-plugin/1.0.0"] [tag "anomaly-evaluation"] [hostname "localhost"] [uri "/"] [unique_id "YwXtyjaXH2S_WKCQ3YNWKQAAAEI"]
```

If the request returns a 403 status, the logs would contain the following lines
```
ModSecurity: Anomaly found by ML [hostname "localhost"] [uri "/"] [unique_id "YwXs5TaXH2S_WKCQ3YNWKAAAAEE"]
ModSecurity: Warning. 0 [file "/etc/modsecurity/plugins/machine-learning-after.conf"] [line "77"] [id "9516210"] [msg "ML kicked in for evaluation."] [severity "NOTICE"] [ver "machine-learning-plugin/1.0.0"] [tag "anomaly-evaluation"] [hostname "localhost"] [uri "/"] [unique_id "YwXs5TaXH2S_WKCQ3YNWKAAAAEE"]
ModSecurity: Access denied with code 403 (phase 2). Operator EQ matched 0 at TX:inbound_ml_status. [file "/etc/modsecurity/plugins/machine-learning-after.conf"] [line "102"] [id "9516320"] [msg "ML Model detected anomalies and blocked"] [data "ML model status: 0. ML model anomaly score: 0. CRS anomaly score: 40"] [severity "CRITICAL"] [ver "machine-learning-plugin/1.0.0"] [tag "anomaly-evaluation"] [hostname "localhost"] [uri "/"] [unique_id "YwXs5TaXH2S_WKCQ3YNWKAAAAEE"]
``` 

## License

Copyright (c) 2022 OWASP ModSecurity Core Rule Set project. All rights reserved.

The OWASP ModSecurity Core Rule Set and its official plugins are distributed
under Apache Software License (ASL) version 2. Please see the enclosed LICENSE
file for full details.
