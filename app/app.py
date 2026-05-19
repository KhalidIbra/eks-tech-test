from flask import Flask
import mysql.connector
import os

app = Flask(__name__)

@app.route('/')
def hello_world():
    return '<h1>Hello, World!</h1>', 200

@app.route('/health')
def health_check():
    return {"status": "OK"}, 200

@app.route('/db')
def db_check():
    try:
        connection = mysql.connector.connect(
            host=os.environ["DB_HOST"],
            user=os.environ["DB_USER"],
            password=os.environ["DB_PASSWORD"],
            database=os.environ["DB_NAME"]
        )
        return {"status": "Database connection successful"}, 200
    except mysql.connector.Error as err:
        return {"status": "Database connection failed", "error": str(err)}, 500
    
if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8080)