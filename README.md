### orders
- **Qué es:** un pedido de un cliente.
- **Una fila =** un pedido (~99 mil filas).
- **Llave:** order_id
- **Se relaciona con:** customers (customer_id), order_items, payments y reviews (order_id).
- **Columnas clave:** order_status y 5 fechas (compra, aprobación, entrega a paquetería, entrega al cliente, entrega estimada).
- **Ojo:** las fechas de entrega vienen vacías si el pedido no se entregó.

### customers
- **Qué es:** la informacion de la entidad cliente.
- **Una fila =** Informacion parcial de direccion del cliente
- **Llave** customer_id
- **Se relaciona con:** Es master data, por lo cual no necesita informacion de las otras tablas, pero puede ser consumida por orders
- **Columnas clave:** customer_unique_id, customer_zip_code_prefix, customer_city, customer_state (Es master data entonces la informacion que describe al cliente es importante)
- **Ojo:** Genera un nuevo customer id con cada orden, para el mismo customer_unique_id que representa a la entidad real

### order items
- **Qué es:** la informacion de orden de un producto en especifico (line item)
- **Una fila =** una unidad de un producto dentro de un pedido
- **Llave** La llave es compuesta de order_id y order_item_id
- **Se relaciona con** Se relaciona con orders, ya que order items es un grano mas bajo de orders, con informacion mas especifica del nivel correspondiente
- **Columnas clave:** product_id, seller_id, shipping_limit_date, price, freight_value
- **Ojo:** No se cual es la traduccion de freight_value amigo claudio

### payments

- **Qué es:** Es la informacion de pagos por orden
- **Una fila =** Un evento de pago relacionado con una orden
- **Llave** La llave es compuesta de order_id y el payment_sequential
- **Se relaciona con** Se relaciona con orders, ya que es un evento de pago relacionado al costo total de una orden
- **Columnas clave:** payment_type, payment installments, payment_value
- **Ojo:** Hay que ver cual es la diferencia entre boleto y voucher, ya que desconozco esos tipos de pago