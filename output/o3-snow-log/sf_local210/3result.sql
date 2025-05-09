WITH "FINISHED_ORDERS" AS (
    SELECT 
        "store_id",
        "order_created_year",
        "order_created_month"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS
    WHERE "order_status" = 'FINISHED'
      AND "order_created_month" IN (2,3)               -- February & March
), 
"HUB_MONTH_COUNTS" AS (
    SELECT
        h."hub_id",
        h."hub_name",
        o."order_created_year",
        o."order_created_month",
        COUNT(*) AS "finished_orders"
    FROM "FINISHED_ORDERS"  o
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES  s ON o."store_id" = s."store_id"
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.HUBS    h ON s."hub_id"   = h."hub_id"
    GROUP BY 
        h."hub_id",
        h."hub_name",
        o."order_created_year",
        o."order_created_month"
), 
"FEB_MAR_PIVOT" AS (
    SELECT
        "hub_id",
        "hub_name",
        "order_created_year",
        MAX(CASE WHEN "order_created_month" = 2 THEN "finished_orders" END) AS "feb_orders",
        MAX(CASE WHEN "order_created_month" = 3 THEN "finished_orders" END) AS "mar_orders"
    FROM "HUB_MONTH_COUNTS"
    GROUP BY 
        "hub_id",
        "hub_name",
        "order_created_year"
)
SELECT
    "hub_id",
    "hub_name",
    "order_created_year",
    "feb_orders",
    "mar_orders",
    ("mar_orders" - "feb_orders") / "feb_orders" AS "pct_increase"
FROM "FEB_MAR_PIVOT"
WHERE "feb_orders" > 0
  AND "mar_orders" > "feb_orders"
  AND ("mar_orders" - "feb_orders") / "feb_orders" > 0.20      -- > 20% increase
ORDER BY "pct_increase" DESC NULLS LAST;