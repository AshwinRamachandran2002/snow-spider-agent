WITH non_invoiced_orders AS (          -- orders that never became invoices
    SELECT so."OrderID",
           so."CustomerID"
    FROM   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERS"  so
    LEFT  JOIN WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_INVOICES" si
           ON so."OrderID" = si."OrderID"
    WHERE  si."OrderID" IS NULL
),
order_values AS (                      -- total value of every non‑invoiced order
    SELECT ol."OrderID",
           SUM(ol."Quantity" * ol."UnitPrice") AS "OrderTotalValue"
    FROM   non_invoiced_orders nio
    JOIN   WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_ORDERLINES" ol
           ON nio."OrderID" = ol."OrderID"
    GROUP  BY ol."OrderID"
),
category_max AS (                      -- per‑category maximum “lost” order value
    SELECT  c."CustomerCategoryID",
            cc."CustomerCategoryName",
            MAX(ov."OrderTotalValue") AS "MaxLostOrderValue"
    FROM    order_values                     ov
    JOIN    non_invoiced_orders              nio ON ov."OrderID"   = nio."OrderID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERS"          c  ON nio."CustomerID"         = c."CustomerID"
    JOIN    WIDE_WORLD_IMPORTERS.WIDE_WORLD_IMPORTERS."SALES_CUSTOMERCATEGORIES" cc ON c."CustomerCategoryID"   = cc."CustomerCategoryID"
    GROUP BY c."CustomerCategoryID", cc."CustomerCategoryName"
),
avg_val AS (                           -- overall average of those maxima
    SELECT AVG("MaxLostOrderValue") AS "AvgMax"
    FROM   category_max
)
SELECT cm."CustomerCategoryID",
       cm."CustomerCategoryName",
       cm."MaxLostOrderValue"
FROM   category_max  cm
CROSS  JOIN avg_val  av
ORDER  BY ABS(cm."MaxLostOrderValue" - av."AvgMax")   -- closest to the average
LIMIT  1;   -- return the single closest category