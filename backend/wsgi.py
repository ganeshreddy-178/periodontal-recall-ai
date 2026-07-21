"""
PythonAnywhere WSGI configuration file.
Path on PythonAnywhere: /var/www/Ganeshreddy_pythonanywhere_com_wsgi.py
"""
import sys
import os

# Add project to path
project_home = '/home/Ganeshreddy/periodontal-recall-ai/backend'
if project_home not in sys.path:
    sys.path.insert(0, project_home)

# Set environment
os.environ['FLASK_ENV'] = 'production'

# Load .env
from dotenv import load_dotenv
load_dotenv(os.path.join(project_home, '.env'))

# Create app
from app import create_app
application = create_app('production')
