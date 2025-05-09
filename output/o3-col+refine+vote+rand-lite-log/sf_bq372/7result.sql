/*  Customer-category whose maximum “lost-order” value is closest to the
    overall average of such maxima across all categories                 */

WITH lost_orders AS (   -- orders that never became invoices
    SELECT o."OrderID",
           o."CustomerID"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"   o
    WHERE  NOT EXISTS ( SELECT 1
                        FROM WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
                        WHERE i."OrderID" = o."OrderID")
),
order_values AS (       -- value of every lost order
    SELECT lo."OrderID",
           SUM(ol."Quantity" * ol."UnitPrice") AS "OrderValue"
    FROM   lost_orders                                                    lo
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES"   ol
           ON  ol."OrderID" = lo."OrderID"
    GROUP  BY lo."OrderID"
),
category_max AS (       -- maximum lost-order value per customer category
    SELECT  c."CustomerCategoryID",
            MAX(ov."OrderValue") AS "MaxLostOrderValue"
    FROM    order_values                                                  ov
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"      o
            ON  o."OrderID" = ov."OrderID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"   c
            ON  c."CustomerID" = o."CustomerID"
    GROUP   BY c."CustomerCategoryID"
),
avg_max AS (            -- overall average of those maxima
    SELECT AVG("MaxLostOrderValue") AS "AvgMax"
    FROM   category_max
)
SELECT  cm."CustomerCategoryID",
        cm."MaxLostOrderValue",
        am."AvgMax",
        ABS(cm."MaxLostOrderValue" - am."AvgMax") AS "DistanceFromAvg"
FROM    category_max  cm
CROSS   JOIN avg_max  am
ORDER BY "DistanceFromAvg" ASC
LIMIT 1;