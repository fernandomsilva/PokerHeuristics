import urllib, urllib2, ssl

#response = urllib2.urlopen("https://216.165.115.237:1111/edit/fernando/Poker/Exhaustive%20Search/exs-output-Typheus-2017-11-25%2016%3A02%3A13.678363.txt")
#html = response.read()

#print html

url = "https://216.165.115.237:1111/edit/fernando/Poker/Exhaustive%20Search/exs-output-Typheus-2017-11-25%2016%3A02%3A13.678363.txt"
req = urllib2.Request(url, headers={ 'X-Mashape-Key': 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' })
form_data = {'password': 'JupyterGIL2016'}
params = urllib.urlencode(form_data)
gcontext = ssl.SSLContext(ssl.PROTOCOL_TLSv1)  # Only for gangstars
info = urllib2.urlopen(req, params, context=gcontext).read()

print info