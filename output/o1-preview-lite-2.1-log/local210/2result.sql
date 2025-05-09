WITH monthly_counts AS (
    SELECT
        "hubs"."hub_id",
        "hubs"."hub_name",
        "orders"."order_created_month" AS "month",
        COUNT("orders"."order_id") AS "finished_orders"
    FROM "orders"
    JOIN "stores" ON "orders"."store_id" = "stores"."store_id"
    JOIN "hubs" ON "stores"."hub_id" = "hubs"."hub_id"
    WHERE
        "orders"."order_status" = 'FINISHED'
        AND "orders"."order_created_month" IN (2, 3)
        AND "orders"."order_created_year" = 2021
    GROUP BY
        "hubs"."hub_id",
        "hubs"."hub_name",
        "orders"."order_created_month"
),
pivot_counts AS (
    SELECT
        "hub_id",
        "hub_name",
        SUM(CASE WHEN "month" = 2 THEN "finished_orders" ELSE 0 END) AS "feb_orders",
        SUM(CASE WHEN "month" = 3 THEN "finished_orders" ELSE 0 END) AS "mar_orders"
    FROM
        monthly_counts
    GROUP BY
        "hub_id",
        "hub_name"
)
SELECT
    "hub_id",
    "hub_name"
FROM
    pivot_counts
WHERE
    "feb_orders" > 0
    AND ("mar_orders" - "feb_orders") * 1.0 / "feb_orders" > 0.2;