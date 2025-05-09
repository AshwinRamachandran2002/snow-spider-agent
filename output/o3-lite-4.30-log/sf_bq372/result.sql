WITH lost_orders AS (
    SELECT o."OrderID"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS" o
    LEFT JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES" i
           ON o."OrderID" = i."OrderID"
    WHERE i."OrderID" IS NULL
),
order_values AS (
    SELECT ol."OrderID",
           SUM(ol."Quantity" * ol."UnitPrice") AS "LostOrderValue"
    FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" ol
    JOIN lost_orders lo
         ON lo."OrderID" = ol."OrderID"
    GROUP BY ol."OrderID"
),
category_max AS (
    SELECT c."CustomerCategoryID",
           MAX(ov."LostOrderValue") AS "MaxLostOrderValue"
    FROM order_values ov
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"    o
           ON o."OrderID" = ov."OrderID"
    JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS" c
           ON c."CustomerID" = o."CustomerID"
    GROUP BY c."CustomerCategoryID"
),
avg_val AS (
    SELECT AVG("MaxLostOrderValue") AS "AvgMaxLost"
    FROM category_max
)
SELECT
    cc."CustomerCategoryName"                            AS customer_category,
    CAST(cm."MaxLostOrderValue" AS NUMBER(38,4))         AS maximum_lost_order_value
FROM category_max cm
CROSS JOIN avg_val a
JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES" cc
     ON cc."CustomerCategoryID" = cm."CustomerCategoryID"
ORDER BY ABS(cm."MaxLostOrderValue" - a."AvgMaxLost") ASC
LIMIT 1;