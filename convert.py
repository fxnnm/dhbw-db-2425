import pymysql
from pymongo import MongoClient
import os
from dotenv import load_dotenv
from infrastructure.database.helpers.helpers import convert_to_mongodb

load_dotenv()

mysql_conn = pymysql.connect(
    host=os.getenv("MYSQL_HOST"),
    user=os.getenv("MYSQL_USER"),
    password=os.getenv("MYSQL_PASSWORD"),
    database=os.getenv("MYSQL_DB_NAME"),
    port=int(os.getenv("MYSQL_DB_PORT")),
    cursorclass=pymysql.cursors.DictCursor
)

mongo_client = MongoClient(os.getenv("MONGO_HOST"), int(os.getenv("MONGO_PORT")))
mongo_db = mongo_client[os.getenv("MONGO_DB_NAME")]

def main():
    """
    Performs flat conversion of predefined tables to MongoDB.
    """
    tables = [
        "fahrer", "fahrzeug", "fahrt", "geraet", "geraet_installation",
        "fahrzeugparameter", "beschleunigung", "diagnose", "wartung"
    ]
    total = convert_to_mongodb(tables, embed=False)
    print(f"Conversion of {total} records completed.")

if __name__ == "__main__":
    main()
