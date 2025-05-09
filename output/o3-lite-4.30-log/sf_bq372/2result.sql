WITH lost_orders AS (        -- orders that were never invoiced
    SELECT o."OrderID",
           o."CustomerID"
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS" o
    WHERE  NOT EXISTS (SELECT 1
                       FROM "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES" i
                       WHERE i."OrderID" = o."OrderID")
),
order_totals AS (            -- value of each lost order
    SELECT ol."OrderID",
           SUM(ol."Quantity" * ol."UnitPrice") AS "OrderValue"
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" ol
           JOIN lost_orders lo ON lo."OrderID" = ol."OrderID"
    GROUP  BY ol."OrderID"
),
category_max AS (            -- max lost‑order value per customer category
    SELECT cat."CustomerCategoryName"            AS "CustomerCategory",
           MAX(ot."OrderValue")                  AS "MaxLostOrderValue"
    FROM   order_totals ot
           JOIN lost_orders                                     lo   ON lo."OrderID"  = ot."OrderID"
           JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS"          c    ON c."CustomerID" = lo."CustomerID"
           JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES" cat  ON cat."CustomerCategoryID" = c."CustomerCategoryID"
    GROUP  BY cat."CustomerCategoryName"
),
avg_of_max AS (              -- overall average of those maxima
    SELECT AVG("MaxLostOrderValue") AS "AvgMax"
    FROM   category_max
)
SELECT
       cm."CustomerCategory"                    AS customer_category,
       TO_DECIMAL(cm."MaxLostOrderValue",38,4)  AS maximum_lost_order_value
FROM   category_max cm
       CROSS JOIN avg_of_max a
ORDER  BY ABS(cm."MaxLostOrderValue" - a."AvgMax") ASC,
          cm."CustomerCategory"
LIMIT 1;