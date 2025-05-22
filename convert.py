# convert.py - Script to migrate MySQL data into MongoDB collections
import pymysql
from pymongo import MongoClient
import os
from dotenv import load_dotenv
from infrastructure.database.helpers.helpers import convert_to_mongodb

# Load environment variables from .env (MySQL and MongoDB credentials)
load_dotenv()

# Establish connection to MySQL using pymysql
mysql_conn = pymysql.connect(
    host=os.getenv("MYSQL_HOST"),
    user=os.getenv("MYSQL_USER"),
    password=os.getenv("MYSQL_PASSWORD"),
    database=os.getenv("MYSQL_DB_NAME"),
    port=int(os.getenv("MYSQL_DB_PORT")),
    cursorclass=pymysql.cursors.DictCursor
)

# Establish connection to MongoDB
mongo_client = MongoClient(os.getenv("MONGO_HOST"), int(os.getenv("MONGO_PORT")))
mongo_db = mongo_client[os.getenv("MONGO_DB_NAME")]

def main():
    """
    Entry point of the script: defines which tables to convert and invokes conversion.
    """
    # List of relational tables to import into MongoDB (flat structure)
    tables = [
        "fahrer", "fahrzeug", "fahrt", "geraet", "geraet_installation",
        "fahrzeugparameter", "beschleunigung", "diagnose", "wartung"
    ]
    # Call the helper function to perform the migration (embed=False for flat collections)
    total = convert_to_mongodb(tables, embed=False)
    # Output summary of how many records were converted
    print(f"Conversion of {total} records completed.")

# When run as a script, execute the main() function
if __name__ == "__main__":
    main()
