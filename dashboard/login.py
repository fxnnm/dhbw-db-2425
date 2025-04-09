from flask import render_template, request, redirect, url_for, session
from helpers import get_mysql_connection

def register_login_routes(app):
    @app.route('/login', methods=['GET', 'POST'])
    def login():
        error = None
        if request.method == 'POST':
            username = request.form['username']
            password = request.form['password']

            conn = get_mysql_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT rolle FROM benutzer WHERE username = %s AND password = %s", (username, password))
            result = cursor.fetchone()
            cursor.close()
            conn.close()

            if result:
                session['username'] = username
                session['rolle'] = result[0]
                return redirect(url_for('dashboard'))
            else:
                error = "Falscher Benutzername oder Passwort"

        return render_template('login.html', error=error)
