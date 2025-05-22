import pymongo
import mysql.connector
from sqlalchemy import MetaData, select, and_
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
    Convert tables from MySQL into MongoDB collections.

    Parameters:
      selected_tables: list of MySQL table names to export.
      embed: bool flag. If True, combine all tables into one 'embedded' MongoDB collection; if False, create separate collections per table.

    Returns:
      Total number of documents inserted into MongoDB.
    """
    # Import MySQL engine and sessionmaker to avoid circular dependency
    from app import mysql_engine, mysql_session

    session = mysql_session()
    try:
        # Establish MongoDB connection
        client = get_mongo_client()
        db = client[MONGO_DB_NAME]

        # Open a SQLAlchemy session for MySQL queries
        session = mysql_session()
        meta = MetaData()
        meta.reflect(bind=mysql_engine)

        # Helper: convert Python date objects to datetime for MongoDB compatibility
        def fix_dates(data):
            """
            Convert datetime.date fields to datetime.datetime.
            """
            for key, value in data.items():
                if isinstance(value, date):
                    data[key] = datetime(value.year, value.month, value.day)
            return data

        # Counter for inserted documents
        total_inserted = 0

        if embed:
            AVAILABLE_TABLES = ["fahrer", "fahrzeug", "geraet", "geraet_installation", "fahrzeugparameter", "beschleunigung", "diagnose", "wartung"]
            selected = [tbl for tbl in selected_tables if tbl in AVAILABLE_TABLES]

            embedded_collection = db['EmbeddedFahrt']
            embedded_collection.delete_many({})

            # Prefetch related tables
            fahrzeug_table = meta.tables.get('fahrzeug')
            geraet_table = meta.tables.get('geraet')
            fahrt_fahrer_table = meta.tables.get('fahrt_fahrer')
            fahrer_table = meta.tables.get('fahrer')
            fahrzeugparameter_table = meta.tables.get('fahrzeugparameter')
            beschleunigung_table = meta.tables.get('beschleunigung')
            diagnose_table = meta.tables.get('diagnose')
            wartung_table = meta.tables.get('wartung')
            geraet_installation_table = meta.tables.get('geraet_installation')

            def fetch_all(table):
                return session.execute(select(table)).mappings().all() if table is not None else []

            # Build lookup dictionaries
            fahrzeug_data = {row['id']: fix_dates(dict(row)) for row in fetch_all(fahrzeug_table)}
            geraet_data = {}
            for row in fetch_all(geraet_table):
                d = fix_dates(dict(row))
                geraet_data.setdefault(d['id'], []).append(d)

            # Driver-pivot data
            fahrer_lookup = {row['id']: fix_dates(dict(row)) for row in fetch_all(fahrer_table)}
            fahrt_fahrer_data = {}
            for row in fetch_all(fahrt_fahrer_table):
                r = dict(row)
                f_id, fr_id = r.get('fahrtid'), r.get('fahrerid')
                if fr_id in fahrer_lookup:
                    fahrt_fahrer_data.setdefault(f_id, []).append(fahrer_lookup[fr_id])

            # Other child tables grouped by key
            def group_by(table, key):
                data = {}
                for row in fetch_all(table):
                    r = fix_dates(dict(row))
                    data.setdefault(r.get(key), []).append(r)
                return data

            fahrzeugparameter_data = group_by(fahrzeugparameter_table, 'fahrtid')
            beschleunigung_data = group_by(beschleunigung_table, 'fahrtid')
            diagnose_data = group_by(diagnose_table, 'fahrtid')
            wartung_data = group_by(wartung_table, 'fahrzeugid')
            geraet_installation_data = group_by(geraet_installation_table, 'fahrzeugid')

            # Fetch all fahrt rows
            parents = session.execute(select(meta.tables['fahrt'])).mappings().all()
            embedded_docs = []
            for parent in parents:
                doc = fix_dates(dict(parent))
                f_id = doc.get('id')
                fv_id = doc.get('fahrzeugid')
                gd_id = doc.get('geraetid')
                doc['fahrzeug'] = fahrzeug_data.get(fv_id)
                doc['fahrer'] = fahrt_fahrer_data.get(f_id, [])
                doc['fahrzeugparameter'] = fahrzeugparameter_data.get(f_id, [])
                doc['beschleunigung'] = beschleunigung_data.get(f_id, [])
                doc['diagnose'] = diagnose_data.get(f_id, [])
                doc['wartung'] = wartung_data.get(fv_id, [])
                doc['geraet_installation'] = geraet_installation_data.get(fv_id, [])
                doc['geraet'] = geraet_data.get(gd_id, [])
                embedded_docs.append(doc)

            if embedded_docs:
                embedded_collection.insert_many(embedded_docs)
                total_inserted += len(embedded_docs)
            print(f"Inserted {total_inserted} embedded documents into 'EmbeddedFahrt' collection.")
        else:
             # FLAT MODE: create one MongoDB collection per table
            for table_name in selected_tables:
                if table_name not in meta.tables:
                    print(f"Table {table_name} not found. Skipping.")
                    continue
                table = meta.tables[table_name]
                result = session.execute(table.select())
                raw_rows = result.mappings().all()
                rows = [fix_dates(dict(rm)) for rm in raw_rows]
                collection = db[table_name]
                collection.delete_many({})  # Clear existing documents
                if rows:
                    try:
                        collection.insert_many(rows)
                        total_inserted += len(rows)
                        print(f"Inserted {len(rows)} rows into {table_name} collection.")
                        # Log conversion in MySQL
                        insert_conversion_log(table_name, len(rows))
                    except Exception as e:
                        print(f"Error inserting {table_name} data: {e}")

        # Close the SQL session and return the total count
        print("Conversion completed.")
        return total_inserted
    except Exception as e:
        print(f"Error during migration: {e}")
    finally:
        session.close()

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
