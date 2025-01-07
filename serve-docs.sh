#!/bin/bash

# Check if Python 3 is available
if command -v python3 &>/dev/null; then
    echo "Starting documentation server on http://localhost:8000"
    python3 -m http.server 8000
else
    echo "Starting documentation server on http://localhost:8000"
    python -m SimpleHTTPServer 8000
fi
