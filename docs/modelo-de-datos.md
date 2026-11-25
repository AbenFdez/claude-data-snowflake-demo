# Modelo de datos · `DEMO_CLAUDE_DATA.VENTAS`

```mermaid
erDiagram
    REGIONES  ||--o{ CLIENTES  : "agrupa"
    REGIONES  ||--o{ OBJETIVOS : "tiene"
    CLIENTES  ||--o{ PEDIDOS   : "realiza"
    PRODUCTOS ||--o{ PEDIDOS   : "aparece en"

    REGIONES {
        number  REGION_ID PK
        varchar REGION
        varchar DIRECTOR_REGIONAL
        varchar AMBITO
    }
    PRODUCTOS {
        number  PRODUCTO_ID PK
        varchar PRODUCTO
        varchar CATEGORIA
        varchar FORMATO_CAJA
        number  PRECIO_CAJA_EUR
        number  COSTE_CAJA_EUR
    }
    CLIENTES {
        number  CLIENTE_ID PK
        varchar NOMBRE_CLIENTE
        number  REGION_ID FK
        varchar CIUDAD
        varchar PAIS
        varchar SEGMENTO
        varchar CANAL_ALTA
        date    FECHA_ALTA
    }
    PEDIDOS {
        number  PEDIDO_ID PK
        date    FECHA_PEDIDO
        number  CLIENTE_ID FK
        number  PRODUCTO_ID FK
        varchar CANAL_VENTA
        number  CAJAS
        number  PRECIO_CAJA_EUR
        number  DESCUENTO_PCT
        number  IMPORTE_BRUTO_EUR
        number  IMPORTE_NETO_EUR
        number  COSTE_EUR
        varchar ESTADO
    }
    OBJETIVOS {
        number  REGION_ID FK
        date    TRIMESTRE_INICIO
        varchar TRIMESTRE
        number  OBJETIVO_INGRESOS_EUR
    }
```

Todas las tablas y columnas llevan comentarios en Snowflake (`COMMENT`). Claude los lee al explorar el esquema, y por eso conviene escribirlos bien.

## Tablas

### `REGIONES` (6 filas)
Mercados comerciales: **Galicia** (mercado local), Centro, Este, Sur, Norte e Internacional (Portugal, Francia, Reino Unido y México).

### `PRODUCTOS` (24 filas)
Conservas vendidas **por caja**. Hay cinco categorías:

| Categoría | Ejemplos |
| --- | --- |
| Moluscos | Mejillones en escabeche, berberechos, zamburiñas, navajas, almejas |
| Cefalópodos | Pulpo en aceite de oliva, calamares en su tinta, chipirones |
| Pescados | Sardinillas, xoubas, bonito del norte, ventresca, atún, caballa |
| Packs y regalo | Pack degustación Rías Baixas, estuche gourmet, lote de Navidad |
| Formato hostelería | Latas de 1 kg de mejillón, pulpo, bonito, berberecho, sardinilla y zamburiña |

### `CLIENTES` (≈ 1.525 filas)

| Columna | Valores |
| --- | --- |
| `SEGMENTO` | Tienda gourmet · Hostelería · Distribuidor · Gran cuenta (cadenas) |
| `CANAL_ALTA` | Web · Comercial directo · Distribuidor · Feria |
| `FECHA_ALTA` | El 60 % son clientes históricos y el 40 % se dio de alta durante el periodo |

### `PEDIDOS` (≈ 55.000-65.000 filas)
Hay una línea por pedido, y **la región del pedido es la del cliente**.

| Regla de negocio | Detalle |
| --- | --- |
| Ingresos | `SUM(IMPORTE_NETO_EUR)` solo con `ESTADO = 'Completado'` |
| Margen | `IMPORTE_NETO_EUR - COSTE_EUR` |
| `ESTADO` | Completado (≈ 92 %) · Devuelto (≈ 5 %) · Cancelado (≈ 3 %) |
| `CANAL_VENTA` | Web · Comercial directo · Distribuidor |

### `OBJETIVOS` (48 filas)
Hay un objetivo de ingresos netos por región y **trimestre completo**: los ingresos del mismo trimestre del año anterior más un 10 %.

### Vista `V_VENTAS_DETALLE`
Junta pedidos, clientes, regiones y productos, y añade `MES`, `TRIMESTRE_INICIO` y `MARGEN_EUR`. Es el punto de partida más cómodo para preguntar en lenguaje natural.
