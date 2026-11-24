## Diccionario de datos

### orders
- **Qué es:** un pedido de un cliente.
- **Una fila =** un pedido (~99 mil filas).
- **Llave:** order_id
- **Se relaciona con:** customers (customer_id), order_items, payments y reviews (order_id).
- **Columnas clave:** order_status y 5 fechas (compra, aprobación, entrega a paquetería, entrega al cliente, entrega estimada).
- **Ojo:** las fechas de entrega vienen vacías si el pedido no se entregó.

### customers
- **Qué es:** la información de la entidad cliente.
- **Una fila =** un cliente *por pedido*, con información parcial de su dirección (~99 mil filas).
- **Llave:** customer_id
- **Se relaciona con:** es master data, por lo cual no necesita información de las otras tablas, pero la consume orders (customer_id).
- **Columnas clave:** customer_unique_id, customer_zip_code_prefix, customer_city, customer_state (es master data, entonces la información que describe al cliente es importante).
- **Ojo:** se genera un nuevo customer_id con cada orden; customer_unique_id representa a la persona real y puede repetirse.

### order_items
- **Qué es:** la información de la orden de un producto en específico (line item).
- **Una fila =** una unidad de un producto dentro de un pedido (~112 mil filas).
- **Llave:** compuesta de order_id y order_item_id.
- **Se relaciona con:** orders, ya que order_items es un grano más bajo de orders, con información más específica de ese nivel; también con products (product_id) y sellers (seller_id).
- **Columnas clave:** product_id, seller_id, shipping_limit_date, price, freight_value.
- **Ojo:** freight_value es el **flete** (costo de envío) de esa línea; price no incluye el flete.

### payments
- **Qué es:** la información de pagos por orden.
- **Una fila =** un evento de pago relacionado con una orden (~104 mil filas).
- **Llave:** compuesta de order_id y payment_sequential.
- **Se relaciona con:** orders, ya que es un evento de pago relacionado al costo total de una orden.
- **Columnas clave:** payment_type, payment_installments, payment_value.
- **Ojo:** un pedido puede tener varios pagos (p. ej. tarjeta + voucher). **Boleto** = ficha bancaria brasileña que se paga en efectivo en banco o tienda (parecido a pagar en OXXO). **Voucher** = vale o cupón de descuento. payment_installments = plazos de ese método (1 = de contado).

### order_reviews
- **Qué es:** la reseña que deja el cliente después de recibir su pedido.
- **Una fila =** una reseña de un pedido (~99 mil filas).
- **Llave:** compuesta de review_id y order_id (el mismo review_id puede aparecer en más de un pedido).
- **Se relaciona con:** orders (order_id).
- **Columnas clave:** review_score (1 a 5), review_comment_title, review_comment_message, review_creation_date, review_answer_timestamp.
- **Ojo:** los comentarios traen saltos de línea, por eso Bronze se carga con multiLine y escape. Título y comentario vacíos son normales.

### products
- **Qué es:** el catálogo de productos.
- **Una fila =** un producto (~33 mil filas).
- **Llave:** product_id
- **Se relaciona con:** order_items (product_id) y product_category_name_translation (product_category_name).
- **Columnas clave:** product_category_name, product_weight_g, product_length_cm, product_height_cm, product_width_cm, product_photos_qty.
- **Ojo:** la fuente escribe `lenght` (typo); en Silver se renombra a `length`. ~610 productos vienen sin categoría.

### sellers
- **Qué es:** los vendedores del marketplace.
- **Una fila =** un vendedor (~3 mil filas).
- **Llave:** seller_id
- **Se relaciona con:** order_items (seller_id).
- **Columnas clave:** seller_zip_code_prefix, seller_city, seller_state.
- **Ojo:** el zip es solo el prefijo de 5 dígitos, se guarda como string.

### geolocation
- **Qué es:** coordenadas GPS por prefijo de código postal.
- **Una fila =** en Bronze, un punto GPS (~1 millón de filas, muchas por zip). En Silver, **un zip** (el grano cambia).
- **Llave:** no tiene en Bronze; en Silver es geolocation_zip_code_prefix.
- **Se relaciona con:** customers y sellers por el prefijo de zip.
- **Columnas clave:** geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state.
- **Ojo:** hay puntos con coordenadas fuera de Brasil (van a cuarentena). La ciudad viene escrita de varias formas ("sao paulo" / "são paulo"); en Silver se toma la más frecuente con MODE().

### product_category_name_translation
- **Qué es:** la traducción de las categorías de portugués a inglés.
- **Una fila =** una categoría (71 filas).
- **Llave:** product_category_name
- **Se relaciona con:** products (product_category_name).
- **Columnas clave:** product_category_name, product_category_name_english.
- **Ojo:** hay categorías de products que no están aquí (13 productos sin traducción).

## Convenciones de nombres
- Prefijo de entidad en las columnas: `order_`, `customer_`, `payment_`, `product_`, `seller_`, `review_`, `geolocation_`.
- Sufijos por tipo: `_id` (llaves), `_timestamp` (fecha y hora), `_date` (solo fecha), `_qty` (cantidades).
- Typos de la fuente se corrigen en Silver (`lenght` → `length`).
- Los códigos postales se guardan como string con el nombre `<entidad>_zip_code_prefix` (para no perder ceros a la izquierda).
- Tablas de cuarentena: `<tabla>_quarantine`, con columna `motivo`.

## Reglas de Silver
- Tipos siempre con `TRY_CAST` (un valor raro queda NULL y va a cuarentena, no truena el notebook).
- Dedupe con `QUALIFY ROW_NUMBER() OVER (PARTITION BY <llave> ORDER BY _ingested_at DESC) = 1`.
- Vista `<tabla>_validated` calcula `motivo` una sola vez: Silver = `motivo IS NULL` (con `EXCEPT (motivo)`), cuarentena = `motivo IS NOT NULL`.
- Motivos en español y con comillas simples.
- Conciliación: Silver + cuarentena = Bronze (en geolocation: `SUM(geolocation_points)` + cuarentena = Bronze).
- Atributos opcionales nulos se quedan en Silver; a cuarentena solo va lo que hace inutilizable la fila.
- Integridad entre tablas en `databricks/silver/integrity_checks` (LEFT ANTI JOIN, huérfanos esperados = 0).

## Decisiones
- **sellers:** un estado inválido se acepta si el zip es válido (se puede recuperar con geolocation).
- **customers:** un estado inválido se acepta si el zip es válido (se puede recuperar con geolocation).
- **order_items:** precio 0 es válido; precio nulo o negativo va a cuarentena.
- **payments:** plazos < 1 y monto ≤ 0 van a cuarentena (1 plazo = de contado).
- **order_reviews:** una respuesta anterior a la creación de la reseña es inválida.
- **products:** los 13 productos sin traducción se quedan en Silver (no se inventan datos). En Gold se usa LEFT JOIN y `COALESCE(inglés, portugués, 'sin_categoria')`.
