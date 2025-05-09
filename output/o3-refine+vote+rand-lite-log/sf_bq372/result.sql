WITH
/* 1. Orders that never turned into invoices = “lost” orders */
lost_orders AS (
    SELECT
        o."OrderID",
        o."CustomerID"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS" AS o
    LEFT JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES" AS i
           ON i."OrderID" = o."OrderID"
    WHERE i."OrderID" IS NULL
),

/* 2. Monetary value of every lost order (sum of its order‑lines) */
order_values AS (
    SELECT
        lo."OrderID",
        lo."CustomerID",
        SUM(ol."Quantity" * ol."UnitPrice")            AS order_value
    FROM lost_orders                                                 lo
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" AS ol
          ON ol."OrderID" = lo."OrderID"
    GROUP BY lo."OrderID", lo."CustomerID"
),

/* 3. Maximum lost‑order value for every customer category */
category_max AS (
    SELECT
        c."CustomerCategoryID"                                  AS category_id,
        cat."CustomerCategoryName"                              AS category_name,
        MAX(ov.order_value)                                     AS max_lost_order_value
    FROM order_values                                            ov
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS"          c
         ON c."CustomerID" = ov."CustomerID"
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES"  cat
         ON cat."CustomerCategoryID" = c."CustomerCategoryID"
    GROUP BY c."CustomerCategoryID", cat."CustomerCategoryName"
),

/* 4. Overall average of those maxima */
avg_val AS (
    SELECT AVG(max_lost_order_value) AS avg_max_value
    FROM category_max
),

/* 5. Distance of each category’s maximum from the overall average */
ranked AS (
    SELECT
        cm.*,
        ABS(cm.max_lost_order_value - av.avg_max_value) AS diff_from_avg
    FROM category_max cm
    CROSS JOIN avg_val av
)

/* 6. Category whose maximum is closest to the average */
SELECT
    category_id            AS "CustomerCategoryID",
    category_name          AS "CustomerCategoryName",
    max_lost_order_value   AS "MaxLostOrderValue"
FROM ranked
ORDER BY diff_from_avg ASC, category_id  -- tie‑breaker on ID
LIMIT 1;