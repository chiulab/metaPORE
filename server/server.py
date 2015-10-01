#!/usr/bin/env python
#
# 	server.py
#

import BaseHTTPServer
import CGIHTTPServer
import cgitb; cgitb.enable()
 
server = BaseHTTPServer.HTTPServer
handler = CGIHTTPServer.CGIHTTPRequestHandler
server_address = ("", 8000)
handler.cgi_directories = ["/cgi-bin"]
 
httpd = server(server_address, handler)
httpd.serve_forever()
