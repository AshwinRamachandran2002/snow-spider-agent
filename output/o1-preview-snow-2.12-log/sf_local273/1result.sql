WITH events AS (
    SELECT
        inv."product_id",
        pur."purchased" AS "event_date",
        'purchase' AS "event_type",
        inv."qty" AS "quantity"
    FROM
        ORACLE_SQL.ORACLE_SQL.INVENTORY inv
    JOIN
        ORACLE_SQL.ORACLE_SQL.PURCHASES pur ON inv."purchase_id" = pur."id"

    UNION ALL

    SELECT
        ol."product_id",
        ord."ordered" AS "event_date",
        'order' AS "event_type",
        ol."qty" AS "quantity"
    FROM
        ORACLE_SQL.ORACLE_SQL.ORDERLINES ol
    JOIN
        ORACLE_SQL.ORACLE_SQL.ORDERS ord ON ol."order_id" = ord."id"
),
ordered_events AS (
    SELECT
        "product_id",
        "event_date",
        "event_type",
        "quantity"
    FROM events
    ORDER BY "product_id", "event_date", CASE WHEN "event_type" = 'purchase' THEN 1 ELSE 2 END
),
cumulative_sums AS (
    SELECT
        "product_id",
        "event_date",
        "event_type",
        "quantity",
        SUM(CASE WHEN "event_type" = 'purchase' THEN "quantity" ELSE 0 END) OVER (
            PARTITION BY "product_id"
            ORDER BY "event_date", CASE WHEN "event_type" = 'purchase' THEN 1 ELSE 2 END
            ROWS UNBOUNDED PRECEDING
        ) AS "cumulative_purchases",
        SUM(CASE WHEN "event_type" = 'order' THEN "quantity" ELSE 0 END) OVER (
            PARTITION BY "product_id"
            ORDER BY "event_date", CASE WHEN "event_type" = 'purchase' THEN 1 ELSE 2 END
            ROWS UNBOUNDED PRECEDING
        ) AS "cumulative_orders"
    FROM ordered_events
),
calculated AS (
    SELECT
        "product_id",
        "event_date",
        "event_type",
        "quantity",
        "cumulative_purchases",
        "cumulative_orders",
        ("cumulative_purchases" - ("cumulative_orders" - CASE WHEN "event_type" = 'order' THEN "quantity" ELSE 0 END)) AS "available_inventory",
        CASE WHEN "event_type" = 'order' THEN
            LEAST("quantity", GREATEST(("cumulative_purchases" - ("cumulative_orders" - "quantity")), 0))
        ELSE NULL END AS "picked_quantity",
        CASE WHEN "event_type" = 'order' THEN
            (LEAST("quantity", GREATEST(("cumulative_purchases" - ("cumulative_orders" - "quantity")), 0)) / "quantity") * 100
        ELSE NULL END AS "pick_percentage"
    FROM cumulative_sums
)
SELECT
    p."name" AS "Product_Name",
    ROUND(AVG(c."pick_percentage"), 4) AS "Average_Pick_Percentage"
FROM
    calculated c
JOIN ORACLE_SQL.ORACLE_SQL.PRODUCTS p ON c."product_id" = p."id"
WHERE
    c."event_type" = 'order'
GROUP BY
    p."name"
ORDER BY
    p."name";