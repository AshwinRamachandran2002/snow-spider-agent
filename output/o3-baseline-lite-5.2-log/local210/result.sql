WITH finished_orders AS (
    SELECT
        h.hub_id,
        h.hub_name,
        o.order_created_month AS month
    FROM orders  AS o
    JOIN stores  AS s ON o.store_id = s.store_id
    JOIN hubs    AS h ON s.hub_id  = h.hub_id
    WHERE o.order_status = 'FINISHED'
      AND o.order_created_month IN (2, 3)          -- February or March
),
monthly_counts AS (
    SELECT
        hub_id,
        hub_name,
        SUM(CASE WHEN month = 2 THEN 1 ELSE 0 END) AS feb_orders,
        SUM(CASE WHEN month = 3 THEN 1 ELSE 0 END) AS mar_orders
    FROM finished_orders
    GROUP BY hub_id, hub_name
),
percentage_change AS (
    SELECT
        hub_id,
        hub_name,
        feb_orders,
        mar_orders,
        CASE
            WHEN feb_orders > 0
            THEN (mar_orders - feb_orders) * 1.0 / feb_orders
            ELSE NULL
        END AS pct_increase
    FROM monthly_counts
)
SELECT
    hub_id,
    hub_name,
    feb_orders,
    mar_orders,
    ROUND(pct_increase * 100, 2) AS percent_increase
FROM percentage_change
WHERE pct_increase > 0.20          -- more than 20 % increase
  AND feb_orders  > 0;             -- avoid division‑by‑zero