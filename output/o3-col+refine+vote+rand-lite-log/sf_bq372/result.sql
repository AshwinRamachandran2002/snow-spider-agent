WITH lost_orders AS (  -- all orders that don't have a matching invoice
    SELECT o."OrderID"
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"   o
    LEFT  JOIN "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_INVOICES" i
           ON o."OrderID" = i."OrderID"
    WHERE  i."OrderID" IS NULL
),
order_values AS (      -- total (UnitPrice * Quantity) per lost order
    SELECT ol."OrderID",
           SUM(ol."UnitPrice" * ol."Quantity") AS "LostOrderValue"
    FROM   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERLINES" ol
    WHERE  ol."OrderID" IN (SELECT "OrderID" FROM lost_orders)
    GROUP BY ol."OrderID"
),
category_max AS (      -- maximum lost-order value per customer category
    SELECT cc."CustomerCategoryID",
           cc."CustomerCategoryName",
           MAX(ov."LostOrderValue") AS "MaxLostOrderValue"
    FROM   order_values                                              ov
    JOIN   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_ORDERS"            o  ON ov."OrderID" = o."OrderID"
    JOIN   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERS"         c  ON o."CustomerID" = c."CustomerID"
    JOIN   "WIDE_WORLD_IMPORTERS"."WIDE_WORLD_IMPORTERS"."SALES_CUSTOMERCATEGORIES" cc ON c."CustomerCategoryID" = cc."CustomerCategoryID"
    GROUP BY cc."CustomerCategoryID",
             cc."CustomerCategoryName"
),
overall_avg AS (       -- overall average of those category maxima
    SELECT AVG("MaxLostOrderValue") AS "OverallAvg"
    FROM   category_max
)
SELECT
    cm."CustomerCategoryID",
    cm."CustomerCategoryName",
    cm."MaxLostOrderValue",
    ABS(cm."MaxLostOrderValue" - oa."OverallAvg") AS "DistanceFromAvg"
FROM   category_max cm
CROSS  JOIN overall_avg oa
ORDER  BY "DistanceFromAvg" ASC
LIMIT  1;