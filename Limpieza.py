
import os
import pandas as pd


def limpiar_csv_general(
    archivo_origen="banxico_todas_series.csv",
    archivo_destino="banxico_todas_series_limpio.csv",
):
    """Limpia el CSV general producido por Extraccion.py."""
    if not os.path.exists(archivo_origen):
        print(f"  No se encontro el archivo: {archivo_origen}")
        print("  Corre primero: python Extraccion.py")
        return

    print(f"  Limpiando {archivo_origen}...")

    # 1. Leer
    df = pd.read_csv(archivo_origen)

    # 2. Quitar espacios en blanco de columnas texto
    for col in ["id_serie", "nombre_serie", "categoria"]:
        if col in df.columns:
            df[col] = df[col].astype(str).str.strip()

    # 3. Normalizar fechas
    df["fecha"] = pd.to_datetime(df["fecha"], errors="coerce")
    df.dropna(subset=["fecha"], inplace=True)

    # 4. Convertir valores a numerico. Texto raro ('N/E') -> NaN
    df["valor"] = df["valor"].astype(str).str.replace(",", "", regex=False).str.strip()
    df["valor"] = pd.to_numeric(df["valor"], errors="coerce")

    # 5. Eliminar duplicados exactos (misma serie, misma fecha)
    filas_antes = len(df)
    df.drop_duplicates(subset=["id_serie", "fecha"], keep="last", inplace=True)
    duplicados = filas_antes - len(df)

    # 6. Ordenar
    df.sort_values(by=["id_serie", "fecha"], inplace=True)

    # 7. Imputacion de nulos: forward fill y backward fill por serie
    faltantes_antes = df["valor"].isna().sum()
    df["valor"] = df.groupby("id_serie")["valor"].ffill()
    df["valor"] = df.groupby("id_serie")["valor"].bfill()
    faltantes_resueltos = faltantes_antes - df["valor"].isna().sum()

    # 8. Guardar
    df.to_csv(archivo_destino, index=False, date_format="%Y-%m-%d")

    print("  Limpieza completada:")
    print(f"    - Duplicados eliminados: {duplicados}")
    print(f"    - Valores nulos imputados: {faltantes_resueltos}")
    print(f"    - Archivo limpio: {archivo_destino}\n")


# ============================================================================
# Punto de entrada del script
# ============================================================================
if __name__ == "__main__":
    print("=" * 60)
    print("  FASE T (TRANSFORM) - LIMPIEZA DE DATOS")
    print("=" * 60)

    limpiar_csv_general()

    print("=" * 60)
    print("  LIMPIEZA FINALIZADA")
    print("=" * 60)
