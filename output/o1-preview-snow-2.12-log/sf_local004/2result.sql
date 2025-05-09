SELECT
  co."customer_id",
  COUNT(DISTINCT co."order_id") AS "number_of_orders",
  ROUND(AVG(co."order_total_payment"), 4) AS "average_payment_per_order",
  CASE
    WHEN DATEDIFF(day, MIN(co."order_purchase_timestamp"), MAX(co."order_purchase_timestamp")) < 7 THEN 1.0
    ELSE ROUND(DATEDIFF(day, MIN(co."order_purchase_timestamp"), MAX(co."order_purchase_timestamp")) / 7.0, 4)
  END AS "customer_lifespan_in_weeks"
FROM (
  SELECT
    o."order_id",
    o."customer_id",
    o."order_purchase_timestamp",
    SUM(p."payment_value") AS "order_total_payment"
  FROM
    "E_COMMERCE"."E_COMMERCE"."ORDERS" o
    JOIN "E_COMMERCE"."E_COMMERCE"."ORDER_PAYMENTS" p
      ON o."order_id" = p."order_id"
  GROUP BY
    o."order_id",
    o."customer_id",
    o."order_purchase_timestamp"
) co
GROUP BY
  co."customer_id"
ORDER BY
  "average_payment_per_order" DESC NULLS LAST
LIMIT 3;