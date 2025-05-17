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
# Function to execute SQL scripts during startup
# -----------------------------------------------------------------------------

def execute_startup_scripts():
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
                        logger.info(f"Executed statement: {stmt[:50]}...")
                    except Exception as stmt_error:
                        logger.error(f"Error executing statement: {stmt[:50]}... - {stmt_error}")

        logger.info("Tabellen wurden erfolgreich erstellt.")

        # Execute the second script
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
    except FileNotFoundError as fnf_error:
        logger.error(fnf_error)
    except Exception as e:
        logger.error("Fehler beim Ausführen der Startskripte: %s", e)

# Automatically execute the 03_reports.sql script on app startup
try:
    sql_file_path = os.path.join(os.path.dirname(__file__), "03_reports.sql")

    if not os.path.exists(sql_file_path):
        logger.warning("Report file not found: 03_reports.sql")
    else:
        with open(sql_file_path, "r", encoding="utf-8") as file:
            sql_script = file.read()

        # Check if it's only SELECT statements (not required to execute at startup)
        logger.info("Report file 03_reports.sql loaded for reference.")
except Exception as e:
    logger.error(f"Error loading report file: {e}")

# Automatically setup trigger from script 04_trigger.sql
try:
    trigger_file_path = os.path.join(os.path.dirname(__file__), "04_trigger.sql")

    if os.path.exists(trigger_file_path):
        with open(trigger_file_path, "r", encoding="utf-8") as file:
            sql_script = file.read()

        # Triggers have to be correctly replaced with DELIMITER $$ ... $$ DELIMITER ;
        statements = sql_script.replace("DELIMITER $$", "").replace("DELIMITER ;", "").split("$$")

        with mysql_engine.begin() as conn:
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:
                    try:
                        conn.execute(text(stmt))
                        logger.info(f"Trigger-Statement ausgeführt: {stmt[:50]}...")
                    except Exception as stmt_error:
                        logger.error(f"Fehler beim Trigger: {stmt[:50]}... - {stmt_error}")
    else:
        logger.warning("Trigger-SQL-Datei nicht gefunden: 04_trigger.sql")
except Exception as e:
    logger.error(f"Fehler beim Einbinden der Trigger-Datei: {e}")

# Automatically execute stored procedure from 05_sp.sql
try:
    sp_file_path = os.path.join(os.path.dirname(__file__), "05_sp.sql")

    if os.path.exists(sp_file_path):
        with open(sp_file_path, "r", encoding="utf-8") as file:
            sql_script = file.read()

        # MySQL DELIMITER $$ entfernen und Split vorbereiten
        statements = sql_script.replace("DELIMITER $$", "").replace("DELIMITER ;", "").split("$$")

        with mysql_engine.begin() as conn:
            for stmt in statements:
                stmt = stmt.strip()
                if stmt:
                    try:
                        conn.execute(text(stmt))
                        logger.info(f"Stored Procedure Statement ausgeführt: {stmt[:50]}...")
                    except Exception as stmt_error:
                        logger.error(f"Fehler bei Stored Procedure: {stmt[:50]}... - {stmt_error}")
    else:
        logger.warning("Stored Procedure SQL-Datei nicht gefunden: 05_sp.sql")
except Exception as e:
    logger.error(f"Fehler beim Einbinden der Stored Procedure Datei: {e}")


# Add a default route for health check
@app.route('/')
def health_check():
    return {"status": "App is running"}, 200

# Function to execute the 02_import_data.sql script
@app.route('/execute-import', methods=['POST'])
def execute_import():
    return "This endpoint is disabled to prevent re-execution of the import script.", 403

# Conditional debug mode based on environment variable
debug_mode = os.getenv("FLASK_DEBUG", "false").lower() == "true"

# -----------------------------------------------------------------------------
# Main Entrypoint
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    execute_startup_scripts()  # Call the function only during startup
    app.run(debug=debug_mode)

