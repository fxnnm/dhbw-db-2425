# File: clean_files.py
# This script creates clean versions of the problematic files
# with fixed indentation and all ERGAENZEN parts replaced.

# 1. First, create the fixed route.py
route_py = '''# filepath: c:\\Users\\finnm\\Documents\\HAUPTORDNER\\Studium\\Sem4\\DB\\dhbw-db-2425\\api\\routes\\route.py
from datetime import datetime
import json
import pymongo
from infrastructure.database.helpers.helpers import (allowed_file, get_tables, convert_to_mongodb,
                                                     insert_message_to_mysql, get_db)
from infrastructure.config.config import MONGO_CONFIG_STRING, MONGO_DB_NAME, ALLOWED_TABLES
from sqlalchemy import MetaData, text
from flask import flash
from infrastructure.database.helpers.helpers import get_mysql_connection
from flask import render_template, request, redirect, url_for, jsonify


# -----------------------------------------------------------------------------
# Homepage Route
# -----------------------------------------------------------------------------
def register_routes(app):
    """Registers all Flask routes inside app.py."""

    @app.route('/')
    def index():
        """Homepage that displays available MySQL tables."""
        tables = get_tables()
        return render_template('index.html', tables=tables, app_version='0.2.14')

    # Version Route for Frontend Fetch

    @app.route('/add-data', methods=['GET', 'POST'])
    def add_data():
        """
        Page that allows users to upload a JSON file and insert its contents into
        a MongoDB collection (either existing or a new one).
        """
        client = pymongo.MongoClient(MONGO_CONFIG_STRING)
        db = client[MONGO_DB_NAME]
        success_message = None
        error_message = None

        if request.method == 'POST':
            collection_choice = request.form.get('collection_choice')

            # Existing collection
            if collection_choice == 'existing':
                selected_table = request.form.get('table_name')
                if selected_table not in ALLOWED_TABLES:
                    error_message = "Invalid table selected."
                    return render_template(
                        'add_data.html',
                        tables=ALLOWED_TABLES,
                        success_message=success_message,
                        error_message=error_message
                    )
                target_collection = selected_table

            else:
                # Create a new collection
                new_collection_name = request.form.get('new_collection_name')
                if not new_collection_name or new_collection_name.strip() == "":
                    error_message = "Please provide a valid name for the new collection."
                    return render_template(
                        'add_data.html',
                        tables=ALLOWED_TABLES,
                        success_message=success_message,
                        error_message=error_message
                    )
                target_collection = new_collection_name.strip()

            # Check if a JSON file was uploaded
            if 'json_file' not in request.files:
                error_message = "No file uploaded."
            else:
                file = request.files['json_file']
                if file.filename == '':
                    error_message = "No file selected."
                elif file and allowed_file(file.filename):
                    file_content = file.read().decode('utf-8')
                    try:
                        data = json.loads(file_content)

                        if isinstance(data, dict):
                            db[target_collection].insert_one(data)
                            success_message = "Successfully added one document!"
                        elif isinstance(data, list):
                            if data:
                                db[target_collection].insert_many(data)
                                success_message = f"{len(data)} documents successfully added!"
                            else:
                                error_message = "The JSON file contains an empty array."
                        else:
                            error_message = "The JSON file must contain either an object or an array of objects."

                    except json.JSONDecodeError as exc:
                        error_message = f"Invalid JSON format: {exc}"
                else:
                    error_message = "Invalid file type. Please upload a .json file."

        return render_template(
            'add_data.html',
            tables=ALLOWED_TABLES,
            success_message=success_message,
            error_message=error_message
        )

    @app.route('/reports', methods=['GET', 'POST'])
    def reports():
        """
        Page that allows users to run reports using MySQL queries instead of MongoDB aggregation.
        """
        conn = get_mysql_connection()  # ✅ Uses default DB settings from .env/config

        available_reports = {
            "fahrten_fahrer": "Anzahl der Fahrten pro Fahrer",
            "fahrten_fahrer": "Anzahl der Fahrten pro Fahrer",
        }

        if request.method == 'POST':
            selected_report = request.form.get('report_type')
            return redirect(url_for('reports', report_type=selected_report))
        else:
            selected_report = request.args.get('report_type')
            page = request.args.get('page', 1, type=int)

        report_data = []

        # Connect to MySQL
        cursor = conn.cursor()        
        # -------------------------------------------------------------------------
        # 🚗 Report: Anzahl der Fahrten pro Fahrer
        # -------------------------------------------------------------------------
        if selected_report == "fahrten_fahrer":
            query = """
               SELECT f.id as fahrerID, f.vorname, f.nachname, COUNT(ff.fahrtid) as anzahl_fahrten
               FROM fahrer f
               LEFT JOIN fahrt_fahrer ff ON f.id = ff.fahrerid
               GROUP BY f.id, f.vorname, f.nachname
               ORDER BY anzahl_fahrten DESC
            """
            cursor.execute(query)
            report_data = cursor.fetchall()
            report_data = [
                {"fahrerID": row[0], "vorname": row[1], "nachname": row[2], "anzahl_fahrten": row[3]}
                for row in report_data]

        # Close MySQL connection
        cursor.close()
        conn.close()

        # -------------------------------------------------------------------------
        # Pagination
        # -------------------------------------------------------------------------
        items_per_page = 10
        total_items = len(report_data)
        total_pages = (total_items + items_per_page - 1) // items_per_page

        start = (page - 1) * items_per_page
        end = start + items_per_page
        page_data = report_data[start:end]

        return render_template(
            'reports.html',
            available_reports=available_reports,
            report_data=page_data,
            selected_report=selected_report,
            page=page,
            total_pages=total_pages
        )
    # Add more routes here...

    @app.route('/database-stats', methods=['GET'])
    def get_database_stats():
        """Fetch statistics from both MongoDB and MySQL."""
        stats = {
            "MongoDB": {},
            "MySQL": {}
        }

        # -------------------- ✅ Fetch MongoDB Stats ✅ --------------------
        try:
            mongo_client = pymongo.MongoClient(MONGO_CONFIG_STRING)
            mongo_db = mongo_client[MONGO_DB_NAME]

            collections = mongo_db.list_collection_names()
            if not collections:
                stats["MongoDB"]["error"] = "No collections found"

            for collection_name in collections:
                collection = mongo_db[collection_name]
                total_rows = collection.count_documents({})

                # Fetch last updated time from _id field
                last_updated_doc = collection.find_one(sort=[("_id", -1)])
                last_updated_time = last_updated_doc["_id"].generation_time.strftime(
                    '%Y-%m-%d %H:%M:%S') if last_updated_doc else "N/A"

                stats["MongoDB"][collection_name] = {
                    "total_rows": total_rows,
                    "last_updated": last_updated_time
                }

        except Exception as e:
            stats["MongoDB"]["error"] = str(e)

        # -------------------- ✅ Fetch MySQL Stats ✅ --------------------
        try:
            conn = get_mysql_connection()  # ✅ Uses default DB settings from .env/config

            query = """
                SELECT 
                    TABLE_NAME as table_name, 
                    (SELECT COUNT(*) FROM information_schema.tables 
                     WHERE table_schema = %s AND table_name = t.TABLE_NAME) as total_rows,
                    (SELECT MAX(UPDATE_TIME) FROM information_schema.tables 
                     WHERE table_schema = %s AND table_name = t.TABLE_NAME) as last_updated
                FROM 
                    information_schema.tables t
                WHERE 
                    t.TABLE_SCHEMA = %s
                AND 
                    t.TABLE_TYPE = 'BASE TABLE'
                ORDER BY 
                    t.TABLE_NAME
            """

            # ✅ Ensure cursor returns dictionaries instead of tuples
            cursor = conn.cursor(dictionary=True)
            cursor.execute(query, ("telematik", "telematik", "telematik"))
            tables = cursor.fetchall()

            # ✅ Process MySQL results correctly
            for table in tables:
                stats["MySQL"][table["table_name"]] = {
                    "total_rows": table["total_rows"] if table["total_rows"] is not None else "N/A",
                    "last_updated": table["last_updated"] if table["last_updated"] else "N/A"
                }

            cursor.close()
            conn.close()

        except Exception as e:
            stats["MySQL"]["error"] = str(e)

        return jsonify(stats)

    @app.route('/view-table', methods=['GET', 'POST'])
    def view_table():
        """
        Page that lets users query a MySQL table and view rows with pagination.
        """
        from app import mysql_engine
        if request.method in ['POST', 'GET']:
            selected_table = (
                request.form.get('selected_table')
                if request.method == 'POST'
                else request.args.get('selected_table')
            )
            page = int(request.args.get('page', 1))
            rows_per_page = 10
            
            if selected_table:
                meta = MetaData()
                meta.reflect(bind=mysql_engine)
                table = meta.tables[selected_table]
                
                rows = []
                total_rows = 0
                
                with mysql_engine.connect() as conn:
                    try:
                        count_query = text(f"SELECT COUNT(*) FROM {selected_table}")
                        total_rows_query = conn.execute(count_query)
                        total_rows = total_rows_query.scalar()

                        offset = (page - 1) * rows_per_page
                        query = table.select().limit(rows_per_page).offset(offset)
                        result = conn.execute(query)

                        # Convert rows to a list of dictionaries
                        if hasattr(result, 'keys'):
                            rows = [dict(zip(result.keys(), row)) for row in result]
                        else:
                            rows = [row._asdict() for row in result]

                    except Exception as exc:
                        print(f"Error processing rows: {exc}")
                        rows = []

                total_pages = (total_rows + rows_per_page - 1) // rows_per_page

                return render_template(
                    'view_table.html',
                    table_name=selected_table,
                    rows=rows,
                    page=page,
                    total_pages=total_pages,
                    rows_per_page=rows_per_page,
                    selected_table=selected_table
                )

        # If no table is selected, redirect to the main page
        return redirect(url_for('index'))

    @app.route('/convert', methods=['GET', 'POST'])
    def convert():
        """
        Page that allows users to convert selected MySQL tables to MongoDB, optionally
        embedding related tables into a single 'embedded' collection.
        """
        if request.method == 'POST':
            selected_tables = request.form.getlist('tables')
            convert_all = request.form.get('convert_all')
            embed = request.form.get('embed')

            # If user selects 'convert all', override selected_tables
            if convert_all == 'true':
                selected_tables = ALLOWED_TABLES

            do_embed = (embed == 'true')
            start_time = datetime.now()

            try:
                if selected_tables:
                    # Perform conversion
                    num_inserted_rows = convert_to_mongodb(selected_tables, do_embed)

                    # Calculate and store duration
                    end_time = datetime.now()
                    duration = (end_time - start_time).total_seconds()

                    success_message = f"Conversion of {num_inserted_rows} items completed!"
                    insert_message_to_mysql(success_message, duration)

                    return render_template('convert.html', success_message=success_message)

                return render_template('convert.html', success_message="No tables selected.")

            except Exception as exc:
                end_time = datetime.now()
                duration = (end_time - start_time).total_seconds()

                error_message = f"Error during conversion: {str(exc)}"
                insert_message_to_mysql(error_message, duration)

                return render_template('convert.html', success_message=error_message)

        return render_template('convert.html')

    @app.route('/update/<table_name>', methods=['POST'])
    def update_row(table_name):
        try:
            db = get_db(table_name)
        except Exception as e:
            flash(f"Database error: {e}", "danger")
            return redirect(url_for('view_table', selected_table=table_name))
            
        row_id = request.form.get('id')
        update_data = {k: v for k, v in request.form.items() if k != 'id'}

        try:
            if table_name in ALLOWED_TABLES:
                # MySQL Update
                cursor = db.cursor()
                set_clause = ", ".join(f"{key} = %s" for key in update_data.keys())
                query = f"UPDATE {table_name} SET {set_clause} WHERE id = %s"
                values = list(update_data.values()) + [row_id]
                cursor.execute(query, values)
                db.commit()
                cursor.close()
            else:
                # MongoDB Update
                db.update_one({"id": int(row_id)}, {"$set": update_data})

            flash(f"Row updated successfully in {table_name}", "success")
        except Exception as e:
            flash(f"Error updating row: {str(e)}", "danger")

        return redirect(url_for('view_table', selected_table=table_name))
'''

# 2. Now create the fixed helpers.py file
helpers_py = '''# filepath: c:\\Users\\finnm\\Documents\\HAUPTORDNER\\Studium\\Sem4\\DB\\dhbw-db-2425\\infrastructure\\database\\helpers\\helpers.py
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
    Converts specified tables from MySQL to MongoDB. If 'embed' is True, it embeds
    related data into a single 'embedded' collection; otherwise, each table is
    converted to its own MongoDB collection.
    """
    from app import mysql_engine, mysql_session

    client = pymongo.MongoClient(MONGO_CONFIG_STRING)
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

    # If embed is True, create a single embedded collection
    if embed:
        # Create a new collection for the embedded data
        embedded_collection = db['embedded']
        
        # Loop through each table and get data
        for table_name in selected_tables:
            if table_name not in meta.tables:
                print(f"Table {table_name} not found. Skipping.")
                continue
                
            table = meta.tables[table_name]
            query = table.select()
            result = session.execute(query)
            rows = [dict(row) for row in result]
            
            # Fix date objects for MongoDB compatibility
            rows = [fix_dates(row) for row in rows]
            
            # Add table_name as a field to identify the source table
            for row in rows:
                row['source_table'] = table_name
            
            # Insert all rows in one batch
            if rows:
                try:
                    embedded_collection.insert_many(rows)
                    total_inserted += len(rows)
                    print(f"Inserted {len(rows)} rows from {table_name} into embedded collection.")
                except Exception as e:
                    print(f"Error inserting {table_name} data: {e}")
    else:
        # Create separate collections for each table
        for table_name in selected_tables:
            if table_name not in meta.tables:
                print(f"Table {table_name} not found. Skipping.")
                continue
                
            table = meta.tables[table_name]
            query = table.select()
            result = session.execute(query)
            rows = [dict(row) for row in result]
            
            # Fix date objects for MongoDB compatibility
            rows = [fix_dates(row) for row in rows]
            
            # Create or clear collection
            collection = db[table_name]
            collection.delete_many({})  # Clear existing data
            
            # Insert all rows in one batch
            if rows:
                try:
                    collection.insert_many(rows)
                    total_inserted += len(rows)
                    print(f"Inserted {len(rows)} rows into {table_name} collection.")
                except Exception as e:
                    print(f"Error inserting {table_name} data: {e}")

    session.close()
    print("Conversion completed.")
    return total_inserted  #
'''

# 3. Write the fixed files
with open(r'c:\Users\finnm\Documents\HAUPTORDNER\Studium\Sem4\DB\dhbw-db-2425\api\routes\route.py.fixed', 'w') as f:
    f.write(route_py)

with open(r'c:\Users\finnm\Documents\HAUPTORDNER\Studium\Sem4\DB\dhbw-db-2425\infrastructure\database\helpers\helpers.py.fixed', 'w') as f:
    f.write(helpers_py)

print("Fixed files created with the .fixed extension. Now you can replace the original files with these fixed versions.")
