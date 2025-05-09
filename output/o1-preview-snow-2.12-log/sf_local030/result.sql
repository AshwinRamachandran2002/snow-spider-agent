SELECT
  AVG(sub.total_payment) AS "average_total_payments",
  AVG(sub.delivered_order_count) AS "average_total_order_counts"
FROM (
  SELECT
    c."customer_city",
    SUM(p."payment_value") AS total_payment,
    COUNT(DISTINCT o."order_id") AS delivered_order_count
  FROM
    "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDERS" o
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_CUSTOMERS" c
      ON o."customer_id" = c."customer_id"
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_ORDER_PAYMENTS" p
      ON o."order_id" = p."order_id"
  WHERE
    o."order_status" = 'delivered'
  GROUP BY
    c."customer_city"
  ORDER BY
    total_payment ASC
  LIMIT 5
) sub;