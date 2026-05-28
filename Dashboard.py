from pymongo import MongoClient
from config import MONGO_URI, MONGO_DB


# Configuration for console reports targeting the MongoDB citizen collections
REPORTES = [
    {
        "coleccion":      "sp_get_termometro_inflacion",
        "titulo":         "Inflation Thermometer (Since 2018)",
        "sort_field":     "period",
        "sort_ascending": True,
        "columns":        ["period", "cpi_index",
                           "accumulated_inflation_since_2018_pct",
                           "price_status"],
    },
    {
        "coleccion":      "sp_get_poder_adquisitivo_udis",
        "titulo":         "Purchasing Power of 10 Pesos (in UDIS)",
        "sort_field":     "period",
        "sort_ascending": True,
        "columns":        ["period", "udi_value",
                           "purchasing_power_10_pesos_coin"],
    },
    {
        "coleccion":      "sp_get_consejo_financiero",
        "titulo":         "Monthly Financial Advice (CETES vs CPI)",
        "sort_field":     "period",
        "sort_ascending": True,
        "columns":        ["period", "cetes_rate_28d_pct",
                           "cpi_index", "advice"],
    },
    {
        "coleccion":      "sp_get_peso_frente_al_dolar",
        "titulo":         "US Cents Purchased with 1 Mexican Peso",
        "sort_field":     "period",
        "sort_ascending": True,
        "columns":        ["period", "pesos_per_dollar",
                           "us_cents_per_one_peso"],
    },
    {
        "coleccion":      "sp_get_mes_mas_caro",
        "titulo":         "Historically Most Expensive Month (CPI Average)",
        "sort_field":     "historical_cpi_average",
        "sort_ascending": False,
        "columns":        ["month_number", "month_name",
                           "historical_cpi_average", "years_averaged"],
    },
    {
        "coleccion":      "sp_get_alerta_volatilidad",
        "titulo":         "Inflation Origin (Headline vs Core CPI)",
        "sort_field":     "period",
        "sort_ascending": True,
        "columns":        ["period", "headline_cpi", "core_cpi",
                           "difference_headline_minus_core",
                           "inflation_origin"],
    },
]


def imprimir_tabla(titulo, documentos, columnas, max_filas=15):
    """Prints a list of dictionaries as a structured console table with dynamic padding."""
    print(f"\n--- {titulo} ---")
    if not documentos:
        print("  (no data found)")
        return

    # Calculate dynamic columns width allocations
    anchos = {}
    for col in columnas:
        max_dato = max(
            (len(_formatear(doc.get(col))) for doc in documentos[:max_filas]),
            default=0,
        )
        anchos[col] = max(len(col), max_dato, 14)

    # Print Table Header
    print("  " + " | ".join(f"{col:<{anchos[col]}}" for col in columnas))
    print("  " + "-+-".join("-" * anchos[col] for col in columnas))

    # Print Rows
    for doc in documentos[:max_filas]:
        valores = []
        for col in columnas:
            valores.append(f"{_formatear(doc.get(col)):<{anchos[col]}}")
        print("  " + " | ".join(valores))

    if len(documentos) > max_filas:
        print(f"  ... ({len(documentos) - max_filas} more rows)")


def _formatear(valor):
    """Formats values for clean shell printing: limits floats to 4 decimals."""
    if valor is None:
        return ""
    if isinstance(valor, float):
        return f"{valor:.4f}"
    return str(valor)


# MAIN ORCHESTRATION LAYER

def main():
    print("=" * 64)
    print("  CITIZEN DASHBOARD - MONGODB REPORTS SYSTEM")
    print("=" * 64)

    client = MongoClient(MONGO_URI)
    if MONGO_DB not in client.list_database_names():
        print(f"  ERROR: MongoDB database '{MONGO_DB}' does not exist.")
        print("  Please run the pipeline migration scripts first.")
        return

    db = client[MONGO_DB]
    colecciones_existentes = set(db.list_collection_names())

    for reporte in REPORTES:
        col = reporte["coleccion"]
        if col not in colecciones_existentes:
            print(f"\n--- {reporte['titulo']} ---")
            print(f"  NOTICE: Target collection '{col}' does not exist yet.")
            continue

        # Fetch, sort, and display collection data
        docs = list(
            db[col].find().sort(
                reporte["sort_field"],
                1 if reporte["sort_ascending"] else -1,
            )
        )
        imprimir_tabla(reporte["titulo"], docs, reporte["columns"])

    print("\n" + "=" * 64)
    print("  END OF DASHBOARD SUMMARY REPORT")
    print("=" * 64)

    client.close()


if __name__ == "__main__":
    main()