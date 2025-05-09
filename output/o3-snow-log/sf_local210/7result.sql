WITH "monthly_counts" AS (
    SELECT
        h."hub_id",
        h."hub_name",
        o."order_created_year"        AS "year",
        o."order_created_month"       AS "month",
        COUNT(*)                      AS "finished_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS   o
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES   s ON o."store_id" = s."store_id"
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.HUBS     h ON s."hub_id"   = h."hub_id"
    WHERE o."order_status" = 'FINISHED'
      AND o."order_created_month" IN (2,3)        -- February & March
    GROUP BY
        h."hub_id",
        h."hub_name",
        o."order_created_year",
        o."order_created_month"
),
"feb_mar" AS (
    SELECT
        "hub_id",
        "hub_name",
        "year",
        SUM(CASE WHEN "month" = 2 THEN "finished_orders" ELSE 0 END) AS "feb_orders",
        SUM(CASE WHEN "month" = 3 THEN "finished_orders" ELSE 0 END) AS "mar_orders"
    FROM "monthly_counts"
    GROUP BY
        "hub_id",
        "hub_name",
        "year"
)
SELECT
    "hub_id",
    "hub_name",
    "year",
    "feb_orders",
    "mar_orders",
    ROUND( ( "mar_orders" - "feb_orders" ) / "feb_orders", 4 ) AS "pct_increase"
FROM "feb_mar"
WHERE "feb_orders" > 0
  AND ( "mar_orders" - "feb_orders" ) / "feb_orders" > 0.20      -- > 20% increase
ORDER BY "pct_increase" DESC NULLS LAST;