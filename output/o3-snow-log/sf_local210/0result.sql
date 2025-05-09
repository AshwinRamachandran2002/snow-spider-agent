WITH "finished_counts" AS (
    SELECT
        S."hub_id",
        SUM(CASE WHEN O."order_created_month" = 2 THEN 1 ELSE 0 END) AS "feb_orders",
        SUM(CASE WHEN O."order_created_month" = 3 THEN 1 ELSE 0 END) AS "mar_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS  O
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES  S
          ON O."store_id" = S."store_id"
    WHERE O."order_status" = 'FINISHED'
      AND O."order_created_year" = 2021           -- adjust if another year is needed
      AND O."order_created_month" IN (2,3)
    GROUP BY S."hub_id"
)

SELECT
    H."hub_id",
    H."hub_name",
    C."feb_orders",
    C."mar_orders",
    ROUND( (C."mar_orders" - C."feb_orders") / C."feb_orders", 4 ) AS "pct_increase"
FROM "finished_counts"  C
JOIN DELIVERY_CENTER.DELIVERY_CENTER.HUBS  H
      ON C."hub_id" = H."hub_id"
WHERE C."feb_orders" > 0
  AND C."mar_orders" > C."feb_orders" * 1.2
ORDER BY "pct_increase" DESC NULLS LAST;