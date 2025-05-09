WITH "monthly_counts" AS (
    SELECT
        s."hub_id",
        o."order_created_year"       AS "year",
        o."order_created_month"      AS "month",
        COUNT(*)                     AS "finished_orders"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS  o
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES  s  ON o."store_id" = s."store_id"
    WHERE o."order_status" = 'FINISHED'
      AND o."order_created_month" IN (2, 3)          -- February and March
    GROUP BY
        s."hub_id",
        o."order_created_year",
        o."order_created_month"
),
"pivoted" AS (
    SELECT
        "hub_id",
        "year",
        SUM(CASE WHEN "month" = 2 THEN "finished_orders" ELSE 0 END) AS "feb_orders",
        SUM(CASE WHEN "month" = 3 THEN "finished_orders" ELSE 0 END) AS "mar_orders"
    FROM "monthly_counts"
    GROUP BY
        "hub_id",
        "year"
),
"growth" AS (
    SELECT
        "hub_id",
        "year",
        "feb_orders",
        "mar_orders",
        ( "mar_orders" - "feb_orders" ) / "feb_orders"  AS "pct_increase"
    FROM "pivoted"
    WHERE "feb_orders" > 0                                -- avoid division by zero
)
SELECT
    h."hub_id",
    h."hub_name",
    g."year",
    g."feb_orders",
    g."mar_orders",
    ROUND(g."pct_increase" * 100, 2)  AS "pct_increase_percent"
FROM "growth" g
JOIN DELIVERY_CENTER.DELIVERY_CENTER.HUBS h
  ON g."hub_id" = h."hub_id"
WHERE g."pct_increase" > 0.20                               -- more than 20% increase
ORDER BY
    "pct_increase_percent" DESC NULLS LAST;