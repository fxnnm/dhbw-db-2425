import os
import logging
from dotenv import load_dotenv
from flask import Flask
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from infrastructure.config.config import MYSQL_CONFIG_STRING

# -----------------------------------------------------------------------------
# Load Environment Variables
# -----------------------------------------------------------------------------
load_dotenv()

# -----------------------------------------------------------------------------
# Flask Application Setup
# -----------------------------------------------------------------------------
app = Flask(__name__, template_folder='web/templates', static_folder="static")
app.secret_key = os.getenv("SECRET_KEY")

# Ensure SECRET_KEY is set
if not app.secret_key:
    raise ValueError("SECRET_KEY environment variable is not set.")

# -----------------------------------------------------------------------------
# Logging Setup
# -----------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

from api.routes.route import register_routes
register_routes(app)
print(f"MYSQL_CONFIG_STRING: {MYSQL_CONFIG_STRING}")
mysql_engine = create_engine(MYSQL_CONFIG_STRING)
mysql_session = sessionmaker(autocommit=False, autoflush=False, bind=mysql_engine)

# -----------------------------------------------------------------------------
# Tabellen in MySQL erstellen
# -----------------------------------------------------------------------------
# Add a flag to ensure scripts are executed only once during app startup
scripts_executed = False

if not scripts_executed:
    try:
        sql_file_path = os.path.join(os.path.dirname(__file__), "01_create_table.sql")

        if not os.path.exists(sql_file_path):
            raise FileNotFoundError(f"SQL file not found: {sql_file_path}")

        with open(sql_file_path, "r", encoding="utf-8") as file:
            sql_script = file.read()

        statements = sql_script.split(';')

        with mysql_engine.begin() as connection:
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:  # Skip empty or whitespace-only statements
                    try:
                        connection.execute(text(stmt))
                        logger.info(f"Executed statement: {stmt[:50]}...")  # Log the first 50 characters of the statement
                    except Exception as stmt_error:
                        logger.error(f"Error executing statement: {stmt[:50]}... - {stmt_error}")

        logger.info("Tabellen wurden erfolgreich erstellt.")
        scripts_executed = True
    except FileNotFoundError as fnf_error:
        logger.error(fnf_error)
    except Exception as e:
        logger.error("Fehler beim Erstellen der Tabellen: %s", e)

# Automatically execute the 02_import_data.sql script on app startup
try:
    sql_file_path = os.path.join(os.path.dirname(__file__), "02_import_data.sql")

    if not os.path.exists(sql_file_path):
        logger.error("SQL file not found: 02_import_data.sql")
    else:
        with open(sql_file_path, "r", encoding="utf-8") as file:
            sql_script = file.read()

        statements = sql_script.split(';')

        with mysql_engine.begin() as connection:
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:  # Skip empty or whitespace-only statements
                    try:
                        connection.execute(text(stmt))
                        logger.info(f"Executed statement: {stmt[:50]}...")
                    except Exception as stmt_error:
                        logger.error(f"Error executing statement: {stmt[:50]}... - {stmt_error}")

        logger.info("Import script executed successfully.")
except Exception as e:
    logger.error(f"Error executing import script on startup: {e}")

# Add a default route for health check
@app.route('/')
def health_check():
    return {"status": "App is running"}, 200

# Function to execute the 02_import_data.sql script
@app.route('/execute-import', methods=['POST'])
def execute_import():
    try:
        sql_file_path = os.path.join(os.path.dirname(__file__), "02_import_data.sql")

        if not os.path.exists(sql_file_path):
            return "SQL file not found.", 404

        with open(sql_file_path, "r", encoding="utf-8") as file:
            sql_script = file.read()

        statements = sql_script.split(';')

        with mysql_engine.begin() as connection:
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:  # Skip empty or whitespace-only statements
                    connection.execute(text(stmt))

        return "Import script executed successfully.", 200
    except Exception as e:
        logger.error(f"Error executing import script: {e}")
        return f"Error executing import script: {e}", 500

# Conditional debug mode based on environment variable
debug_mode = os.getenv("FLASK_DEBUG", "false").lower() == "true"

# -----------------------------------------------------------------------------
# Main Entrypoint
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    app.run(debug=debug_mode)

