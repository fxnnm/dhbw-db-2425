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
try:
    sql_file_path = os.path.join(os.path.dirname(__file__), "data", "create_table.sql")

    with open(sql_file_path, "r", encoding="utf-8") as file:
        sql_script = file.read()
    
    statements = sql_script.split(';')

    with mysql_engine.begin() as connection:
        for stmt in statements:
            stmt = stmt.strip()
            # Leere Zeilen, reine Kommentarzeilen etc. überspringen
            if stmt:
                connection.execute(text(stmt))
    
    logger.info("Tabellen wurden erfolgreich erstellt.")
except Exception as e:
    logger.error("Fehler beim Erstellen der Tabellen: %s", e)


# -----------------------------------------------------------------------------
# Main Entrypoint
# -----------------------------------------------------------------------------
if __name__ == '__main__':
    app.run(debug=False)

