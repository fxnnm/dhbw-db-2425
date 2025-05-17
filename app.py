import os
import logging
from dotenv import load_dotenv
from flask import Flask
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from infrastructure.config.config import MYSQL_CONFIG_STRING

# -----------------------------------------------------------------------------
# Load environment variables from .env file
# -----------------------------------------------------------------------------
load_dotenv()

# -----------------------------------------------------------------------------
# Flask application setup
# -----------------------------------------------------------------------------
app = Flask(__name__, template_folder='web/templates', static_folder="static")
app.secret_key = os.getenv("SECRET_KEY")

if not app.secret_key:
    raise ValueError("SECRET_KEY environment variable is not set.")

# -----------------------------------------------------------------------------
# Logging configuration
# -----------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# SQLAlchemy configuration
# -----------------------------------------------------------------------------
from api.routes.route import register_routes
register_routes(app)
print(f"MYSQL_CONFIG_STRING: {MYSQL_CONFIG_STRING}")
mysql_engine = create_engine(MYSQL_CONFIG_STRING)
mysql_session = sessionmaker(autocommit=False, autoflush=False, bind=mysql_engine)

# -----------------------------------------------------------------------------
# Database Setup and Initialization
# -----------------------------------------------------------------------------

def setup_tables():
    """
    Creates all required tables and imports CSV data on first startup.
    Skips execution if tables already exist.
    """
    expected_tables = [
        "fahrzeug", "fahrer", "fahrer_fahrzeug", "geraet", "fahrt", "fahrt_fahrer",
        "fahrzeugparameter", "beschleunigung", "diagnose", "wartung", "geraet_installation"
    ]

    try:
        with mysql_engine.connect() as conn:
            placeholders = ", ".join([":tbl" + str(i) for i in range(len(expected_tables))])
            query = f"""
                SELECT COUNT(*) FROM information_schema.tables
                WHERE table_schema = :db AND table_name IN ({placeholders})
            """
            params = {"db": os.getenv("MYSQL_DB_NAME")}
            params.update({f"tbl{i}": t for i, t in enumerate(expected_tables)})
            result = conn.execute(text(query), params)
            existing_count = result.scalar()

        if existing_count > 0:
            logger.info("Tables already exist – skipping setup.")
            return

        # Execute table creation script
        sql_file_path = os.path.join(os.path.dirname(__file__), "01_create_table.sql")
        if not os.path.exists(sql_file_path):
            raise FileNotFoundError("01_create_table.sql not found.")

        with open(sql_file_path, "r", encoding="utf-8") as file:
            statements = file.read().split(';')

        with mysql_engine.begin() as conn:
            for stmt in statements:
                if stmt.strip():
                    conn.execute(text(stmt))
        logger.info("All tables created successfully.")

        # Import initial data from CSVs
        import_path = os.path.join(os.path.dirname(__file__), "02_import_data.sql")
        if not os.path.exists(import_path):
            logger.warning("02_import_data.sql not found.")
            return

        with open(import_path, "r", encoding="utf-8") as file:
            import_statements = file.read().split(';')

        with mysql_engine.begin() as conn:
            for stmt in import_statements:
                if stmt.strip():
                    conn.execute(text(stmt))
        logger.info("CSV data imported successfully.")

    except Exception as e:
        logger.error(f"Error during setup: {e}")

def import_data():
    logger.info("import_data() is deprecated and no longer used.")

def load_reports():
    """
    Load report file for reference (not executed on startup).
    """
    try:
        sql_file_path = os.path.join(os.path.dirname(__file__), "03_reports.sql")
        if not os.path.exists(sql_file_path):
            logger.warning("Report file not found: 03_reports.sql")
        else:
            with open(sql_file_path, "r", encoding="utf-8") as file:
                _ = file.read()
            logger.info("Report file 03_reports.sql loaded for reference.")
    except Exception as e:
        logger.error(f"Error loading report file: {e}")

def load_triggers():
    """
    Load and execute all UPDATE triggers defined in 04_trigger.sql.
    Trigger statements must be separated with $$.
    """
    try:
        trigger_file_path = os.path.join(os.path.dirname(__file__), "04_trigger.sql")
        if os.path.exists(trigger_file_path):
            with open(trigger_file_path, "r", encoding="utf-8") as file:
                sql_script = file.read()

            statements = sql_script.split("$$")

            with mysql_engine.begin() as conn:
                for stmt in statements:
                    stmt = stmt.strip()
                    if stmt:
                        try:
                            conn.execute(text(stmt))
                            logger.info(f"Trigger executed: {stmt[:50]}...")
                        except Exception as stmt_error:
                            logger.error(f"Trigger error: {stmt[:50]}... - {stmt_error}")
        else:
            logger.warning("Trigger SQL file not found: 04_trigger.sql")
    except Exception as e:
        logger.error(f"Error loading triggers: {e}")

def load_stored_procedures():
    """
    Load and create all stored procedures from 05_sp.sql.
    Procedure blocks must be separated with $$.
    """
    try:
        sp_file_path = os.path.join(os.path.dirname(__file__), "05_sp.sql")
        if os.path.exists(sp_file_path):
            with open(sp_file_path, "r", encoding="utf-8") as file:
                sql_script = file.read()
            statements = sql_script.replace("DELIMITER $$", "").replace("DELIMITER ;", "").split("$$")

            with mysql_engine.begin() as conn:
                for stmt in statements:
                    stmt = stmt.strip()
                    if stmt:
                        try:
                            conn.execute(text(stmt))
                            logger.info(f"Stored procedure executed: {stmt[:50]}...")
                        except Exception as stmt_error:
                            logger.error(f"Stored procedure error: {stmt[:50]}... - {stmt_error}")
        else:
            logger.warning("Stored procedure file not found: 05_sp.sql")
    except Exception as e:
        logger.error(f"Error loading stored procedures: {e}")

# -----------------------------------------------------------------------------
# Routes
# -----------------------------------------------------------------------------

@app.route('/')
def health_check():
    """Simple route to confirm the application is running."""
    return {"status": "App is running"}, 200

@app.route('/execute-import', methods=['POST'])
def execute_import():
    """Disabled to avoid repeated import after startup."""
    return "This endpoint is disabled to prevent re-execution of the import script.", 403

# -----------------------------------------------------------------------------
# Application Entry Point
# -----------------------------------------------------------------------------
debug_mode = os.getenv("FLASK_DEBUG", "false").lower() == "true"

if __name__ == '__main__':
    setup_tables()
    load_reports()
    load_triggers()
    load_stored_procedures()
    app.run(debug=debug_mode)
