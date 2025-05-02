import pymysql
from pymongo import MongoClient
import os
from dotenv import load_dotenv

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

def log_conversion(table, count):
    with mysql_conn.cursor() as cursor:
        cursor.execute(
            "INSERT INTO konvertierung_log (tabelle, anzahl) VALUES (%s, %s)",
            (table, count)
        )
        mysql_conn.commit()

def convert_flat(table_name):
    with mysql_conn.cursor() as cursor:
        cursor.execute(f"SELECT * FROM {table_name}")
        rows = cursor.fetchall()
        if rows:
            mongo_db[table_name].delete_many({})
            mongo_db[table_name].insert_many(rows)
            print(f"[FLAT] {len(rows)} records -> '{table_name}'")
            log_conversion(table_name, len(rows))

def convert_embedded_fahrt():
    mongo_db["fahrt_embedded"].delete_many({})
    fahrten = list(mongo_db["fahrt"].find())

    for fahrt in fahrten:
        fahrer = mongo_db["fahrer"].find_one({"id": fahrt["fahrerid"]})
        fahrzeug = mongo_db["fahrzeug"].find_one({"id": fahrt["fahrzeugid"]})
        fahrzeugparameter = list(mongo_db["fahrzeugparameter"].find({"fahrtid": fahrt["id"]}))
        beschleunigungen = list(mongo_db["beschleunigung"].find({"fahrtid": fahrt["id"]}))
        diagnosen = list(mongo_db["diagnose"].find({"fahrtid": fahrt["id"]}))

        fahrt["fahrer"] = fahrer
        fahrt["fahrzeug"] = fahrzeug
        fahrt["fahrzeugparameter"] = fahrzeugparameter
        fahrt["beschleunigung"] = beschleunigungen
        fahrt["diagnose"] = diagnosen

        fahrt.pop("fahrerid", None)
        fahrt.pop("fahrzeugid", None)

        mongo_db["fahrt_embedded"].insert_one(fahrt)

    print(f"[EMBEDDED] {len(fahrten)} -> 'fahrt_embedded'")
    log_conversion("fahrt_embedded", len(fahrten))

def convert_embedded_geraet():
    mongo_db["geraet_embedded"].delete_many({})
    geraete = list(mongo_db["geraet"].find())

    for geraet in geraete:
        installationen = list(mongo_db["geraet_installation"].find({"geraetid": geraet["id"]}))
        wartungen = list(mongo_db["wartung"].find({"geraetid": geraet["id"]}))
        geraet["installationen"] = installationen
        geraet["wartung"] = wartungen
        mongo_db["geraet_embedded"].insert_one(geraet)

    print(f"[EMBEDDED] {len(geraete)} -> 'geraet_embedded'")
    log_conversion("geraet_embedded", len(geraete))

def convert_embedded_fahrzeug():
    mongo_db["fahrzeug_embedded"].delete_many({})
    fahrzeuge = list(mongo_db["fahrzeug"].find())

    for fahrzeug in fahrzeuge:
        wartungen = list(mongo_db["wartung"].find({"fahrzeugid": fahrzeug["id"]}))
        fahrzeug["wartung"] = wartungen
        mongo_db["fahrzeug_embedded"].insert_one(fahrzeug)

    print(f"[EMBEDDED] {len(fahrzeuge)} -> 'fahrzeug_embedded'")
    log_conversion("fahrzeug_embedded", len(fahrzeuge))

def main():
    flat_tables = [
        "fahrer", "fahrzeug", "fahrt", "geraet", "geraet_installation",
        "fahrzeugparameter", "beschleunigung", "diagnose", "wartung"
    ]
    for table in flat_tables:
        convert_flat(table)

    convert_embedded_fahrt()
    convert_embedded_geraet()
    convert_embedded_fahrzeug()

if __name__ == "__main__":
    main()
