from flask import Flask
import mysql.connector
import os

app = Flask(__name__)

@app.route('/')
def hello_world():
    return '<h1>Hello, World v2.0!</h1>', 200

@app.route('/health')
def health_check():
    return {"status": "OK"}, 200

@app.route("/db")
def db_check():
    try:
        with mysql.connector.connect(
            host=os.environ["DB_HOST"],
            port=int(os.environ.get("DB_PORT", "3306")),
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            database=os.environ["DB_NAME"],
            connection_timeout=3,
        ) as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
                cur.fetchone()
        return {"db": "ok"}, 200
    except Exception as e:
        return {"db": "error", "detail": str(e)}, 500
    
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)