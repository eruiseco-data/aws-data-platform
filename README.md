### orders
- **Qué es:** un pedido de un cliente.
- **Una fila =** un pedido (~99 mil filas).
- **Llave:** order_id
- **Se relaciona con:** customers (customer_id), order_items, payments y reviews (order_id).
- **Columnas clave:** order_status y 5 fechas (compra, aprobación, entrega a paquetería, entrega al cliente, entrega estimada).
- **Ojo:** las fechas de entrega vienen vacías si el pedido no se entregó.