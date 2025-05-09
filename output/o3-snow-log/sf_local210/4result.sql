WITH finished_orders AS (
    SELECT
        "order_id",
        "store_id",
        "order_created_year",
        "order_created_month"
    FROM DELIVERY_CENTER.DELIVERY_CENTER.ORDERS
    WHERE "order_status" = 'FINISHED'
      AND "order_created_month" IN (2, 3)           -- February or March
), orders_with_hub AS (
    SELECT
        fo."order_created_year"  AS "year",
        fo."order_created_month" AS "month",
        s."hub_id"
    FROM finished_orders fo
    JOIN DELIVERY_CENTER.DELIVERY_CENTER.STORES s
      ON fo."store_id" = s."store_id"
    WHERE s."hub_id" IS NOT NULL                     -- only orders linked to a hub
), monthly_counts AS (
    SELECT
        "hub_id",
        "year",
        "month",
        COUNT(*) AS "finished_orders"
    FROM orders_with_hub
    GROUP BY "hub_id", "year", "month"
), feb_mar_pairs AS (
    SELECT
        feb."hub_id",
        feb."year",
        feb."finished_orders" AS "feb_orders",
        mar."finished_orders" AS "mar_orders",
        (mar."finished_orders" - feb."finished_orders")
        / feb."finished_orders"  AS pct_increase
    FROM monthly_counts feb
    JOIN monthly_counts mar
      ON feb."hub_id" = mar."hub_id"
     AND feb."year"   = mar."year"
    WHERE feb."month" = 2                             -- February
      AND mar."month" = 3                             -- March
      AND feb."finished_orders" > 0                   -- avoid division-by-zero
), qualifying_hubs AS (
    SELECT *
    FROM feb_mar_pairs
    WHERE pct_increase > 0.20                         -- > 20 % increase
)
SELECT
    q."hub_id",
    h."hub_name",
    q."year",
    q."feb_orders",
    q."mar_orders",
    ROUND(q.pct_increase * 100, 2) AS "percent_increase"
FROM qualifying_hubs q
JOIN DELIVERY_CENTER.DELIVERY_CENTER.HUBS h
  ON q."hub_id" = h."hub_id"
ORDER BY "percent_increase" DESC NULLS LAST;