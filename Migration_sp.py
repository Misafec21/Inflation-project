import pymysql
from pymongo import MongoClient
from datetime import datetime
from decimal import Decimal
from config import MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DB, MONGO_URI, MONGO_DB


# List of citizen-facing stored procedures to execute and migrate.
SPS_CIUDADANOS = [
    "sp_get_termometro_inflacion",
    "sp_get_poder_adquisitivo_udis",
    "sp_get_consejo_financiero",
    "sp_get_peso_frente_al_dolar",
    "sp_get_mes_mas_caro",
    "sp_get_alerta_volatilidad",
]

def convertir_fila(fila):
    convertida = {}
    for clave, valor in fila.items():
        if isinstance(valor, Decimal):
            convertida[clave] = float(valor)
        elif isinstance(valor, datetime):
            convertida[clave] = valor
        else:
            convertida[clave] = valor
    return convertida

# MAIN PIPELINE EXECUTION
def main():
    mysql_conn = pymysql.connect(
        host=MYSQL_HOST, port=MYSQL_PORT,
        user=MYSQL_USER, password=MYSQL_PASSWORD,
        database=MYSQL_DB, charset="utf8mb4"
    )
    mongo_db = MongoClient(MONGO_URI)[MONGO_DB]

    for sp in SPS_CIUDADANOS:
        with mysql_conn.cursor(pymysql.cursors.DictCursor) as cursor:
            cursor.callproc(sp)
            filas = [convertir_fila(f) for f in cursor.fetchall()]

        mongo_db[sp].drop()
        if filas:
            mongo_db[sp].insert_many(filas)
        print(f"  OK: {sp} -> {len(filas)} documentos")

    mysql_conn.close()

if __name__ == "__main__":
    main()