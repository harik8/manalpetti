import os
import logging
from flask import Flask, abort
import psycopg2

logging.basicConfig(level=logging.INFO)
app = Flask(__name__)

conn = psycopg2.connect(os.environ["CNPG_URI"])
logging.info("DB connection is established")


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