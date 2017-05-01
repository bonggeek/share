#!/usr/bin/env python3 

# on windows need python.exe -m pip install requests
# on linux pip install requests 
import json 
import sys 
import requests
import traceback

ip = '169.254.169.254'
port = '80'

def restCall(resPath, version='latest_internal', format='json', imds_headers = {'Metadata': 'True'}):
    mdUrl = 'http://{0}:{1}/{2}?api-version={3}&format={4}'.format(ip, port, resPath, version, format)
    print('Calling {}'.format(mdUrl))
    resp = requests.get(url=mdUrl, headers=imds_headers)
    code = resp.status_code
    cont = bytes.decode(resp.content)
    print(code)
    print(cont)
    return code, cont

def restCallRaw(subUrl, imds_headers = {'Metadata': 'True'}):
    mdUrl = 'http://{0}:{1}/{2}'.format(ip, port, subUrl)
    print('Calling {}'.format(mdUrl))
    resp = requests.get(url=mdUrl, headers=imds_headers)
    code = resp.status_code
    cont = bytes.decode(resp.content)
    print(code)
    print(cont)
    return code, cont

def baseTest():
    subUrl = 'metadata/instance'
    code,content = restCall(subUrl, '2017-03-01')
    if(code == 200 and len(content) > 0):
        return True

def defaultFormat():
    url1 = 'metadata/instance?api-version=latest'
    url2 = 'metadata/instance?api-version=latest&format=json'
    code1,content1 = restCallRaw(url1)
    code2,content2 = restCallRaw(url2)
    if(code1 != 200 or code1 != code2):
        print('Status code 200 expected')
        return false

    if (content1 != content2):
        print('default format does not match json')
        return false

    return True

testList = [baseTest, defaultFormat]

def runTests():
    passCount = 0
    failCount = 0
    for test in testList:
        print('--------------------------------------------------')
        print('Running Test: {}'.format(test.__name__))
        result = test()
        print()
        if(result):
            passCount += 1
            print('PASS')
        else:
            failCount += 1
            print('FAIL')

    print('==================================================')
    print('{} tests passed, {} tests failed'.format(passCount, failCount))
    return failCount == 0

try:
    if(not runTests()):
        print('!!!! Tests failed')
        sys.exit(1)
    else:
        sys.exit(0)
except Exception as e:
    print('Unhandled exception')
    traceback.print_stack()
    traceback.print_exc()


