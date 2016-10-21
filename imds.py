#!/usr/bin/env python3
import json
import urllib.request
import sys

server = "127.0.0.1"
port = "90"
mdUrl = "http://" + server + ":" + port + "/metadata/latest/instance/"

def restCall(mdUrl):
    header={'Metadata': 'True'}
    request = urllib.request.Request(url=mdUrl + "?cid=42", headers=header)
    response = urllib.request.urlopen(request)
    data = response.read()
    dataStr = data.decode("utf-8")
    return dataStr
    
def fetch(mdUrl):
    #print("Called with %s" % mdUrl)
    data = restCall(mdUrl)
    #print ("Got %s" % data)
    for e in data.splitlines():
        newUrl = mdUrl + e
        if e.endswith('/'):
            fetch(newUrl)
        else:
            r = restCall(newUrl)
            print(newUrl, r)

fetch(mdUrl)
