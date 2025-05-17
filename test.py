import pymysql
conn = pymysql.connect(
    host="localtest",
    port=3306,
    user="root",
    password="example",
    database="mydb"
)
print("✅ Verbindung erfolgreich!")
