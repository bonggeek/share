#!/usr/bin/python
# Copyright (c) 2014 Adafruit Industries
# Author: Tony DiCola

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Abhinaba Basu
# Extended to 

import sys
import urllib2
import requests
import Adafruit_DHT
import json
import time

url = "http://192.168.1.42/api/Thing"
deviceId = "b1d943ce-725d-4fe4-97b3-c868032df95f"

def registerDevice(deviceId):
    jsonDeviceStr = """
    {{
        "Id": "{}",
        "Description": "RPi Magic Mirror, Python client",
        "Capability": [
            "temp",
            "humidity",
            "motion"
        ]
    }}
    """

    # register the device with ThingServer
    print("Registering device with ")
    jsonDevice = jsonDeviceStr.format(deviceId)
    print(jsonDevice)

    headers = {'Content-type': 'application/json'}
    r = requests.put(url, data=jsonDevice, headers=headers)

    print("Got response {}".format(r.status_code))

    if(r.status_code != 200):
        print("Failed to register device with status %d" %(r.status_code))
        return ""

    # Need to parse r.text to get teh token
    rJson = json.loads(r.text)
    token = rJson["id"]
    print("Successfully registered device and got AccessToken %s" % token);

    return token


def sendData(url, deviceId, token, temperature, humidity ):
    jsonDataStr = """
    {{
        "Id": "{}",
        "Data" : [
            {{
                "Name": "temperature",
                "Value": "{}"
            }},
            {{
                "Name": "humidity",
                "Value": "{}"
            }}
        ]
    }}
    """
    formattedStr = jsonDataStr.format(deviceId, temperature, humidity)

    headers = {'Content-type': 'application/json', 'AccessToken' : token}
    r = requests.post(url, data=formattedStr, headers=headers)
    print("Got response {}".format(r.status_code))
    
    return r.status_code


token = registerDevice(deviceId)

# Parse command line parameters.
sensor_args = { '11': Adafruit_DHT.DHT11,
                '22': Adafruit_DHT.DHT22,
                '2302': Adafruit_DHT.AM2302 }
if len(sys.argv) == 3 and sys.argv[1] in sensor_args:
    sensor = sensor_args[sys.argv[1]]
    pin = sys.argv[2]
else:
    print('usage: sudo ./Adafruit_DHT.py [11|22|2302] GPIOpin#')
    print('example: sudo ./Adafruit_DHT.py 2302 4 - Read from an AM2302 connected to GPIO #4')
    sys.exit(1)

dataPush = 0
while True:
    print("======================= Data Push %d =========================" % dataPush)
    dataPush += 1
    # Try to grab a sensor reading.  Use the read_retry method which will retry up
    # to 15 times to get a sensor reading (waiting 2 seconds between each retry).
    humidity, temperature = Adafruit_DHT.read_retry(sensor, pin)

    # Un-comment the line below to convert the temperature to Fahrenheit.
    #temperature = temperature * 9/5.0 + 32

    # Note that sometimes you won't get a reading and
    # the results will be null (because Linux can't
    # guarantee the timing of calls to read the sensor).
    # If this happens try again!
    if humidity is not None and temperature is not None:
        print('Temp={0:0.1f}*  Humidity={1:0.1f}%'.format(temperature, humidity))
        statusCode = sendData(url, deviceId, token, temperature, humidity)
        if(statusCode == 404 or statusCode == 401):
            # Failed with unknown device, reattempt registering
            token = registerDevice(deviceId)
            if token:
                statusCode = sendData(url, deviceId, token, temperature, humidity)
            else:
                print("Failed to register as well")

    else:
        print('Failed to get reading. Try again!')

    time.sleep(5)

