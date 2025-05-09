WITH finished_orders AS (
    SELECT
        o."order_id",
        s."hub_id",
        o."order_created_year"  AS "year",
        o."order_created_month" AS "month"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS  o
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES  s
          ON o."store_id" = s."store_id"
    WHERE o."order_status"        = 'FINISHED'
      AND o."order_created_month" IN (2, 3)          -- February and March
),

monthly_counts AS (
    SELECT
        "hub_id",
        "year",
        "month",
        COUNT(*) AS "finished_orders"
    FROM finished_orders
    GROUP BY "hub_id", "year", "month"
),

pivot_counts AS (
    SELECT
        "hub_id",
        "year",
        SUM(CASE WHEN "month" = 2 THEN "finished_orders" ELSE 0 END) AS "feb_orders",
        SUM(CASE WHEN "month" = 3 THEN "finished_orders" ELSE 0 END) AS "mar_orders"
    FROM monthly_counts
    GROUP BY "hub_id", "year"
)

SELECT
    h."hub_id",
    h."hub_name",
    pc."year",
    pc."feb_orders",
    pc."mar_orders",
    ROUND( (pc."mar_orders" - pc."feb_orders") / pc."feb_orders", 4) AS "percent_increase"
FROM pivot_counts pc
JOIN DELIVERY_CENTER.DELIVERY_CENTER.HUBS h
      ON pc."hub_id" = h."hub_id"
WHERE pc."feb_orders" > 0                                   -- avoid division by zero
  AND pc."mar_orders" > pc."feb_orders"                     -- only hubs with growth
  AND (pc."mar_orders" - pc."feb_orders") / pc."feb_orders" > 0.20   -- > 20 % increase
ORDER BY "percent_increase" DESC NULLS LAST;