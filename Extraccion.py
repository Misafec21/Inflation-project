import requests
import csv
from datetime import datetime
from config import (
    BANXICO_TOKEN, BANXICO_URL, FECHA_INICIO, FECHA_FIN, SERIES_BANXICO
)


def consultar_serie(id_serie, fecha_inicio=FECHA_INICIO, fecha_fin=FECHA_FIN):
    """Queries a series from the Banxico API and returns the data list."""
    url = f"{BANXICO_URL}/{id_serie}/datos/{fecha_inicio}/{fecha_fin}"
    headers = {"Bmx-Token": BANXICO_TOKEN, "Accept": "application/json"}
    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        data = response.json()
        return data["bmx"]["series"][0].get("datos", [])
    except Exception as e:
        print(f"  Error in {id_serie}: {e}")
        return []


def parsear_fecha(fecha_str):
    """Converts dates from 'dd/mm/yyyy' format to 'yyyy-mm-dd'."""
    return datetime.strptime(fecha_str, "%d/%m/%Y").strftime("%Y-%m-%d")


def descargar_todas():
    """Downloads all series configured in config.py."""
    resultados = {}
    print(f"\n  Downloading {len(SERIES_BANXICO)} series from the Banxico API...\n")

    for id_serie, (nombre, categoria) in SERIES_BANXICO.items():
        print(f"  -> {id_serie} ({nombre})...", end=" ")
        datos = consultar_serie(id_serie)
        if datos:
            resultados[id_serie] = {"nombre": nombre, "categoria": categoria, "datos": datos}
            print(f"OK {len(datos)} records")
        else:
            print("no data")

    return resultados


def guardar_csv_general(resultados, archivo="banxico_todas_series.csv"):
    """Saves all series into a single CSV using long format."""
    with open(archivo, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["id_serie", "nombre_serie", "categoria", "fecha", "valor"])
        for id_serie, info in resultados.items():
            for d in info["datos"]:
                writer.writerow([
                    id_serie,
                    info["nombre"],
                    info["categoria"],
                    parsear_fecha(d["fecha"]),
                    d["dato"]
                ])
    print(f"\n  General CSV saved: {archivo}")


def generar_resumen(resultados, archivo="resumen_extraccion.txt"):
    """Generates a text summary with extraction details."""
    with open(archivo, "w", encoding="utf-8") as f:
        f.write("EXTRACTION SUMMARY - BANXICO API\n")
        f.write("=" * 60 + "\n")
        f.write(f"Execution date: {datetime.now()}\n")
        f.write(f"Period covered: {FECHA_INICIO} to {FECHA_FIN}\n\n")
        for id_serie, info in resultados.items():
            f.write(f"\n  {id_serie} - {info['nombre']}\n")
            f.write(f"    Records: {len(info['datos'])}\n")
            if info["datos"]:
                f.write(f"    First data point: {info['datos'][0]['fecha']} = {info['datos'][0]['dato']}\n")
                f.write(f"    Last data point: {info['datos'][-1]['fecha']} = {info['datos'][-1]['dato']}\n")
    print(f"  Summary saved: {archivo}")



if __name__ == "__main__":
    print("=" * 60)
    print("  PHASE E (EXTRACT) - BANXICO API")
    print("=" * 60)

    resultados = descargar_todas()

    if not resultados:
        print("\n  ERROR: Nothing was downloaded. Check your token or connection.")
    else:
        print(f"\n  {len(resultados)} series successfully downloaded")
        guardar_csv_general(resultados)
        generar_resumen(resultados)
        print("\n" + "=" * 60)
        print("  EXTRACTION COMPLETE")
        print("=" * 60)