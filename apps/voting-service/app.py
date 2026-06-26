import os
import logging
from flask import Flask, abort, render_template
import psycopg2

logging.basicConfig(level=logging.INFO)
app = Flask(__name__, template_folder=os.path.join(os.path.dirname(__file__), 'templates'))

conn = psycopg2.connect(os.environ["CNPG_URI"])
logging.info("DB connection is established")


@app.get("/")
def index():
    return render_template("index.html")


@app.get("/ping")
def ping():
    return "pong"


@app.post("/vote/<candidate>")
def vote(candidate):
    with conn.cursor() as cur:
        cur.execute("UPDATE candidates SET votes = votes + 1 WHERE candidate = %s", (candidate,))
        conn.commit()
        if cur.rowcount == 0:
            abort(404)
    return "OK"


@app.get("/result/<candidate>")
def result(candidate):
    with conn.cursor() as cur:
        cur.execute("SELECT votes FROM candidates WHERE candidate = %s", (candidate,))
        row = cur.fetchone()
        if row is None:
            abort(404)
        return str(row[0])


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

'''
    --- DB SCHEMA ---
    CREATE TABLE IF NOT EXISTS voting.candidates (
	    id SERIAL PRIMARY KEY,
	    candidate VARCHAR(10),
	    votes INT DEFAULT 0
	);

	INSERT INTO candidates (candidate) VALUES ('blue');
	INSERT INTO candidates (candidate) VALUES ('green');

    --- CURL COMMANDS ---
    curl -X POST localhost:8080/vote/blue
    curl -X POST localhost:8080/vote/green

    curl -X GET localhost:8080/result/blue
    curl -X GET localhost:8080/result/green
'''