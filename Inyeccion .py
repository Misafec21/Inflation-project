import sys
import requests
import pandas as pd
import pymysql
from datetime import datetime

from config import (
    MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DB,
    BANXICO_TOKEN, BANXICO_URL, FECHA_INICIO, FECHA_FIN, SERIES_BANXICO,
)


def _detalles_serie(categoria):
    """Returns plausible (unit, frequency) tuple based on the category string."""
    if categoria == "Inflation":
        return ("Index 2018=100", "Monthly")
    elif categoria == "Rates":
        return ("Percentage", "Daily")
    elif categoria == "ExchangeRates":
        return ("Pesos per Unit", "Daily")
    elif categoria == "Indicators":
        return ("Various", "Daily")
    else:
        return ("Various", "Monthly")


# ============================================================================
# STEP 1 - API EXTRACTION AND CLEANING
# ============================================================================

def descargar_serie(id_serie):
    """Downloads a complete economic series from the Banxico API."""
    url = f"{BANXICO_URL}/{id_serie}/datos/{FECHA_INICIO}/{FECHA_FIN}"
    headers = {"Bmx-Token": BANXICO_TOKEN, "Accept": "application/json"}

    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()
        return data["bmx"]["series"][0].get("datos", [])
    except Exception:
        print(f"  ⚠️ Error downloading series {id_serie}, skipping... (Banxico API might be down)")
        return []


def limpiar_y_agregar_mensual(datos_crudos):
    """Transforms raw API data into a clean, monthly-aggregated DataFrame (mean value)."""
    if not datos_crudos:
        return pd.DataFrame()

    df = pd.DataFrame(datos_crudos)
    df.columns = [c.strip() for c in df.columns]

    # Process timestamps and remove invalid rows
    df["fecha"] = pd.to_datetime(df["fecha"], format="%d/%m/%Y", errors="coerce")
    df.dropna(subset=["fecha"], inplace=True)

    # Cast data values to numeric and impute missing gaps
    df["dato"] = df["dato"].astype(str).str.replace(",", "", regex=False).str.strip()
    df["dato"] = pd.to_numeric(df["dato"], errors="coerce")
    df.drop_duplicates(subset=["fecha"], keep="last", inplace=True)
    df.sort_values("fecha", inplace=True)
    df["dato"] = df["dato"].ffill().bfill()
    df.dropna(subset=["dato"], inplace=True)

    # Monthly aggregation using the first day of each month
    df["mes"] = df["fecha"].dt.to_period("M").dt.to_timestamp()
    mensual = df.groupby("mes", as_index=False)["dato"].mean()
    mensual.rename(columns={"mes": "fecha", "dato": "valor"}, inplace=True)
    return mensual


def descargar_todas_las_series():
    """Iterates over all configured series, downloads, and processes them."""
    datos = {}
    for id_serie, (nombre, _categoria) in SERIES_BANXICO.items():
        print(f"   -> {id_serie} ({nombre})...", end=" ")
        try:
            crudos = descargar_serie(id_serie)
            mensual = limpiar_y_agregar_mensual(crudos)
            datos[id_serie] = mensual
            print(f"OK ({len(mensual)} months)")
        except Exception as e:
            datos[id_serie] = pd.DataFrame()
            print(f"FAILED ({e})")
    return datos


# ============================================================================
# STEP 2 - AUTO-SEEDING DIMENSIONS
# ============================================================================

def preparar_base_de_datos(conn, datos_descargados):
    """Idempotent function that inserts dimension catalogs before importing facts."""
    with conn.cursor() as cursor:

        # 2.1 Seed banxico_series dimensions catalog
        filas_series = []
        for sid, (nombre, categoria) in SERIES_BANXICO.items():
            unit, frequency = _detalles_serie(categoria)
            filas_series.append((sid, nombre, unit, frequency, categoria))

        cursor.executemany(
            "INSERT IGNORE INTO banxico_series "
            "(series_id, name, unit, frequency, category) "
            "VALUES (%s, %s, %s, %s, %s)",
            filas_series,
        )
        series_insertadas = cursor.rowcount
        print(f"   - banxico_series: {series_insertadas} new / "
              f"{len(filas_series) - series_insertadas} already existed")

        # 2.2 Seed period dimension catalog from unique downloaded dates
        fechas_set = set()
        for df in datos_descargados.values():
            if not df.empty:
                fechas_set.update(df["fecha"].dt.date.tolist())

        cursor.execute("SELECT period_date FROM period")
        existentes = {row[0] for row in cursor.fetchall()}

        # Filter out missing dates to compute attributes dynamically
        faltantes = sorted(fechas_set - existentes)
        filas_periodos = []
        for fecha in faltantes:
            year = fecha.year
            month = fecha.month
            quarter = (month - 1) // 3 + 1
            label = f"{year}-{month:02d}"
            filas_periodos.append((fecha, year, month, quarter, label))

        if filas_periodos:
            cursor.executemany(
                "INSERT IGNORE INTO period "
                "(period_date, year, month, quarter, label) "
                "VALUES (%s, %s, %s, %s, %s)",
                filas_periodos,
            )

        print(f"   - period: {len(filas_periodos)} new / "
              f"{len(existentes)} already existed "
              f"(Total unique dates: {len(fechas_set)})")

    conn.commit()


# ============================================================================
# STEP 3 - DATA LOADING VIA STORED PROCEDURES
# ============================================================================

def conectar_mysql():
    """Initializes and returns a MySQL database connection instance."""
    return pymysql.connect(
        host=MYSQL_HOST,
        port=MYSQL_PORT,
        user=MYSQL_USER,
        password=MYSQL_PASSWORD,
        database=MYSQL_DB,
        autocommit=False,
        charset="utf8mb4",
    )


def obtener_period_id(cursor, fecha):
    """Calls sp_get_period_id_by_date and extracts the primary key identifier output."""
    cursor.callproc("sp_get_period_id_by_date", (fecha.strftime("%Y-%m-%d"),))
    fila = cursor.fetchone()
    return fila[0] if fila else None


def iniciar_auditoria_carga(cursor, id_serie):
    """Calls sp_start_api_load to create a tracking audit batch identifier."""
    cursor.callproc("sp_start_api_load", (id_serie, FECHA_INICIO, FECHA_FIN, 0))
    cursor.execute("SELECT @_sp_start_api_load_3")
    return cursor.fetchone()[0]


def cerrar_auditoria_carga(cursor, load_id, recibidos, insertados, fallidos, status, error_msg):
    """Calls sp_finish_api_load to close the batch load job track metrics."""
    cursor.callproc(
        "sp_finish_api_load",
        (load_id, recibidos, insertados, fallidos, status, error_msg),
    )


def upsert_observacion(cursor, period_id, series_id, valor):
    """Executes the custom database upsert operation with validation routines."""
    cursor.callproc("sp_upsert_observation", (period_id, series_id, float(valor)))


def cargar_observaciones_serie(conn, id_serie, df_mensual):
    """Iterates through rows uploading factual series data using Stored Procedures."""
    print(f"\n   -> {id_serie}")

    cursor = conn.cursor()
    load_id = None
    recibidos = len(df_mensual)
    insertados = fallidos = 0
    status = "RUNNING"
    error_msg = None

    try:
        load_id = iniciar_auditoria_carga(cursor, id_serie)
        conn.commit()

        if df_mensual.empty:
            status = "EMPTY"
            error_msg = "No downloaded data found"
            cerrar_auditoria_carga(cursor, load_id, 0, 0, 0, status, error_msg)
            conn.commit()
            print(f"      No data available (status=EMPTY)")
            return

        # Row-by-row procedural load execution block
        for _, fila in df_mensual.iterrows():
            try:
                period_id = obtener_period_id(cursor, fila["fecha"])
                if period_id is None:
                    fallidos += 1
                    continue
                upsert_observacion(cursor, period_id, id_serie, fila["valor"])
                insertados += 1
            except Exception:
                fallidos += 1

        status = "OK" if fallidos == 0 else "PARTIAL"

    except Exception as e:
        status = "ERROR"
        error_msg = str(e)[:500]
        print(f"      DATABASE ERROR: {error_msg}")
        conn.rollback()

    finally:
        if load_id is not None:
            try:
                cerrar_auditoria_carga(
                    cursor, load_id, recibidos, insertados, fallidos, status, error_msg
                )
                conn.commit()
            except Exception:
                conn.rollback()
        cursor.close()

    print(f"      status={status} | inserted={insertados} | failed={fallidos}")


# ============================================================================
# ORCHESTRATION PIPELINE CONTROL LAYER
# ============================================================================

def main():
    print("=" * 64)
    print("  AUTONOMOUS ETL PIPELINE: BANXICO API -> MYSQL (via SPs)")
    print("=" * 64)
    print(f"  Execution timestamp: {datetime.now()}")
    print(f"  Configured series:   {len(SERIES_BANXICO)}")
    print(f"  Target timeline:     {FECHA_INICIO} to {FECHA_FIN}")

    try:
        conn = conectar_mysql()
        print(f"  Connected to MySQL: {MYSQL_DB} @ {MYSQL_HOST}")
    except Exception as e:
        print(f"\n  MySQL Connection Error: {e}")
        sys.exit(1)

    try:
        print("\n[1/3] Downloading target series from Banxico API...")
        datos = descargar_todas_las_series()
        series_con_datos = sum(1 for df in datos.values() if not df.empty)
        if series_con_datos == 0:
            print("\n  FATAL ERROR: No series returned data records.")
            sys.exit(1)
        print(f"   Summary: {series_con_datos}/{len(datos)} series fetched correctly.")

        print("\n[2/3] Preparing targeted relational schemas (auto-seeding)...")
        preparar_base_de_datos(conn, datos)

        print("\n[3/3] Feeding factual observations via Stored Procedures...")
        for id_serie in SERIES_BANXICO.keys():
            df_mensual = datos.get(id_serie, pd.DataFrame())
            cargar_observaciones_serie(conn, id_serie, df_mensual)

        # Pull immediate metrics summary from audit logs
        with conn.cursor() as c:
            c.execute("""
                SELECT
                    COALESCE(SUM(records_inserted), 0),
                    COALESCE(SUM(records_failed),   0)
                FROM api_load_audit
                WHERE DATE(started_at) = CURDATE()
            """)
            ins, fall = c.fetchone()

        print("\n" + "=" * 64)
        print("  ETL DATA PIPELINE EXECUTION COMPLETE")
        print(f"  Total records processed today: {ins}")
        print(f"  Total records failed today:    {fall}")
        print("=" * 64)

    finally:
        conn.close()


if __name__ == "__main__":
    main()