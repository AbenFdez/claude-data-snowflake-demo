# Guion de la demo · Claude Data sobre Conservas Ardora

Duración orientativa: **6-8 minutos**. Los prompts están pensados para que aparezcan los hallazgos que esconden los datos (ver el [README](../README.md#la-historia-que-esconden-los-datos)).

## Antes de grabar

- [ ] Ejecuta `sql/01_crear_demo.sql` **el día antes** para que los datos lleguen hasta ayer.
- [ ] Revisa el apartado 8 del script y confirma que Sur cae e Internacional crece.
- [ ] Comprueba que la conexión de Snowflake en Claude usa el rol `CLAUDE_DATA_LECTOR` (o, en el plan B, ten a mano los dos CSV).
- [ ] Ten **un panel ya creado** como plan B, por si falla la conexión en directo.
- [ ] Cierra pestañas y notificaciones.

> **Plan B, sin servidor MCP (cuenta de prueba de Snowflake):** antes de cada pregunta, adjunta en el chat `data/ventas_detalle.csv` y `data/clientes.csv`, o tus propias exportaciones (ver el README). Las preguntas son las mismas.

## 1. Una pregunta, un panel (≈ 2 min)

> Construye un panel con los ingresos de Conservas Ardora en lo que va de trimestre por región y compáralos con el mismo periodo del trimestre anterior.

**Qué contar:** Claude explora el esquema, escribe el SQL, lo ejecuta y monta el panel. Nadie ha tenido que abrir una herramienta de BI.

**Qué debería salir:** casi todas las regiones crecen, **Sur cae** e **Internacional** es la que más crece.

> ⚠ Pide la comparación «en lo que va de trimestre» frente al «mismo periodo». Si comparas un trimestre a medias con el anterior completo, todo sale a la baja.

## 2. Ajustar sin empezar de cero (≈ 1 min)

> Añade un filtro por segmento de cliente.

**Qué contar:** el panel se refina conversando, y al filtrar por *Gran cuenta* la caída de Sur se hace evidente.

## 3. Preguntar el porqué (≈ 1,5 min)

> ¿Por qué caen los ingresos en Sur? Desglósalo por cliente.

**Qué debería salir:** *Supermercados Hispalis* (Sevilla) compraba mucho y ha dejado de hacerlo.

> ¿Qué está impulsando el crecimiento de Internacional?

**Qué debería salir:** los pedidos por el canal *Distribuidor* (importadores) en Portugal, Francia, Reino Unido y México.

## 4. Transparencia y confianza (≈ 1,5 min)

1. Haz clic en una cifra o un gráfico y **abre su consulta**. Pide: *«Explícame esta consulta»*.
2. Señala el filtro `ESTADO = 'Completado'` y explica que, sin él, los ingresos salen inflados por devoluciones y cancelaciones (≈ 8 %).
3. **Certifica la consulta**: activa *Certificar consulta*, pega las instrucciones de la consulta C1 de `sql/02_consultas_certificadas.sql`, pulsa *Probar* y después *Publicar*. Enseña la insignia.

## 5. Otra pregunta de negocio (≈ 1 min)

> ¿Cómo se comparan las altas de clientes de este mes por canal con las del mes pasado?

**Qué debería salir:** un pico de altas por el canal **Feria**.

## 6. Compartir (≈ 30 s)

Enseña **Compartir**. Recuerda que cada persona ve los datos con sus propios permisos: si alguien no tiene acceso a la fuente, esa parte del panel le muestra un error en lugar de los datos.

## Mensajes clave para cerrar

- De la pregunta al panel en minutos, sin escribir SQL.
- Cada cifra muestra su consulta: se puede revisar y certificar.
- Es para explorar rápido; para análisis profundos se sigue en la herramienta de BI.
