#!/usr/bin/env python3 

# on windows need python.exe -m pip install requests
# on linux pip install requests 
import json 
import sys 
import requests
import traceback
import json

ip = '169.254.169.254'
port = '80'
default_version = 'latest'

def is_json(myjson):
  try:
    json_object = json.loads(myjson)
  except ValueError:
    return False
  return True

def restCall(resPath, format='json', version=default_version, imds_headers = {'Metadata': 'True'}):
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
    code,content = restCall(subUrl, 'json', '2017-03-01')
    if(code == 200 and len(content) > 0):
        return True

def defaultFormat():
    # Verify that default format is correct
    url1 = 'metadata/instance?api-version=latest'
    url2 = 'metadata/instance?api-version=latest&format=json'
    code1,content1 = restCallRaw(url1)
    code2,content2 = restCallRaw(url2)
    if(code1 != 200 or code1 != code2):
        print('Status code 200 expected')
        return False

    if (content1 != content2):
        print('default format does not match json')
        return False

    if not is_json(content1):
        print("Default was not JSON")
        return False

    # Verify that default format of errors is correct
    url1 = 'metadata/instance/blah?api-version=latest'
    url2 = 'metadata/instance/blah?api-version=latest&format=json'

    code1,content1 = restCallRaw(url1)
    code2,content2 = restCallRaw(url2)
    if(code1 != 404 or code1 != code2):
        print('Status code 404 expected')
        return False

    if (content1 != content2):
        print('default format does not match json')
        return False

    if not is_json(content1):
        print("Default was not JSON")
        return False

    return True

def urlPrefix():
    url = 'metadata'
    code,cont = restCall(url, 'text')
    if not cont == 'instance/':
        print('root metadata call returned invalid value')
        return False

    return True;    

# List of tests to run
testList = [baseTest, defaultFormat, urlPrefix]

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


