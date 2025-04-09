from flask import Flask, render_template, request, redirect, session
import pymysql
from config import MYSQL_CONFIG

app = Flask(__name__)
app.secret_key = 'geheim'

# Simple Benutzerliste aus deiner Tabelle (ersetzt später Login-System)
users = {
    'admin1': {'rolle': 'admin'},
    'dozent1': {'rolle': 'dozent'},
    'student1': {'rolle': 'student'}
}

column_rename = {
    "student_vorname": "Vorname",
    "student_nachname": "Nachname",
    "kurs": "Kurs",
    "note": "Note",
    "datum": "Datum",
    "dozent_vorname": "Dozent-Vorname",
    "dozent_nachname": "Dozent-Nachname",
    "dozent_username": "Dozent",
    "student_username": "Benutzer",
    "kurs_titel": "Kurstitel",
    "pruefung_id": "Prüfungs-ID"
}

def get_db():
    return pymysql.connect(
        host=MYSQL_CONFIG['host'],
        user=MYSQL_CONFIG['user'],
        password=MYSQL_CONFIG['password'],
        database=MYSQL_CONFIG['database'],
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route('/', methods=['GET', 'POST'])
def login():
    error = None

    if request.method == 'POST':
        username = request.form['username']

        db = get_db()
        cursor = db.cursor()
        cursor.execute("SELECT rolle FROM benutzer WHERE username = %s", (username,))
        result = cursor.fetchone()
        db.close()

        if result:
            session['username'] = username
            session['rolle'] = result['rolle']
            return redirect('/dashboard')
        else:
            error = "Unbekannter Benutzer"

    return render_template('login.html', error=error)


# @app.route('/dashboard', methods=['GET', 'POST'])
@app.route('/dashboard', methods=['GET', 'POST'])
def dashboard():
    rolle = session.get('rolle')
    username = session.get('username')

    if not rolle:
        return redirect('/')

    # View-Liste mit Beschreibung
    role_views = {
        "admin": [
        {"name": "adminsicht", "desc": "Vollständige Übersicht", "editable": False},
        {"name": "dozentsicht", "desc": "Prüfungsübersicht pro Dozent", "editable": False},
        {"name": "studentsicht", "desc": "Eigene Prüfungsübersicht", "editable": False},
        {"name": "benutzerohnerollesicht", "desc": "Nur lesender Zugriff auf Benutzer ohne Rolle", "editable": True},
        {"name": "gutenotensicht", "desc": "Nur gute Noten sichtbar", "editable": True},
    ],
        "dozent": [
            {"name": "dozentsicht", "desc": "Sicht: Prüfungsübersicht", "editable": False},
            {"name": "dozentinfosicht", "desc": "Sicht: dozentinfosicht", "editable": False},
            {"name": "topstudentsicht", "desc": "Sicht: topstudentsicht", "editable": False},
            {"name": "kursstatistiksicht", "desc": "Sicht: kursstatistiksicht", "editable": False},
            {"name": "bestestudentsicht", "desc": "Sicht: bestestudentsicht", "editable": False}
        ],
        "student": [
            {"name": "studentsicht", "desc": "Sicht: Eigene Prüfungsübersicht", "editable": False}
        ],
        "dau": []
    }

    available_views = role_views.get(rolle, [])

    # View-Auswahl bei POST (nur für Admin)
    if request.method == 'POST' and rolle == 'admin' or (rolle == 'dozent'):
        selected_view = request.form.get('selected_view')
        # prüfen ob view überhaupt in der Liste verfügbar ist
        if any(v['name'] == selected_view for v in available_views):
            view = selected_view
        else:
            view = 'adminsicht'
    else:
        # Standardansicht je nach Rolle
        if rolle == 'admin':
            view = 'adminsicht'
        elif rolle == 'dozent':
            view = 'dozentsicht'
        elif rolle == 'student':
            view = 'studentsicht'
        elif rolle == 'dau':
            view = 'dauinfosicht'
        else:
            return "Keine gültige Rolle"

    # Daten abrufen
    db = get_db()
    cursor = db.cursor()
    cursor.execute(f"SELECT * FROM {view}")
    daten = cursor.fetchall()
    db.close()

    return render_template('dashboard.html',
        daten=daten,
        rolle=rolle,
        username=username,
        view=view,
        available_views=available_views,
        column_rename=column_rename
    )



@app.route('/logout')
def logout():
    session.clear()
    return redirect('/')

if __name__ == '__main__':
    app.run(debug=True, port=5001)
