import sys
from datetime import datetime, date, timedelta
from decimal import Decimal

import pymysql
from pymongo import MongoClient

from config import (
    MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DB,
    MONGO_URI, MONGO_DB,
)


def convertir_fila(fila):
    """Converts MySQL data types to MongoDB-compatible formats (Decimal->float, date->datetime)."""
    convertida = {}
    for clave, valor in fila.items():
        if isinstance(valor, Decimal):
            convertida[clave] = float(valor)
        elif isinstance(valor, datetime):
            convertida[clave] = valor
        elif isinstance(valor, date):
            convertida[clave] = datetime.combine(valor, datetime.min.time())
        elif isinstance(valor, timedelta):
            convertida[clave] = str(valor)
        else:
            convertida[clave] = valor
    return convertida


# DATABASE INITIALIZATION AND VALIDATION CONNECTIONS

def conectar_mysql():
    """Initializes and returns a connection to MySQL, validating that the target schema exists."""
    conn = pymysql.connect(
        host=MYSQL_HOST, port=MYSQL_PORT,
        user=MYSQL_USER, password=MYSQL_PASSWORD,
        charset="utf8mb4",
    )
    with conn.cursor() as c:
        c.execute("SHOW DATABASES")
        bases = [r[0] for r in c.fetchall()]
        if MYSQL_DB not in bases:
            print(f"  ERROR: MySQL database '{MYSQL_DB}' does not exist.")
            sys.exit(1)
    conn.select_db(MYSQL_DB)
    return conn


def conectar_mongo():
    """Connects to MongoDB, dropping any previous collections to guarantee a fresh synchronization sync."""
    client = MongoClient(MONGO_URI)
    if MONGO_DB not in client.list_database_names():
        print(f"  MongoDB '{MONGO_DB}' does not exist. Creating it now.")
        client[MONGO_DB]["_init"].insert_one({"created": datetime.now()})
        client[MONGO_DB]["_init"].drop()
    else:
        print(f"  MongoDB '{MONGO_DB}' already exists. Wiping prior tracking collections...")
        db = client[MONGO_DB]
        for col in db.list_collection_names():
            db[col].drop()
        print(f"  Previous collections successfully dropped.")
    return client


# SYSTEM MIGRATION REPLICATION LAYER

def clonar_tabla(mysql_conn, mongo_db, nombre_tabla):
    """Extracts all matching records from a MySQL table and updates them into a Mongo collection."""
    try:
        with mysql_conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.execute(f"SELECT * FROM `{nombre_tabla}`")
            filas = cursor.fetchall()

            if not filas:
                print(f"     NOTICE: Table '{nombre_tabla}' is currently empty.")
                return

            filas_convertidas = [convertir_fila(f) for f in filas]

            mongo_db[nombre_tabla].drop()
            mongo_db[nombre_tabla].insert_many(filas_convertidas)
            print(f"     OK: Table '{nombre_tabla}' -> Collection '{nombre_tabla}' ({len(filas)} docs)")

    except Exception as e:
        print(f"     ERROR cloning relational structure '{nombre_tabla}': {e}")


# MAIN PIPELINE EXECUTION SUMMARY

def main():
    print("=" * 64)
    print("  MYSQL -> MONGODB MIGRATION PIPELINE (Full Entities Sync)")
    print("=" * 64)

    mysql_conn = conectar_mysql()
    print(f"  Connected to MySQL: {MYSQL_DB}")

    mongo_client = conectar_mongo()
    mongo_db = mongo_client[MONGO_DB]
    print(f"  Connected to MongoDB: {MONGO_DB}\n")

    # Fetch only structural base tables, skipping any SQL view layers
    try:
        with mysql_conn.cursor() as cursor:
            cursor.execute("SHOW FULL TABLES WHERE Table_type = 'BASE TABLE'")
            tablas = [fila[0] for fila in cursor.fetchall()]
    except Exception as e:
        print(f"  ERROR retrieving relational metadata schemas: {e}")
        sys.exit(1)

    print(f"  Target base entities to synchronize: {len(tablas)}\n")

    for tabla in tablas:
        clonar_tabla(mysql_conn, mongo_db, tabla)

    print("\n" + "=" * 64)
    print("  REPLICATION PIPELINE SUCCESSFUL")
    print("=" * 64)

    print("\n  Available MongoDB target collections:")
    for col in sorted(mongo_db.list_collection_names()):
        n = mongo_db[col].count_documents({})
        print(f"    - {col}: {n} documents")

    mysql_conn.close()
    mongo_client.close()


if __name__ == "__main__":
    main()