WITH lost_orders AS (   -- orders that never became invoices
    SELECT o."OrderID"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"   o
    LEFT  JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" i
           ON o."OrderID" = i."OrderID"
    WHERE  i."OrderID" IS NULL
),
order_values AS (       -- value of every lost order
    SELECT ol."OrderID",
           SUM(ol."Quantity" * ol."UnitPrice") AS "OrderValue"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
    JOIN   lost_orders lo ON lo."OrderID" = ol."OrderID"
    GROUP  BY ol."OrderID"
),
category_max AS (       -- maximum lost-order value per customer category
    SELECT cst."CustomerCategoryID",
           MAX(ov."OrderValue")          AS "MaxLostOrderValue"
    FROM   order_values                                                   ov
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"       o   ON ov."OrderID" = o."OrderID"
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"    cst ON o."CustomerID" = cst."CustomerID"
    GROUP  BY cst."CustomerCategoryID"
),
avg_val AS (            -- overall average of those maxima
    SELECT AVG("MaxLostOrderValue") AS "AvgMaxLostOrderValue"
    FROM   category_max
)
SELECT cm."CustomerCategoryID",
       scc."CustomerCategoryName",
       cm."MaxLostOrderValue",
       ABS(cm."MaxLostOrderValue" - av."AvgMaxLostOrderValue") AS "DiffFromAvg"
FROM   category_max                                      cm
CROSS  JOIN avg_val                                      av
JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" scc
       ON cm."CustomerCategoryID" = scc."CustomerCategoryID"
ORDER  BY "DiffFromAvg" ASC NULLS LAST
LIMIT 1;