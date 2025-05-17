import os
from dotenv import load_dotenv

# Load environment variables from a .env file
load_dotenv()

# MySQL configuration values loaded from environment variables
MYSQL_HOST = os.getenv("MYSQL_HOST")
MYSQL_USER = os.getenv("MYSQL_USER")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD")
MYSQL_DB_NAME = os.getenv("MYSQL_DB_NAME")
MYSQL_DB_PORT = os.getenv("MYSQL_DB_PORT")

# MongoDB configuration values loaded from environment variables
MONGO_HOST = os.getenv("MONGO_HOST")
MONGO_USER = os.getenv("MONGO_USER")
MONGO_PASSWORD = os.getenv("MONGO_PASSWORD")
MONGO_DB_NAME = os.getenv("MONGO_DB_NAME")
MONGO_PORT = os.getenv("MONGO_PORT")

# SQLAlchemy-compatible MySQL connection string
# Note: 'local_infile=1' enables LOAD DATA LOCAL INFILE support
MYSQL_CONFIG_STRING = f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_DB_PORT}/{MYSQL_DB_NAME}?local_infile=1"

# MongoDB connection string
MONGO_CONFIG_STRING = f"mongodb://{MONGO_USER}:{MONGO_PASSWORD}@{MONGO_HOST}:{MONGO_PORT}/"

# Supported file extensions for import functionality (used for validation)
ALLOWED_EXTENSIONS = {'json'}

# List of MySQL tables eligible for processing and interaction in the frontend/backend
ALLOWED_TABLES = [
    'fahrzeug', 'fahrer', 'fahrer_fahrzeug', 'geraet',
    'fahrt', 'fahrt_fahrer', 'fahrzeugparameter',
    'beschleunigung', 'diagnose', 'wartung', 'geraet_installation'
]