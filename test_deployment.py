#!/usr/bin/env python3
"""
Test deployment script for Healthcare Research Dashboard
This script starts a simple HTTP server to test the deployment package.
"""

import http.server
import socketserver
import os
import webbrowser
import threading
import time

def start_server():
    """Start a simple HTTP server to test the deployment package"""
    # Change to docs directory
    os.chdir('docs')
    
    # Define the handler
    Handler = http.server.SimpleHTTPRequestHandler
    
    # Create the server
    with socketserver.TCPServer(("", 8001), Handler) as httpd:
        print("Serving deployment package at http://localhost:8001")
        print("Press Ctrl+C to stop the server")
        
        # Start the server in a separate thread
        server_thread = threading.Thread(target=httpd.serve_forever)
        server_thread.daemon = True
        server_thread.start()
        
        # Open the browser after a short delay
        time.sleep(1)
        webbrowser.open('http://localhost:8001')
        
        try:
            # Keep the main thread alive
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\nShutting down server...")
            httpd.shutdown()
            httpd.server_close()

if __name__ == "__main__":
    start_server()