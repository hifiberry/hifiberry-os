import http.server
import threading

from metadata import MetadataDisplay


class WebRequestHandler(http.server.BaseHTTPRequestHandler):

    @classmethod
    def set_metadata(cls, metadata):
        cls.metadata = metadata

    def _set_headers(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()

    def do_GET(self):
        print("GET")
        self._set_headers()
#        self.wfile.write("<html><body><h1>{}: {}</h1></body></html>".format(
#            MetadataHandler.metadata.artist,
#            MetadataHandler.self.metadata.title
#       ))
        self.wfile.write("<html><body><h1>Hi!</h1></body></html>")
        print("GET done")

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):
        # Doesn't do anything with posted data
        self._set_headers()
        self.wfile.write("<html><body><h1>POST!</h1></body></html>")


class AudioControlWebserver(MetadataDisplay):

    def __init__(self, port=8080):
        self.port = port
        super()

    def run_server(self):
        import socketserver

        self.server = socketserver.TCPServer(("", self.port),
                                             WebRequestHandler)
        self.server_thread = threading.Thread(target=self.server.serve_forever)
        self.server_thread.daemon = True

    def metadata(self, metadata):
        WebRequestHandler.set_metadata(metadata)
