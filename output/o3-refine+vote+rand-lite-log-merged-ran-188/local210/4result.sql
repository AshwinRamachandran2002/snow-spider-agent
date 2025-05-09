WITH finished_orders AS (
    SELECT 
        o."order_id",
        s."hub_id",
        h."hub_name",
        o."order_created_month" AS month
    FROM "orders" AS o
    JOIN "stores"  AS s ON o."store_id" = s."store_id"
    JOIN "hubs"    AS h ON s."hub_id" = h."hub_id"
    WHERE 
        o."order_status" = 'FINISHED'
        AND o."order_created_month" IN (2, 3)          -- February and March
),
monthly_counts AS (
    SELECT
        hub_id,
        hub_name,
        month,
        COUNT(*) AS cnt
    FROM finished_orders
    GROUP BY hub_id, hub_name, month
),
pivot AS (
    SELECT
        hub_id,
        hub_name,
        SUM(CASE WHEN month = 2 THEN cnt ELSE 0 END) AS feb_count,
        SUM(CASE WHEN month = 3 THEN cnt ELSE 0 END) AS mar_count
    FROM monthly_counts
    GROUP BY hub_id, hub_name
)
SELECT
    hub_id,
    hub_name
FROM pivot
WHERE 
    feb_count > 0                     -- avoid division by zero
    AND mar_count > feb_count * 1.20; -- more than 20% increase