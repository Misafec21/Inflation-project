

# --- MySQL ------------------------------------------------------------------
MYSQL_HOST     = "localhost"
MYSQL_PORT     = 3306
MYSQL_USER     = "root"
MYSQL_PASSWORD = "Camacho123"          # <-- cambiar segun la maquina
MYSQL_DB       = "mexico_inflation"

# --- MongoDB ----------------------------------------------------------------
MONGO_URI      = "mongodb://localhost:27017/"
MONGO_DB       = "mexico_inflation"


BANXICO_TOKEN  = "a2b76ab8387bf1e7c3c8070df84c894558548efbab676f435813a7249433280e"
BANXICO_URL    = "https://www.banxico.org.mx/SieAPIRest/service/v1/series"

# Rango de fechas que cubre el estudio
FECHA_INICIO   = "2022-01-01"
FECHA_FIN      = "2024-12-31"

# --- Series de Banxico que descargamos --------------------------------------
# Diccionario: id_serie -> (nombre amigable, categoria)
# Estas 12 series DEBEN coincidir con las insertadas en sql/02_seed.sql
SERIES_BANXICO = {
    "SP1":     ("CPI General",              "Inflation"),
    "SP74665": ("CPI Core (subyacente)",    "Inflation"),
    "SF61745": ("Banxico Target Rate",      "Rates"),
    "SF43783": ("TIIE 28 days",             "Rates"),
    "SF43936": ("Cetes 28 days",            "Rates"),
    "SF43718": ("FIX Exchange Rate USD",    "ExchangeRates"),
    "SF46410": ("Euro Exchange Rate",       "ExchangeRates"),
    "SF46406": ("Yen Exchange Rate",        "ExchangeRates"),
    "SF46407": ("Pound Exchange Rate",      "ExchangeRates"),
    "SF60632": ("CAD Exchange Rate",        "ExchangeRates"),
    "SP68257": ("UDIS Value",               "Indicators"),
    "SF43707": ("International Reserves",   "Indicators"),
}
