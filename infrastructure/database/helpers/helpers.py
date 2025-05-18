import pymongo
import mysql.connector
from sqlalchemy import MetaData
import os
from datetime import datetime, date
from infrastructure.config.config import (MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DB_NAME, MONGO_DB_NAME,
                                          ALLOWED_TABLES, ALLOWED_EXTENSIONS, MONGO_CONFIG_STRING)


# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

def get_tables():
    """
    Reads all tables from the relational database using automatic reflection.
    """
    from app import mysql_engine  # Import here to avoid circular dependency
    meta = MetaData()
    meta.reflect(bind=mysql_engine)
    return meta.tables.keys()


def get_mongo_client():
    """
    Returns a new MongoDB client instance.
    """
    return pymongo.MongoClient(MONGO_CONFIG_STRING)


def insert_message_to_mysql(message, duration):
    """
    Inserts a success or error message into the 'success_logs' table in MySQL.
    """
    try:
        conn = get_mysql_connection()
        cursor = conn.cursor()
        query = """
            INSERT INTO success_logs (message, duration) 
            VALUES (%s, %s)
        """
        cursor.execute(query, (message, duration))
        conn.commit()
        cursor.close()
        conn.close()
    except mysql.connector.Error as err:
        print(f"Error writing success message to MySQL: {err}")


def allowed_file(filename):
    """
    Checks whether the provided filename has an allowed extension (JSON).
    """
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def get_mysql_connection():
    """
    Returns a new MySQL database connection.
    Use this function to avoid repeated connection setups.
    """
    return mysql.connector.connect(
        host=MYSQL_HOST,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DB_NAME
    )
  
def insert_conversion_log(table_name, count):
    """
    Inserts a conversion log into the konvertierung_log table in MySQL.
    """
    try:
        conn = get_mysql_connection()
        cursor = conn.cursor()
        query = """
            INSERT INTO konvertierung_log (tabelle, anzahl)
            VALUES (%s, %s)
        """
        cursor.execute(query, (table_name, count))
        conn.commit()
        cursor.close()
        conn.close()
    except mysql.connector.Error as err:
        print(f"Error writing conversion log to MySQL: {err}")


# Add this function to `helpers.py`
def get_db(table_name=None):
    """
    Returns a database connection based on the table name:
    - MySQL for relational tables
    - MongoDB for NoSQL collections
    """
    if table_name in ALLOWED_TABLES:
        return get_mysql_connection()
    else:
        # Return MongoDB collection for NoSQL collections
        mongo_client = get_mongo_client()
        db = mongo_client[os.getenv("MONGO_DB_NAME", "production")]
        return db[table_name]


def convert_to_mongodb(selected_tables, embed=True):
    """
    Converts specified tables from MySQL to MongoDB. If 'embed' is True, embeds related data into a single 'embedded' collection; else flat collections.
    """
    from app import mysql_engine, mysql_session

    client = get_mongo_client()
    db = client[MONGO_DB_NAME]

    session = mysql_session()
    meta = MetaData()
    meta.reflect(bind=mysql_engine)

    def fix_dates(data):
        """
        Converts datetime.date objects to datetime.datetime to ensure compatibility
        with MongoDB.
        """
        for key, value in data.items():
            if isinstance(value, date):
                data[key] = datetime(value.year, value.month, value.day)
        return data

    total_inserted = 0
    if embed:
        # Single embedded collection: clear previous contents
        embedded_collection = db['embedded']
        embedded_collection.delete_many({})
        for table_name in selected_tables:
            if table_name not in meta.tables:
                print(f"Table {table_name} not found. Skipping.")
                continue
            table = meta.tables[table_name]
            result = session.execute(table.select())
            raw_rows = result.mappings().all()
            rows = []
            for rm in raw_rows:
                data = dict(rm)
                data = fix_dates(data)
                # mark source in embedded mode
                data['source_table'] = table_name
                rows.append(data)
            if rows:
                try:
                    embedded_collection.insert_many(rows)
                    total_inserted += len(rows)
                    print(f"Inserted {len(rows)} rows from {table_name} into embedded collection.")
                    insert_conversion_log(table_name, len(rows))
                except Exception as e:
                    print(f"Error inserting {table_name} data: {e}")
    else:
        # Flat collections per table
        for table_name in selected_tables:
            if table_name not in meta.tables:
                print(f"Table {table_name} not found. Skipping.")
                continue
            table = meta.tables[table_name]
            result = session.execute(table.select())
            raw_rows = result.mappings().all()
            rows = [fix_dates(dict(rm)) for rm in raw_rows]
            collection = db[table_name]
            collection.delete_many({})
            if rows:
                try:
                    collection.insert_many(rows)
                    total_inserted += len(rows)
                    print(f"Inserted {len(rows)} rows into {table_name} collection.")
                    insert_conversion_log(table_name, len(rows))
                except Exception as e:
                    print(f"Error inserting {table_name} data: {e}")
    session.close()
    print("Conversion completed.")
    return total_inserted

def load_report_sql(report_key):
    # Open the SQL file that contains multiple named report queries
    with open("03_reports.sql", "r", encoding="utf-8") as f:
        lines = f.readlines()

    # State variables to track the parsing status
    inside_block = False            # True when currently inside the desired report block
    current_key = None              # Current report key being processed
    report_lines = []              # List to collect the SQL lines for the matched report

    for line in lines:
        # Check for the start of a report block
        if line.strip().startswith("-- REPORT:"):
            current_key = line.strip().split(":", 1)[1].strip()
            # Enable block collection only if the current key matches the desired one
            inside_block = (current_key == report_key)
            continue

        # End of report block
        elif line.strip().startswith("-- ENDREPORT"):
            if inside_block:
                break  # Stop processing once the full block has been collected
            inside_block = False

        # Collect lines only if we are inside the correct report block
        elif inside_block:
            report_lines.append(line.rstrip())

    # Return the collected SQL statement as a single string (or None if not found)
    return "\n".join(report_lines) if report_lines else None
