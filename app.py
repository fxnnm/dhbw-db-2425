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
# Initialization Steps
# -----------------------------------------------------------------------------

def setup_tables():
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
            logger.info("Tabellen existieren bereits – Setup wird übersprungen.")
            return

        # Tabellen erstellen
        sql_file_path = os.path.join(os.path.dirname(__file__), "01_create_table.sql")
        if not os.path.exists(sql_file_path):
            raise FileNotFoundError("01_create_table.sql nicht gefunden.")

        with open(sql_file_path, "r", encoding="utf-8") as file:
            statements = file.read().split(';')

        with mysql_engine.begin() as conn:
            for stmt in statements:
                if stmt.strip():
                    conn.execute(text(stmt))
        logger.info("Alle Tabellen wurden erstellt.")

        # Importdaten laden
        import_path = os.path.join(os.path.dirname(__file__), "02_import_data.sql")
        if not os.path.exists(import_path):
            logger.warning("02_import_data.sql nicht gefunden.")
            return

        with open(import_path, "r", encoding="utf-8") as file:
            import_statements = file.read().split(';')

        with mysql_engine.begin() as conn:
            for stmt in import_statements:
                if stmt.strip():
                    conn.execute(text(stmt))
        logger.info("CSV-Daten wurden importiert.")

    except Exception as e:
        logger.error(f"Fehler beim Setup: {e}")

def import_data():
    logger.info("import_data() ist veraltet und wird nicht mehr verwendet.")

def load_reports():
    try:
        sql_file_path = os.path.join(os.path.dirname(__file__), "03_reports.sql")
        if not os.path.exists(sql_file_path):
            logger.warning("Report file not found: 03_reports.sql")
        else:
            with open(sql_file_path, "r", encoding="utf-8") as file:
                sql_script = file.read()
            logger.info("Report file 03_reports.sql loaded for reference.")
    except Exception as e:
        logger.error(f"Error loading report file: {e}")

def load_triggers():
    try:
        trigger_file_path = os.path.join(os.path.dirname(__file__), "04_trigger.sql")
        if os.path.exists(trigger_file_path):
            with open(trigger_file_path, "r", encoding="utf-8") as file:
                sql_script = file.read()

            # Kein DELIMITER-Ersatz nötig – direkt mit $$ splitten
            statements = sql_script.split("$$")

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

def load_stored_procedures():
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

@app.route('/execute-import', methods=['POST'])
def execute_import():
    return "This endpoint is disabled to prevent re-execution of the import script.", 403

# Conditional debug mode based on environment variable
debug_mode = os.getenv("FLASK_DEBUG", "false").lower() == "true"

# -----------------------------------------------------------------------------
# Main Entrypoint
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    setup_tables()
    load_reports()
    load_triggers()
    load_stored_procedures()
    app.run(debug=debug_mode)